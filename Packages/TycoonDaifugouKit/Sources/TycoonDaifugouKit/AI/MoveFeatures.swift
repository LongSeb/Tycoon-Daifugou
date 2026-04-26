import Foundation

// MARK: - MoveFeatures

/// Numeric description of a single candidate `Move` from a player's perspective.
/// Each component is normalized to `[0, 1]` so that `FeatureWeights` are
/// interpretable as importance ratios.
public struct MoveFeatures: Sendable, Equatable {

    /// Cards shed by the move, normalized against the largest possible base-rule
    /// move (a quad = 4). Pass = 0.
    public let cardsCleared: Double

    /// Heuristic probability that the move takes the lead. ~0 on a fresh lead
    /// (no trick to win) and on pass; ~1 for unconditional trump plays.
    public let winLikelihood: Double

    /// Same-rank-group preservation. 1 = no held combo is split (untouched or
    /// played whole); lower = a held combo was partially played, leaving
    /// stranded cards that no longer form their original group.
    public let comboIntegrity: Double

    /// Mean rank-strength of the cards being spent, revolution-aware.
    /// Joker = 1.0, 3 = 0.0. Pass = 0.
    public let cardValueSpent: Double

    /// True iff the underlying move is `.pass`. Used by `Policy.score` to apply
    /// `passBias` rather than treating pass as another scored play.
    public let isPass: Bool

    public init(
        cardsCleared: Double,
        winLikelihood: Double,
        comboIntegrity: Double,
        cardValueSpent: Double,
        isPass: Bool
    ) {
        self.cardsCleared = cardsCleared
        self.winLikelihood = winLikelihood
        self.comboIntegrity = comboIntegrity
        self.cardValueSpent = cardValueSpent
        self.isPass = isPass
    }
}

// MARK: - Extraction

extension MoveFeatures {

    /// Computes the feature vector for `move` from `playerID`'s perspective.
    /// `hand` is the player's current hand (passed in to avoid re-deriving it).
    public static func extract(
        for move: Move,
        in state: GameState,
        hand: [Card]
    ) -> MoveFeatures {
        switch move {
        case .pass:
            return MoveFeatures(
                cardsCleared: 0.0,
                winLikelihood: 0.0,
                comboIntegrity: 1.0,
                cardValueSpent: 0.0,
                isPass: true
            )

        case .play(let cards, _):
            return MoveFeatures(
                cardsCleared: cardsClearedFeature(cards: cards),
                winLikelihood: winLikelihoodFeature(cards: cards, state: state),
                comboIntegrity: comboIntegrityFeature(cards: cards, hand: hand),
                cardValueSpent: cardValueSpentFeature(
                    cards: cards,
                    revolutionActive: state.isRevolutionActive
                ),
                isPass: false
            )

        case .trade:
            // Trading-phase moves are out of scope for combat scoring.
            return MoveFeatures(
                cardsCleared: 0.0,
                winLikelihood: 0.0,
                comboIntegrity: 1.0,
                cardValueSpent: 0.0,
                isPass: false
            )
        }
    }
}

// MARK: - Per-feature helpers

/// `Rank.three.rawValue == 3` and `Rank.two.rawValue == 15` give 13 distinct
/// strengths. Normalized to `[0, 1]` against the span of 12.
private let rankSpan: Double = 12.0

private func rankStrength(_ rank: Rank, revolutionActive: Bool) -> Double {
    let raw = Double(rank.rawValue - Rank.three.rawValue) / rankSpan
    return revolutionActive ? (1.0 - raw) : raw
}

private func cardStrength(_ card: Card, revolutionActive: Bool) -> Double {
    if card.isJoker { return 1.0 }
    guard let rank = card.rank else { return 1.0 }
    return rankStrength(rank, revolutionActive: revolutionActive)
}

/// Cards shed normalized against a quad (the largest base-rule move).
private func cardsClearedFeature(cards: [Card]) -> Double {
    guard !cards.isEmpty else { return 0.0 }
    return min(Double(cards.count) / 4.0, 1.0)
}

/// Heuristic [0, 1] estimate that the move takes the lead.
/// On a fresh lead returns 0 (no trick to seize). On contested tricks scales
/// with rank strength, with hard-coded 1.0 for unconditional trump cases.
private func winLikelihoodFeature(cards: [Card], state: GameState) -> Double {
    guard !state.currentTrick.isEmpty else { return 0.0 }
    guard let played = try? Hand(cards: cards) else { return 0.0 }

    if played.isDoubleJoker { return 1.0 }
    if played.isSoloJoker   { return 1.0 }

    // 3-Spade reversal onto a solo Joker clears the trick — treat as a sure win.
    if cards == [.regular(.three, .spades)],
       state.currentTrick.last?.isSoloJoker == true {
        return 1.0
    }

    return rankStrength(played.rank, revolutionActive: state.isRevolutionActive)
}

/// Mean rank-strength of cards being spent. Used with a negative weight in
/// almost every personality so the bot avoids burning its strongest cards.
private func cardValueSpentFeature(cards: [Card], revolutionActive: Bool) -> Double {
    guard !cards.isEmpty else { return 0.0 }
    let sum = cards.reduce(0.0) { $0 + cardStrength($1, revolutionActive: revolutionActive) }
    return sum / Double(cards.count)
}

/// Combo integrity in `[0, 1]`. For each held same-rank group of size G ≥ 2,
/// playing all or none of it counts as 1.0 (preserved or cleanly removed),
/// while a partial split contributes `(G − played) / G` — the fraction of
/// the group that survives as stranded cards. The total is the mean across
/// held groups. With no held groups, returns 1.0.
private func comboIntegrityFeature(cards: [Card], hand: [Card]) -> Double {
    let heldGroups = Dictionary(grouping: hand.filter { !$0.isJoker }) { $0.rank! }
        .filter { $0.value.count >= 2 }
    guard !heldGroups.isEmpty else { return 1.0 }

    let playedByRank = Dictionary(grouping: cards.filter { !$0.isJoker }) { $0.rank! }
        .mapValues(\.count)

    var contributions: [Double] = []
    contributions.reserveCapacity(heldGroups.count)

    for (rank, groupCards) in heldGroups {
        let groupSize = groupCards.count
        let played = playedByRank[rank, default: 0]
        if played == 0 || played == groupSize {
            contributions.append(1.0)
        } else {
            contributions.append(Double(groupSize - played) / Double(groupSize))
        }
    }

    return contributions.reduce(0.0, +) / Double(contributions.count)
}
