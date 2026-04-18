// MARK: - GameState

/// A complete, immutable snapshot of one Tycoon game. Every move produces a
/// brand-new `GameState` — nothing mutates in place. Log states freely for
/// undo, replay, and debugging.
public struct GameState: Sendable, Equatable {
    /// Players in seat order (index 0 = first seat).
    public let players: [Player]
    /// The shuffled deck used this round, kept for deterministic re-dealing.
    public let deck: [Card]
    /// All hands played since the last trick reset, oldest first.
    public let currentTrick: [Hand]
    /// Index into `players` for whose turn it is.
    public let currentPlayerIndex: Int
    /// Current phase of the round.
    public let phase: GamePhase
    /// The active rule configuration.
    public let ruleSet: RuleSet
    /// True when a Revolution has flipped rank order for this round.
    public let isRevolutionActive: Bool
    /// 1-indexed round number.
    public let round: Int
    /// Running score totals keyed by player ID.
    public let scoresByPlayer: [PlayerID: Int]

    public init(
        players: [Player],
        deck: [Card],
        currentTrick: [Hand],
        currentPlayerIndex: Int,
        phase: GamePhase,
        ruleSet: RuleSet,
        isRevolutionActive: Bool,
        round: Int,
        scoresByPlayer: [PlayerID: Int]
    ) {
        self.players = players
        self.deck = deck
        self.currentTrick = currentTrick
        self.currentPlayerIndex = currentPlayerIndex
        self.phase = phase
        self.ruleSet = ruleSet
        self.isRevolutionActive = isRevolutionActive
        self.round = round
        self.scoresByPlayer = scoresByPlayer
    }
}

// MARK: - Factory

extension GameState {
    /// Creates a freshly dealt game ready for round 1.
    ///
    /// - Parameters:
    ///   - players: Players in seat order (3–5 recommended).
    ///   - ruleSet: Active House Rules, including joker count.
    ///   - seed: Deterministic seed — same inputs always produce the same state.
    public static func newGame(
        players: [Player],
        ruleSet: RuleSet,
        seed: UInt64
    ) -> GameState {
        precondition(!players.isEmpty, "A game requires at least one player")

        var deck = Deck.deck(withJokers: ruleSet.jokerCount)
        var rng = Xoshiro256StarStar(seed: seed)
        rng.shuffle(&deck)

        let count = deck.count
        let base = count / players.count
        let extras = count % players.count

        var dealt = players
        var cursor = 0
        for seatIndex in dealt.indices {
            let handSize = base + (seatIndex < extras ? 1 : 0)
            dealt[seatIndex] = dealt[seatIndex].adding(Array(deck[cursor ..< cursor + handSize]))
            cursor += handSize
        }

        // Round 1 lead goes to whoever holds the 3 of Diamonds.
        let threeDiamonds = Card.regular(.three, .diamonds)
        let startIndex = dealt.firstIndex { $0.hand.contains(threeDiamonds) } ?? 0

        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })

        return GameState(
            players: dealt,
            deck: deck,
            currentTrick: [],
            currentPlayerIndex: startIndex,
            phase: .playing,
            ruleSet: ruleSet,
            isRevolutionActive: false,
            round: 1,
            scoresByPlayer: scores
        )
    }
}
