import Foundation

// MARK: - GameState

public struct GameState: Sendable, Equatable {
    /// Players in seat order.
    public let players: [Player]
    /// The shuffled deck used for this game (stored for deterministic re-dealing).
    public let deck: [Card]
    /// Plays made since the last trick reset.
    public let currentTrick: [Hand]
    /// Index into `players` of whose turn it is.
    public let currentPlayerIndex: Int
    public let phase: GamePhase
    public let ruleSet: RuleSet
    public let isRevolutionActive: Bool
    /// 1-indexed round counter.
    public let round: Int
    public let scoresByPlayer: [PlayerID: Int]
    /// Number of consecutive passes since the last `.play` move.
    public let passCountSinceLastPlay: Int
    /// Index into `players` of whoever played the most recent `Hand` in the current trick.
    public let lastPlayedByIndex: Int?
    /// Cards from completed tricks — accumulated when `currentTrick` is cleared.
    /// Keeps total card count constant across the entire round.
    public let playedPile: [Card]

    public init(
        players: [Player],
        deck: [Card],
        currentTrick: [Hand] = [],
        currentPlayerIndex: Int,
        phase: GamePhase,
        ruleSet: RuleSet,
        isRevolutionActive: Bool = false,
        round: Int,
        scoresByPlayer: [PlayerID: Int],
        passCountSinceLastPlay: Int = 0,
        lastPlayedByIndex: Int? = nil,
        playedPile: [Card] = []
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
        self.passCountSinceLastPlay = passCountSinceLastPlay
        self.lastPlayedByIndex = lastPlayedByIndex
        self.playedPile = playedPile
    }

    /// Every card that exists in this state: player hands + current trick + discard pile.
    public var allCards: [Card] {
        players.flatMap { $0.hand }
            + currentTrick.flatMap { $0.cards }
            + playedPile
    }

    /// Creates a fresh round-1 game state. Cards are deterministically shuffled
    /// using `seed` via Xoshiro256**, then dealt evenly (leftover cards go to
    /// the first players in seat order). Phase is `.playing`; the first player
    /// is whoever holds the 3 of Diamonds.
    public static func newGame(players: [Player], ruleSet: RuleSet, seed: UInt64) -> GameState {
        var rng = Xoshiro256StarStar(seed: seed)

        var shuffledDeck = Deck.deck(withJokers: ruleSet.jokerCount)
        rng.shuffle(&shuffledDeck)

        let total = shuffledDeck.count
        let playerCount = players.count
        let base = total / playerCount
        let leftover = total % playerCount

        var dealtPlayers: [Player] = []
        var offset = 0
        for (seatIndex, player) in players.enumerated() {
            let handSize = base + (seatIndex < leftover ? 1 : 0)
            let hand = Array(shuffledDeck[offset..<offset + handSize])
            dealtPlayers.append(player.adding(hand))
            offset += handSize
        }

        let threeDiamonds = Card.regular(.three, .diamonds)
        let startIndex = dealtPlayers.firstIndex { $0.hand.contains(threeDiamonds) } ?? 0

        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })

        return GameState(
            players: dealtPlayers,
            deck: shuffledDeck,
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

// MARK: - Xoshiro256** PRNG

/// Xoshiro256** — fast, high-quality seeded PRNG. State is initialized from a
/// single UInt64 seed via SplitMix64.
private struct Xoshiro256StarStar {
    private struct State {
        var w0: UInt64
        var w1: UInt64
        var w2: UInt64
        var w3: UInt64
    }

    private var state: State

    init(seed: UInt64) {
        var seedValue = seed
        state = State(
            w0: Self.splitmix64(&seedValue),
            w1: Self.splitmix64(&seedValue),
            w2: Self.splitmix64(&seedValue),
            w3: Self.splitmix64(&seedValue)
        )
    }

    mutating func next() -> UInt64 {
        let result = Self.rotl(state.w1 &* 5, shift: 7) &* 9
        let temp = state.w1 << 17
        state.w2 ^= state.w0
        state.w3 ^= state.w1
        state.w1 ^= state.w2
        state.w0 ^= state.w3
        state.w2 ^= temp
        state.w3 = Self.rotl(state.w3, shift: 45)
        return result
    }

    mutating func shuffle<T>(_ array: inout [T]) {
        for idx in stride(from: array.count - 1, through: 1, by: -1) {
            let swapIdx = Int(next() % UInt64(idx + 1))
            array.swapAt(idx, swapIdx)
        }
    }

    private static func rotl(_ value: UInt64, shift: Int) -> UInt64 {
        (value << shift) | (value >> (64 - shift))
    }

    private static func splitmix64(_ seedValue: inout UInt64) -> UInt64 {
        seedValue &+= 0x9e3779b97f4a7c15
        var mixed = seedValue
        mixed = (mixed ^ (mixed >> 30)) &* 0xbf58476d1ce4e5b9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94d049bb133111eb
        return mixed ^ (mixed >> 31)
    }
}
