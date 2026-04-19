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
    passCount: Int = 0,
    lastPlayedByIndex: Int? = nil
) -> GameState {
    let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    return GameState(
        players: players,
        deck: [],
        currentTrick: currentTrick,
        currentPlayerIndex: currentPlayerIndex,
        phase: .playing,
        ruleSet: .baseOnly,
        isRevolutionActive: false,
        round: 1,
        scoresByPlayer: scores,
        passCountSinceLastPlay: passCount,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

// MARK: - Play

@Suite("Reducer — play moves")
struct ReducerPlayTests {

    @Test("Valid single advances turn and moves card to trick")
    func basicSinglePlay() throws {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs), .regular(.king, .diamonds)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let initial = makeState(players: [p0, p1])

        let next = try initial.apply(.play(cards: [.regular(.five, .clubs)], by: p0.id))

        #expect(next.currentPlayerIndex == 1)
        #expect(next.currentTrick.count == 1)
        #expect(next.currentTrick[0].rank == .five)
        #expect(next.players[0].hand.count == 1)
        #expect(!next.players[0].hand.contains(.regular(.five, .clubs)))
        #expect(next.lastPlayedByIndex == 0)
        #expect(next.passCountSinceLastPlay == 0)
    }

    @Test("Second player beats first player's single")
    func secondPlayerBeatsFirst() throws {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.king, .hearts)])
        let fiveTrick = try Hand(cards: [.regular(.five, .clubs)])
        let initial = makeState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [fiveTrick],
            lastPlayedByIndex: 0
        )

        let next = try initial.apply(.play(cards: [.regular(.king, .hearts)], by: p1.id))

        #expect(next.currentTrick.count == 2)
        #expect(next.currentTrick.last?.rank == .king)
        #expect(next.lastPlayedByIndex == 1)
    }

    @Test("Playing out of turn throws notYourTurn")
    func playOutOfTurn() {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.seven, .diamonds)])
        let initial = makeState(players: [p0, p1], currentPlayerIndex: 0)

        #expect(throws: GameError.notYourTurn) {
            try initial.apply(.play(cards: [.regular(.seven, .diamonds)], by: p1.id))
        }
    }

    @Test("Playing cards not in hand throws cardsNotInHand")
    func playCardsNotInHand() {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let initial = makeState(players: [p0])

        #expect(throws: GameError.cardsNotInHand) {
            try initial.apply(.play(cards: [.regular(.king, .spades)], by: p0.id))
        }
    }

    @Test("Playing invalid hand (mixed ranks) throws invalidHand")
    func playInvalidHand() {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs), .regular(.six, .diamonds)])
        let initial = makeState(players: [p0])

        #expect(throws: GameError.invalidHand(.mixedRanks)) {
            try initial.apply(
                .play(cards: [.regular(.five, .clubs), .regular(.six, .diamonds)], by: p0.id)
            )
        }
    }

    @Test("Playing wrong hand type when trick has a single throws handTypeMismatch")
    func handTypeMismatch() throws {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.seven, .clubs), .regular(.seven, .diamonds)])
        let trick = try Hand(cards: [.regular(.five, .clubs)])
        let initial = makeState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        #expect(throws: GameError.handTypeMismatch) {
            try initial.apply(
                .play(cards: [.regular(.seven, .clubs), .regular(.seven, .diamonds)], by: p1.id)
            )
        }
    }

    @Test("Playing weaker single throws notStrongerThanCurrent")
    func weakerSingle() throws {
        let p0 = makePlayer("P0", cards: [.regular(.king, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .hearts)])
        let trick = try Hand(cards: [.regular(.king, .clubs)])
        let initial = makeState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        #expect(throws: GameError.notStrongerThanCurrent) {
            try initial.apply(.play(cards: [.regular(.three, .hearts)], by: p1.id))
        }
    }

    @Test("Playing equal rank throws notStrongerThanCurrent")
    func equalRank() throws {
        let p0 = makePlayer("P0", cards: [.regular(.seven, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.seven, .diamonds)])
        let trick = try Hand(cards: [.regular(.seven, .clubs)])
        let initial = makeState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        #expect(throws: GameError.notStrongerThanCurrent) {
            try initial.apply(.play(cards: [.regular(.seven, .diamonds)], by: p1.id))
        }
    }
}

