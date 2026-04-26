import Testing
@testable import TycoonDaifugouKit

// MARK: - Helpers

private func makePlayer(_ name: String, cards: [Card]) -> Player {
    Player(displayName: name, hand: cards)
}

private func makeState(
    players: [Player],
    currentPlayerIndex: Int = 0,
    currentTrick: [Hand] = [],
    ruleSet: RuleSet = .baseOnly,
    isRevolutionActive: Bool = false,
    lastPlayedByIndex: Int? = nil
) -> GameState {
    let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    return GameState(
        players: players,
        deck: [],
        currentTrick: currentTrick,
        currentPlayerIndex: currentPlayerIndex,
        phase: .playing,
        ruleSet: ruleSet,
        isRevolutionActive: isRevolutionActive,
        round: 1,
        scoresByPlayer: scores,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

private let jokerRules = RuleSet(
    revolution: false, eightStop: false, jokers: true,
    threeSpadeReversal: true, bankruptcy: false, jokerCount: 1
)

// MARK: - cardsCleared

@Suite("MoveFeatures.cardsCleared")
struct CardsClearedFeatureTests {

    @Test("Single play yields 0.25")
    func singlePlay() {
        let player = makePlayer("P", cards: [.regular(.five, .clubs)])
        let state = makeState(players: [player])
        let move = Move.play(cards: [.regular(.five, .clubs)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.cardsCleared == 0.25)
    }

    @Test("Quad play yields 1.0")
    func quadPlay() {
        let cards: [Card] = [
            .regular(.five, .clubs), .regular(.five, .diamonds),
            .regular(.five, .hearts), .regular(.five, .spades),
        ]
        let player = makePlayer("P", cards: cards)
        let state = makeState(players: [player])
        let move = Move.play(cards: cards, by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.cardsCleared == 1.0)
    }

    @Test("Pass yields 0")
    func passYieldsZero() {
        let player = makePlayer("P", cards: [.regular(.five, .clubs)])
        let state = makeState(players: [player])
        let move = Move.pass(by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.cardsCleared == 0)
    }
}

// MARK: - winLikelihood

@Suite("MoveFeatures.winLikelihood")
struct WinLikelihoodFeatureTests {

    @Test("Lead (no trick) is always 0")
    func leadIsZero() throws {
        let player = makePlayer("P", cards: [.regular(.two, .spades)])
        let state = makeState(players: [player])
        let move = Move.play(cards: [.regular(.two, .spades)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.winLikelihood == 0)
    }

    @Test("Pass is always 0")
    func passIsZero() throws {
        let trick = try Hand(cards: [.regular(.five, .clubs)])
        let player = makePlayer("P", cards: [.regular(.king, .hearts)])
        let state = makeState(
            players: [player],
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        let features = MoveFeatures.extract(for: .pass(by: player.id), in: state, hand: player.hand)

        #expect(features.winLikelihood == 0)
    }

    @Test("Solo Joker beating a single is 1.0")
    func soloJokerWins() throws {
        let trick = try Hand(cards: [.regular(.queen, .clubs)])
        let player = makePlayer("P", cards: [.joker(index: 0)])
        let state = makeState(
            players: [player],
            currentTrick: [trick],
            ruleSet: jokerRules,
            lastPlayedByIndex: 0
        )
        let move = Move.play(cards: [.joker(index: 0)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.winLikelihood == 1.0)
    }

    @Test("3-Spade reversal onto a solo Joker is 1.0")
    func threeSpadeReversal() throws {
        let trick = try Hand(cards: [.joker(index: 0)])
        let player = makePlayer("P", cards: [.regular(.three, .spades)])
        let state = makeState(
            players: [player],
            currentTrick: [trick],
            ruleSet: jokerRules,
            lastPlayedByIndex: 0
        )
        let move = Move.play(cards: [.regular(.three, .spades)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.winLikelihood == 1.0)
    }

    @Test("Stronger rank gives higher likelihood than weaker rank")
    func strongerBeatsWeaker() throws {
        let trick = try Hand(cards: [.regular(.four, .clubs)])
        let player = makePlayer("P", cards: [.regular(.king, .hearts), .regular(.two, .spades)])
        let state = makeState(
            players: [player],
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        let weakBeater = MoveFeatures.extract(
            for: .play(cards: [.regular(.king, .hearts)], by: player.id),
            in: state, hand: player.hand
        )
        let strongBeater = MoveFeatures.extract(
            for: .play(cards: [.regular(.two, .spades)], by: player.id),
            in: state, hand: player.hand
        )

        #expect(strongBeater.winLikelihood > weakBeater.winLikelihood)
        #expect(weakBeater.winLikelihood > 0)
    }
}

// MARK: - comboIntegrity

@Suite("MoveFeatures.comboIntegrity")
struct ComboIntegrityFeatureTests {

    @Test("Pass preserves combos (1.0)")
    func passPreserves() {
        let player = makePlayer("P", cards: [
            .regular(.five, .clubs), .regular(.five, .diamonds),
        ])
        let state = makeState(players: [player])

        let features = MoveFeatures.extract(for: .pass(by: player.id), in: state, hand: player.hand)

        #expect(features.comboIntegrity == 1.0)
    }

    @Test("Playing a single from no held group is 1.0")
    func soloSingleNoGroup() {
        let player = makePlayer("P", cards: [
            .regular(.five, .clubs), .regular(.king, .hearts),
        ])
        let state = makeState(players: [player])
        let move = Move.play(cards: [.regular(.five, .clubs)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.comboIntegrity == 1.0)
    }

    @Test("Splitting a held pair drops integrity to 0.5")
    func splitPair() {
        let player = makePlayer("P", cards: [
            .regular(.five, .clubs), .regular(.five, .diamonds),
        ])
        let state = makeState(players: [player])
        let move = Move.play(cards: [.regular(.five, .clubs)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.comboIntegrity == 0.5)
    }

    @Test("Playing the whole pair is 1.0")
    func fullPair() {
        let cards: [Card] = [.regular(.five, .clubs), .regular(.five, .diamonds)]
        let player = makePlayer("P", cards: cards)
        let state = makeState(players: [player])
        let move = Move.play(cards: cards, by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.comboIntegrity == 1.0)
    }

    @Test("Splitting a triple by playing 1 leaves 2/3 integrity")
    func splitTripleByOne() {
        let player = makePlayer("P", cards: [
            .regular(.six, .clubs), .regular(.six, .diamonds), .regular(.six, .hearts),
        ])
        let state = makeState(players: [player])
        let move = Move.play(cards: [.regular(.six, .clubs)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(abs(features.comboIntegrity - 2.0 / 3.0) < 1e-9)
    }

    @Test("Splitting a triple by playing 2 leaves 1/3 integrity")
    func splitTripleByTwo() {
        let cards: [Card] = [
            .regular(.six, .clubs), .regular(.six, .diamonds), .regular(.six, .hearts),
        ]
        let player = makePlayer("P", cards: cards)
        let state = makeState(players: [player])
        let move = Move.play(
            cards: [.regular(.six, .clubs), .regular(.six, .diamonds)], by: player.id
        )

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(abs(features.comboIntegrity - 1.0 / 3.0) < 1e-9)
    }
}

// MARK: - cardValueSpent

@Suite("MoveFeatures.cardValueSpent")
struct CardValueSpentFeatureTests {

    @Test("3 of clubs scores ~0 (weakest rank)")
    func threeIsWeakest() {
        let player = makePlayer("P", cards: [.regular(.three, .clubs)])
        let state = makeState(players: [player])
        let move = Move.play(cards: [.regular(.three, .clubs)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.cardValueSpent == 0.0)
    }

    @Test("2 of spades scores 1.0 (strongest non-Joker)")
    func twoIsStrongest() {
        let player = makePlayer("P", cards: [.regular(.two, .spades)])
        let state = makeState(players: [player])
        let move = Move.play(cards: [.regular(.two, .spades)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.cardValueSpent == 1.0)
    }

    @Test("Joker scores 1.0")
    func jokerIsStrongest() {
        let player = makePlayer("P", cards: [.joker(index: 0)])
        let state = makeState(players: [player], ruleSet: jokerRules)
        let move = Move.play(cards: [.joker(index: 0)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.cardValueSpent == 1.0)
    }

    @Test("Revolution flips strength so 3 becomes the strongest")
    func revolutionFlipsStrength() {
        let player = makePlayer("P", cards: [.regular(.three, .clubs)])
        let state = makeState(players: [player], isRevolutionActive: true)
        let move = Move.play(cards: [.regular(.three, .clubs)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(features.cardValueSpent == 1.0)
    }

    @Test("Mean of [3, K] is between 0 and 1, closer to King's strength")
    func meanOfMixedRanks() {
        let cards: [Card] = [.regular(.three, .clubs), .regular(.king, .hearts)]
        let player = makePlayer("P", cards: cards)
        let state = makeState(players: [player])
        // Note: this isn't a legal play (mixed ranks) but the feature func is
        // pure on the cards array, so we exercise it directly.
        let move = Move.play(cards: cards, by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        // 3 → 0.0, King → (13-3)/12 ≈ 0.833. Mean ≈ 0.417.
        #expect(features.cardValueSpent > 0.4 && features.cardValueSpent < 0.45)
    }

    @Test("Pass scores 0")
    func passZero() {
        let player = makePlayer("P", cards: [.regular(.king, .hearts)])
        let state = makeState(players: [player])

        let features = MoveFeatures.extract(for: .pass(by: player.id), in: state, hand: player.hand)

        #expect(features.cardValueSpent == 0)
    }
}

// MARK: - isPass flag

@Suite("MoveFeatures.isPass")
struct IsPassFlagTests {

    @Test("Pass move has isPass=true")
    func passTrue() {
        let player = makePlayer("P", cards: [.regular(.three, .clubs)])
        let state = makeState(players: [player])

        let features = MoveFeatures.extract(for: .pass(by: player.id), in: state, hand: player.hand)

        #expect(features.isPass)
    }

    @Test("Play move has isPass=false")
    func playFalse() {
        let player = makePlayer("P", cards: [.regular(.three, .clubs)])
        let state = makeState(players: [player])
        let move = Move.play(cards: [.regular(.three, .clubs)], by: player.id)

        let features = MoveFeatures.extract(for: move, in: state, hand: player.hand)

        #expect(!features.isPass)
    }
}
