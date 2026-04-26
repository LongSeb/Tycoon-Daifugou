import Testing
@testable import TycoonDaifugouKit

// MARK: - Helpers

private func makeReversalState(
    players: [Player],
    currentPlayerIndex: Int = 0,
    currentTrick: [Hand] = [],
    lastPlayedByIndex: Int? = nil,
    threeSpadeReversal: Bool = true,
    jokers: Bool = true,
    jokerCount: Int = 1,
    isRevolutionActive: Bool = false
) -> GameState {
    let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    return GameState(
        players: players,
        deck: [],
        currentTrick: currentTrick,
        currentPlayerIndex: currentPlayerIndex,
        phase: .playing,
        ruleSet: RuleSet(jokers: jokers, threeSpadeReversal: threeSpadeReversal, jokerCount: jokerCount),
        isRevolutionActive: isRevolutionActive,
        round: 1,
        scoresByPlayer: scores,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

// MARK: - ThreeSpadeReversal tests

@Suite("3-Spade Reversal house rule")
struct ThreeSpadeReversalTests {

    // MARK: Core reversal effect

    @Test("3 of Spades played onto a solo Joker ends the trick and gives lead to the 3-Spade player")
    func threeSpadeOnSoloJokerEndsTriickAndGrantsLead() throws {
        let jokerHand = try Hand(cards: [.joker(index: 0)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [jokerHand],
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: [.regular(.three, .spades)], by: p1.id))
        #expect(next.currentTrick.isEmpty, "Trick must be cleared after 3-Spade Reversal")
        #expect(next.currentPlayerIndex == 1, "3-Spade player must receive the lead")
    }

    @Test("Played pile accumulates the Joker and 3 of Spades after a reversal")
    func playedPileAccumulatesAfterReversal() throws {
        let jokerHand = try Hand(cards: [.joker(index: 0)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [jokerHand],
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: [.regular(.three, .spades)], by: p1.id))
        #expect(next.playedPile.contains(.joker(index: 0)))
        #expect(next.playedPile.contains(.regular(.three, .spades)))
    }

    // MARK: Non-reversal cases

    @Test("3 of Spades on a non-Joker single is rejected (normal play is illegal since 3 is weakest)")
    func threeSpadeOnRegularSingleIsIllegal() throws {
        let kingTrick = try Hand(cards: [.regular(.king, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.ace, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [kingTrick],
            lastPlayedByIndex: 0
        )

        #expect(throws: GameError.notStrongerThanCurrent) {
            try state.apply(.play(cards: [.regular(.three, .spades)], by: p1.id))
        }
    }

    @Test("3 of Spades on a pair containing a Joker is not a reversal (hand type mismatch)")
    func threeSpadeOnJokerPairIsNotReversal() throws {
        // A pair with a Joker: [Joker, 9♥] — valid pair hand
        let jokerPairHand = try Hand(cards: [.joker(index: 0), .regular(.nine, .hearts)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [jokerPairHand],
            lastPlayedByIndex: 0
        )

        // Playing a single 3♠ on a pair is a type mismatch — not a reversal
        #expect(throws: GameError.handTypeMismatch) {
            try state.apply(.play(cards: [.regular(.three, .spades)], by: p1.id))
        }
    }

    // MARK: Rule toggle

    @Test("Reversal is not triggered when threeSpadeReversal rule is disabled")
    func reversalRuleDisabledDoesNotTrigger() throws {
        let jokerHand = try Hand(cards: [.joker(index: 0)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [jokerHand],
            lastPlayedByIndex: 0,
            threeSpadeReversal: false
        )

        // Without the rule, 3♠ cannot beat a Joker
        #expect(throws: GameError.notStrongerThanCurrent) {
            try state.apply(.play(cards: [.regular(.three, .spades)], by: p1.id))
        }
    }

    @Test("Reversal is not triggered when jokers rule is disabled (threeSpadeReversal requires jokers)")
    func reversalRequiresJokersEnabled() throws {
        // A solo Joker hand cannot even be constructed without jokers, so test via ThreeSpadeReversal.triggers directly
        let soloJokerHand = try Hand(cards: [.joker(index: 0)])
        let threeSpadeHand = try Hand(cards: [.regular(.three, .spades)])
        let ruleSetJokersOff = RuleSet(jokers: false, threeSpadeReversal: true, jokerCount: 0)
        #expect(
            !ThreeSpadeReversal.triggers(newHand: threeSpadeHand, onto: soloJokerHand, ruleSet: ruleSetJokersOff),
            "Reversal must not fire when jokers are disabled"
        )
    }

    // MARK: validMoves

    @Test("3 of Spades appears in validMoves when trick top is a solo Joker and rule is enabled")
    func validMovesIncludesThreeSpadeWhenTrickTopIsSoloJoker() throws {
        let jokerHand = try Hand(cards: [.joker(index: 0)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [jokerHand],
            lastPlayedByIndex: 0
        )

        let moves = state.validMoves(for: p1.id)
        let threeSpadeMove = Move.play(cards: [.regular(.three, .spades)], by: p1.id)
        #expect(moves.contains(threeSpadeMove), "3♠ must be a valid move against a solo Joker when rule is on")
    }

    @Test("3 of Spades does not appear in validMoves when trick top is a solo Joker but rule is disabled")
    func validMovesExcludesThreeSpadeWhenRuleDisabled() throws {
        let jokerHand = try Hand(cards: [.joker(index: 0)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [jokerHand],
            lastPlayedByIndex: 0,
            threeSpadeReversal: false
        )

        let moves = state.validMoves(for: p1.id)
        let threeSpadeMove = Move.play(cards: [.regular(.three, .spades)], by: p1.id)
        #expect(!moves.contains(threeSpadeMove), "3♠ must not appear when rule is disabled")
    }

    // MARK: Revolution interaction

    @Test("regression: 3♠ reversal is legal under revolution (trump-of-trump beyond rank order)")
    func reversalUnderRevolutionAppearsInValidMoves() throws {
        let jokerHand = try Hand(cards: [.joker(index: 0)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [jokerHand],
            lastPlayedByIndex: 0,
            isRevolutionActive: true
        )

        let moves = state.validMoves(for: p1.id)
        let threeSpadeMove = Move.play(cards: [.regular(.three, .spades)], by: p1.id)
        #expect(moves.contains(threeSpadeMove), "3♠ must remain a legal beater of solo Joker even under revolution")
    }

    @Test("regression: applying 3♠ reversal under revolution clears the trick and grants lead")
    func reversalUnderRevolutionExecutes() throws {
        let jokerHand = try Hand(cards: [.joker(index: 0)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.five, .clubs)])
        let state = makeReversalState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [jokerHand],
            lastPlayedByIndex: 0,
            isRevolutionActive: true
        )

        let next = try state.apply(.play(cards: [.regular(.three, .spades)], by: p1.id))
        #expect(next.currentTrick.isEmpty, "Trick must clear after 3♠ reversal even under revolution")
        #expect(next.currentPlayerIndex == 1, "3♠ player must keep the lead")
        #expect(next.isRevolutionActive, "Revolution flag must be unaffected by the reversal play")
    }
}