// MARK: - Pass

@Suite("Reducer — pass moves")
struct ReducerPassTests {

    @Test("Passing out of turn throws notYourTurn")
    func passOutOfTurn() {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .hearts)])
        let initial = makeState(players: [p0, p1], currentPlayerIndex: 0)

        #expect(throws: GameError.notYourTurn) {
            try initial.apply(.pass(by: p1.id))
        }
    }

    @Test("Three consecutive passes in 4-player game reset trick and return lead")
    func allPassResetsTrick() throws {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs), .regular(.king, .diamonds)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let p2 = makePlayer("P2", cards: [.regular(.four, .hearts)])
        let p3 = makePlayer("P3", cards: [.regular(.six, .clubs)])
        var state = makeState(players: [p0, p1, p2, p3], currentPlayerIndex: 0)

        state = try state.apply(.play(cards: [.regular(.five, .clubs)], by: p0.id))
        #expect(state.currentPlayerIndex == 1)
        #expect(state.lastPlayedByIndex == 0)
        #expect(state.currentTrick.count == 1)

        state = try state.apply(.pass(by: p1.id))
        #expect(state.currentPlayerIndex == 2)
        #expect(state.passCountSinceLastPlay == 1)

        state = try state.apply(.pass(by: p2.id))
        #expect(state.currentPlayerIndex == 3)
        #expect(state.passCountSinceLastPlay == 2)

        state = try state.apply(.pass(by: p3.id))
        #expect(state.currentTrick.isEmpty, "Trick should reset after all-pass")
        #expect(state.currentPlayerIndex == 0, "P0 (last player) should get the lead")
        #expect(state.passCountSinceLastPlay == 0)
        #expect(state.lastPlayedByIndex == nil)
    }

    @Test("Partial pass sequence does not reset trick")
    func partialPassDoesNotReset() throws {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs), .regular(.king, .diamonds)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let p2 = makePlayer("P2", cards: [.regular(.four, .hearts)])
        var state = makeState(players: [p0, p1, p2], currentPlayerIndex: 0)

        state = try state.apply(.play(cards: [.regular(.five, .clubs)], by: p0.id))
        state = try state.apply(.pass(by: p1.id))

        #expect(!state.currentTrick.isEmpty, "Trick must not reset after only one pass")
        #expect(state.currentPlayerIndex == 2)
        #expect(state.passCountSinceLastPlay == 1)
    }

    @Test("Lead transfers to last player after second player wins and all pass")
    func midTrickWinnerGetsLead() throws {
        // P0 and P1 hold an extra card each so neither goes out after playing.
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs), .regular(.four, .hearts)])
        let p1 = makePlayer("P1", cards: [.regular(.king, .hearts), .regular(.jack, .spades)])
        let p2 = makePlayer("P2", cards: [.regular(.three, .spades)])
        var state = makeState(players: [p0, p1, p2], currentPlayerIndex: 0)

        state = try state.apply(.play(cards: [.regular(.five, .clubs)], by: p0.id))
        state = try state.apply(.play(cards: [.regular(.king, .hearts)], by: p1.id))
        #expect(state.lastPlayedByIndex == 1)

        state = try state.apply(.pass(by: p2.id))
        state = try state.apply(.pass(by: p0.id))

        #expect(state.currentTrick.isEmpty)
        #expect(state.currentPlayerIndex == 1, "P1 (last to play) should get the lead")
    }
}

// MARK: - Trade

@Suite("Reducer — trade moves")
struct ReducerTradeTests {

