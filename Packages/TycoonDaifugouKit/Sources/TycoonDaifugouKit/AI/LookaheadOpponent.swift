import Foundation

// MARK: - LookaheadOpponent

/// An opponent that augments its `policy.score(...)` with a 1-ply forward
/// simulation: for each candidate move, it applies the move, walks the engine
/// forward through other seats' turns assuming everyone plays a `.balanced`
/// argmax move, and adds the best score it could achieve on its own next turn.
///
/// Used exclusively by `Difficulty.expert`. Hard and below remain pure softmax.
///
/// `LookaheadOpponent` is deterministic — no softmax, no RNG. Identical
/// `(policy, state, hand)` always yields the same move.
public final class LookaheadOpponent: Opponent, @unchecked Sendable {

    /// Score-gap threshold for considering candidates "close enough" to call
    /// for a lookahead tiebreak. When the highest-direct-scoring move is more
    /// than this many points above all alternatives, we trust the direct
    /// argmax and skip the forward sim (also saves compute). When several
    /// candidates are within this band, the lookahead gets to choose.
    public static let defaultTieBreakEpsilon: Double = 0.15

    /// Hard cap on simulated steps after our move. Generous enough to walk
    /// through a full pass cycle (one ply per other seat). Prevents runaway
    /// loops if the engine ever reaches an unexpected state.
    private static let simulationStepCap = 16

    public let policy: Policy
    public let tieBreakEpsilon: Double

    public init(
        policy: Policy,
        tieBreakEpsilon: Double = LookaheadOpponent.defaultTieBreakEpsilon
    ) {
        self.policy = policy
        self.tieBreakEpsilon = tieBreakEpsilon
    }

    public func move(for playerID: PlayerID, in state: GameState) -> Move {
        // Same description-sort as `PolicyOpponent` so candidate ordering is
        // stable across runs and reproducible for tests.
        let candidates = state.validMoves(for: playerID).sorted { lhs, rhs in
            String(describing: lhs) < String(describing: rhs)
        }
        if candidates.isEmpty { return .pass(by: playerID) }
        if candidates.count == 1 { return candidates[0] }

        // Tactical fast-path: applied uniformly across difficulties.
        if let forced = TacticalRules.forcedMove(
            for: playerID, in: state, candidates: candidates
        ) {
            return forced
        }

        let hand = state.players.first(where: { $0.id == playerID })?.hand ?? []
        let directScores = candidates.map { policy.score($0, in: state, hand: hand) }
        guard let bestDirect = directScores.max() else { return candidates[0] }

        // Pick the indices whose direct score is within ε of the leader.
        // Single-leader positions short-circuit straight to argmax — no
        // forward sim needed, saves compute, and matches Hard's argmax in
        // those positions exactly.
        let topIndices = directScores.indices.filter {
            directScores[$0] >= bestDirect - tieBreakEpsilon
        }
        if topIndices.count == 1 {
            return candidates[topIndices[0]]
        }

        // Multiple close candidates — let the lookahead break the tie.
        var bestLookahead = -Double.infinity
        var bestIdx = topIndices[0]
        for idx in topIndices {
            let value = lookaheadValue(
                after: candidates[idx], from: state, selfID: playerID
            )
            if value > bestLookahead {
                bestLookahead = value
                bestIdx = idx
            }
        }
        return candidates[bestIdx]
    }

    // MARK: - Lookahead

    /// Applies `candidate`, walks the engine through one rotation of other
    /// seats' turns assuming each plays a `.balanced` argmax move, and
    /// scores the **resulting hand quality** with a positional eval:
    ///
    ///     value = trump_count × 1.5 + combo_count × 1.0 − hand_size × 0.5
    ///
    /// — where `trump_count` is the number of cards in our remaining hand
    /// that outrank ≥80% of the unseen deck (i.e. cards we can almost
    /// certainly cash in later), `combo_count` is the number of held
    /// same-rank groups of size ≥ 2, and `hand_size` is the obvious one.
    ///
    /// This evaluator captures the endgame-stash strategy directly: a
    /// rotation that leaves us with our 2s/Aces/Joker intact and a couple
    /// of combos scores higher than one that empties our trump stash, even
    /// when both leave the same number of cards. The policy's direct score
    /// is move-local; this is position-local, so the two are complementary.
    ///
    /// Edge cases:
    /// - If applying `candidate` ends the round, value = +10 (we won) or
    ///   -1 (round closed without us). The round-ending-win case is also
    ///   tactical-rule-forced upstream, so this branch mostly handles the
    ///   defensive loss case.
    private func lookaheadValue(
        after candidate: Move, from state: GameState, selfID: PlayerID
    ) -> Double {
        guard let advanced = try? state.apply(candidate) else { return 0.0 }

        if advanced.phase != .playing {
            guard let me = advanced.players.first(where: { $0.id == selfID })
            else { return 0.0 }
            return me.hand.isEmpty ? 10.0 : -1.0
        }

        let resolved = simulateUntilSelfTurn(advanced, selfID: selfID)
        return handQualityEval(in: resolved, selfID: selfID)
    }

