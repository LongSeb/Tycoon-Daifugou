import Testing
@testable import TycoonDaifugouKit

// MARK: - Helpers

private func makeJokerState(
    players: [Player],
    currentPlayerIndex: Int = 0,
    currentTrick: [Hand] = [],
    lastPlayedByIndex: Int? = nil,
    jokers: Bool = true,
    jokerCount: Int = 1,
    revolution: Bool = false,
    revolutionActive: Bool = false
) -> GameState {
    let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    return GameState(
        players: players,
        deck: [],
        currentTrick: currentTrick,
        currentPlayerIndex: currentPlayerIndex,
        phase: .playing,
        ruleSet: RuleSet(revolution: revolution, jokers: jokers, jokerCount: jokerCount),
        isRevolutionActive: revolutionActive,
        round: 1,
        scoresByPlayer: scores,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

// MARK: - Joker reducer rule tests

@Suite("Joker house rule")
struct JokerTests {

    // MARK: Solo Joker strength

    @Test("Single Joker beats a lone 2")
    func singleJokerBeatsLoneTwo() throws {
        let twoTrick = try Hand(cards: [.regular(.two, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.ace, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.joker(index: 0), .regular(.three, .diamonds)])
        let state = makeJokerState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [twoTrick],
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: [.joker(index: 0)], by: p1.id))
        #expect(next.currentTrick.last?.cards == [.joker(index: 0)])
    }

    @Test("Single Joker beats a lone 3 under Revolution")
    func singleJokerBeatsLoneThreeUnderRevolution() throws {
        let threeTrick = try Hand(cards: [.regular(.three, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.ace, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.joker(index: 0), .regular(.five, .diamonds)])
        let state = makeJokerState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [threeTrick],
            lastPlayedByIndex: 0,
            revolution: true,
            revolutionActive: true
        )

        let next = try state.apply(.play(cards: [.joker(index: 0)], by: p1.id))
        #expect(next.currentTrick.last?.cards == [.joker(index: 0)])
    }

    // MARK: Joker as wildcard (Hand constructor already handles these)

    @Test("Joker as wildcard in a pair")
    func jokerWildcardPair() throws {
        let hand = try Hand(cards: [.regular(.king, .clubs), .joker(index: 0)])
        #expect(hand.type == .pair)
        #expect(hand.rank == .king)
        #expect(!hand.isSoloJoker)
    }

    @Test("Joker as wildcard in a triple")
    func jokerWildcardTriple() throws {
        let hand = try Hand(cards: [
            .regular(.queen, .clubs), .regular(.queen, .diamonds), .joker(index: 0),
        ])
        #expect(hand.type == .triple)
        #expect(hand.rank == .queen)
    }

    @Test("Joker as wildcard in a quad")
    func jokerWildcardQuad() throws {
        let hand = try Hand(cards: [
            .regular(.jack, .clubs), .regular(.jack, .diamonds),
            .regular(.jack, .hearts), .joker(index: 0),
        ])
        #expect(hand.type == .quad)
        #expect(hand.rank == .jack)
    }

    // MARK: Rule disabled — regular game

    @Test("ruleSet.jokers false + jokerCount 0 passes RuleSet validation (regular game)")
    func ruleDisabledValidation() throws {
        let baseGame = RuleSet(jokers: false, jokerCount: 0)
        try baseGame.validate()  // Must not throw
    }

    @Test("Playing a solo Joker is rejected when jokers rule is disabled")
    func ruleDisabledRejectsSoloJoker() throws {
        let sevenTrick = try Hand(cards: [.regular(.seven, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.ace, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.joker(index: 0), .regular(.five, .hearts)])
        let scores = Dictionary(uniqueKeysWithValues: [p0, p1].map { ($0.id, 0) })
        let state = GameState(
            players: [p0, p1],
            deck: [],
            currentTrick: [sevenTrick],
            currentPlayerIndex: 1,
            phase: .playing,
            ruleSet: RuleSet(jokers: false, jokerCount: 0),
            round: 1,
            scoresByPlayer: scores,
            lastPlayedByIndex: 0
        )

        #expect(throws: GameError.invalidHand(.allJokers)) {
            try state.apply(.play(cards: [.joker(index: 0)], by: p1.id))
        }
    }

    // MARK: RuleSet validation

    @Test("RuleSet with jokers enabled but jokerCount 0 fails validation")
    func ruleSetValidationFailsWhenJokersEnabledWithZeroCount() {
        let invalid = RuleSet(jokers: true, jokerCount: 0)
        #expect(throws: RuleSetError.jokersEnabledButCountIsZero) {
            try invalid.validate()
        }
    }

    @Test("RuleSet with jokers enabled and jokerCount 1 passes validation")
    func ruleSetValidationPassesWithJokerCount1() throws {
        let valid = RuleSet(jokers: true, jokerCount: 1)
        try valid.validate()
    }

    // MARK: validMoves includes solo Joker

    @Test("validMoves includes solo Joker when trick has a single and jokers is enabled")
    func validMovesIncludesSoloJokerAgainstSingle() throws {
        let sevenTrick = try Hand(cards: [.regular(.seven, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.ace, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.joker(index: 0), .regular(.three, .spades)])
        let state = makeJokerState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenTrick],
            lastPlayedByIndex: 0
        )

        let moves = state.validMoves(for: p1.id)
        #expect(moves.contains(.play(cards: [.joker(index: 0)], by: p1.id)))
    }

    @Test("validMoves includes solo Joker as a lead when trick is empty")
    func validMovesIncludesSoloJokerAsLead() throws {
        let p0 = Player(displayName: "P0", hand: [.regular(.ace, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.joker(index: 0), .regular(.three, .spades)])
        let state = makeJokerState(players: [p0, p1], currentPlayerIndex: 1)

        let moves = state.validMoves(for: p1.id)
        #expect(moves.contains(.play(cards: [.joker(index: 0)], by: p1.id)))
    }

    @Test("validMoves excludes solo Joker when jokers rule is disabled")
    func validMovesExcludesSoloJokerWhenRuleDisabled() throws {
        let sevenTrick = try Hand(cards: [.regular(.seven, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.ace, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.joker(index: 0), .regular(.five, .hearts)])
        let scores = Dictionary(uniqueKeysWithValues: [p0, p1].map { ($0.id, 0) })
        let state = GameState(
            players: [p0, p1],
            deck: [],
            currentTrick: [sevenTrick],
            currentPlayerIndex: 1,
            phase: .playing,
            ruleSet: RuleSet(jokers: false, jokerCount: 0),
            round: 1,
            scoresByPlayer: scores,
            lastPlayedByIndex: 0
        )

        let moves = state.validMoves(for: p1.id)
        #expect(!moves.contains(.play(cards: [.joker(index: 0)], by: p1.id)))
    }
}