    @Test("Trade throws tradingNotSupportedYet")
    func tradingThrows() {
        let p0 = makePlayer("P0", cards: [.regular(.two, .spades)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .clubs)])
        let initial = makeState(players: [p0, p1])

        #expect(throws: GameError.tradingNotSupportedYet) {
            try initial.apply(.trade(cards: [.regular(.two, .spades)], from: p0.id, to: p1.id))
        }
    }
}

// MARK: - validMoves

@Suite("Reducer — validMoves")
struct ValidMovesTests {

    @Test("Returns empty when it is not the player's turn")
    func notYourTurn() {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.seven, .hearts)])
        let state = makeState(players: [p0, p1], currentPlayerIndex: 0)

        #expect(state.validMoves(for: p1.id).isEmpty)
    }

    @Test("Pass is excluded when trick is empty (player must lead)")
    func noPassWhenLeading() {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let state = makeState(players: [p0], currentPlayerIndex: 0)

        let moves = state.validMoves(for: p0.id)
        #expect(!moves.contains(.pass(by: p0.id)))
    }

    @Test("Pass is included when trick is non-empty")
    func includesPassWhenTrickNonEmpty() throws {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .hearts)])
        let trick = try Hand(cards: [.regular(.five, .clubs)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        #expect(state.validMoves(for: p1.id).contains(.pass(by: p1.id)))
    }

    @Test("Plays weaker than current trick are excluded")
    func excludesWeakerPlays() throws {
        let p0 = makePlayer("P0", cards: [.regular(.king, .spades)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .clubs), .regular(.four, .diamonds)])
        let trick = try Hand(cards: [.regular(.king, .spades)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        let moves = state.validMoves(for: p1.id)
        let playMoves = moves.filter { if case .play = $0 { return true }; return false }
        #expect(playMoves.isEmpty, "3 and 4 cannot beat king")
        #expect(moves == [.pass(by: p1.id)])
    }

    @Test("Wrong-type plays excluded when trick has a single")
    func excludesWrongTypePlays() throws {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.nine, .hearts), .regular(.nine, .spades)])
        let trick = try Hand(cards: [.regular(.five, .clubs)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        let moves = state.validMoves(for: p1.id)
        let playMoves = moves.filter { if case .play = $0 { return true }; return false }
        // Only a single nine is valid (not the pair) since trick type is .single
        #expect(playMoves.count == 2, "One single nine♥ and one single nine♠")
    }

    @Test("All valid hand types generated from empty trick")
    func allPlaysFromEmptyTrick() {
        let p0 = makePlayer("P0", cards: [
            .regular(.five, .clubs),
            .regular(.five, .diamonds),
            .regular(.king, .hearts),
        ])
        let state = makeState(players: [p0], currentPlayerIndex: 0)

        let moves = state.validMoves(for: p0.id)
        let playMoves = moves.filter { if case .play = $0 { return true }; return false }

        // Expected: single 5♣, single 5♦, single K♥, pair [5♣,5♦] — 4 plays, no pass
        #expect(playMoves.count == 4)
        #expect(!moves.contains(.pass(by: p0.id)))
    }

    @Test("Stronger plays included, weaker excluded when trick is active")
    func onlyStrongerPlays() throws {
        let p0 = makePlayer("P0", cards: [.regular(.seven, .clubs)])
        let p1 = makePlayer("P1", cards: [
            .regular(.three, .hearts),
            .regular(.six,   .clubs),
            .regular(.nine,  .spades),
            .regular(.two,   .diamonds),
        ])
        let trick = try Hand(cards: [.regular(.seven, .clubs)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        let moves = state.validMoves(for: p1.id)
        let playMoves = moves.filter { if case .play = $0 { return true }; return false }

        // 3 and 6 are weaker; only 9 and 2 (rank 15) are stronger singles
        #expect(playMoves.count == 2)
        #expect(moves.contains(.pass(by: p1.id)))
    }
}