    /// Position-quality score for the active player's hand. Higher = better
    /// position (more trumps preserved, more combos leadable, fewer cards).
    private func handQualityEval(in state: GameState, selfID: PlayerID) -> Double {
        guard let me = state.players.first(where: { $0.id == selfID }) else { return 0.0 }
        let hand = me.hand
        if hand.isEmpty { return 10.0 }

        let unseen = unseenCards(in: state, selfHand: hand)
        let trumpCount = countTrumps(in: hand, unseen: unseen, revolution: state.isRevolutionActive)
        let comboCount = countCombos(in: hand)
        let handSize = hand.count

        return Double(trumpCount) * 1.5
            +  Double(comboCount) * 1.0
            -  Double(handSize) * 0.5
    }

    /// Cards that exist in the deck but are not in our hand, the played
    /// pile, or the current trick — i.e. presumably in opponents' hands.
    private func unseenCards(in state: GameState, selfHand: [Card]) -> Set<Card> {
        let deck = Deck.deck(withJokers: state.ruleSet.jokerCount)
        let visible = Set(selfHand)
            .union(state.playedPile)
            .union(state.currentTrick.flatMap { $0.cards })
        return Set(deck.filter { !visible.contains($0) })
    }

    /// Cards in `hand` that outrank ≥80% of the unseen deck, plus all Jokers.
    /// These are "presumably-cashable" — likely to win when led.
    private func countTrumps(
        in hand: [Card], unseen: Set<Card>, revolution: Bool
    ) -> Int {
        guard !unseen.isEmpty else { return hand.filter { $0.isJoker }.count }
        var trumps = 0
        for card in hand {
            if card.isJoker { trumps += 1; continue }
            let myStrength = trumpStrength(card, revolution: revolution)
            let weakerCount = unseen.filter {
                trumpStrength($0, revolution: revolution) < myStrength
            }.count
            if Double(weakerCount) / Double(unseen.count) >= 0.8 {
                trumps += 1
            }
        }
        return trumps
    }

    private func trumpStrength(_ card: Card, revolution: Bool) -> Double {
        if card.isJoker { return 1.0 }
        guard let rank = card.rank else { return 1.0 }
        let raw = Double(rank.rawValue - Rank.three.rawValue) / 12.0
        return revolution ? (1.0 - raw) : raw
    }

    /// Number of held same-rank groups of size ≥ 2 (potential combo leads).
    private func countCombos(in hand: [Card]) -> Int {
        let groups = Dictionary(grouping: hand.filter { !$0.isJoker }) { $0.rank! }
        return groups.values.filter { $0.count >= 2 }.count
    }

    /// Drives the engine forward through other seats' turns, choosing the
    /// `.balanced` argmax move for each, until either it's our turn again,
    /// the round ends, or the step cap trips.
    private func simulateUntilSelfTurn(_ state: GameState, selfID: PlayerID) -> GameState {
        var current = state
        for _ in 0..<Self.simulationStepCap {
            guard current.phase == .playing else { return current }
            let activePlayer = current.players[current.currentPlayerIndex]
            if activePlayer.id == selfID { return current }

            let moves = current.validMoves(for: activePlayer.id)
            guard !moves.isEmpty else { return current }
            let chosen = argmaxStandInMove(moves: moves, state: current, hand: activePlayer.hand)
            guard let next = try? current.apply(chosen) else { return current }
            current = next
        }
        return current
    }

    /// Stand-in opponent decision: score every legal move with `.balanced`
    /// at τ=0 and pick the argmax. The bot doesn't know other seats' real
    /// policies in pure-engine code, so this single rational baseline keeps
    /// the simulation deterministic and well-behaved.
    private func argmaxStandInMove(
        moves: [Move], state: GameState, hand: [Card]
    ) -> Move {
        let sorted = moves.sorted { lhs, rhs in
            String(describing: lhs) < String(describing: rhs)
        }
        var bestScore = -Double.infinity
        var bestMove = sorted[0]
        for move in sorted {
            let score = Policy.balanced.score(move, in: state, hand: hand)
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        return bestMove
    }
}
