import Testing
@testable import TycoonDaifugouKit

// MARK: - Helpers

private func makeRevolutionState(
    players: [Player],
    currentPlayerIndex: Int = 0,
    currentTrick: [Hand] = [],
    passCount: Int = 0,
    lastPlayedByIndex: Int? = nil,
    isRevolutionActive: Bool = false,
    ruleEnabled: Bool = true
) -> GameState {
    let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    return GameState(
        players: players,
        deck: [],
        currentTrick: currentTrick,
        currentPlayerIndex: currentPlayerIndex,
        phase: .playing,
        ruleSet: RuleSet(revolution: ruleEnabled),
        isRevolutionActive: isRevolutionActive,
        round: 1,
        scoresByPlayer: scores,
        passCountSinceLastPlay: passCount,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

private func allFour(_ rank: Rank) -> [Card] {
    Suit.allCases.map { .regular(rank, $0) }
}

// MARK: - Revolution tests

@Suite("Revolution house rule")
struct RevolutionTests {

    // MARK: Activation / deactivation

    @Test("Playing a quad without the rule enabled does not activate revolution")
    func quadWithoutRuleDoesNotActivate() throws {
        let p0 = Player(displayName: "P0", hand: allFour(.five) + [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .hearts)])
        var state = makeRevolutionState(players: [p0, p1], ruleEnabled: false)

        state = try state.apply(.play(cards: allFour(.five), by: p0.id))
        #expect(!state.isRevolutionActive)
    }

    @Test("Playing a quad with the rule enabled activates revolution")
    func quadWithRuleActivatesRevolution() throws {
        let p0 = Player(displayName: "P0", hand: allFour(.five) + [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .hearts)])
        var state = makeRevolutionState(players: [p0, p1], ruleEnabled: true)

        state = try state.apply(.play(cards: allFour(.five), by: p0.id))
        #expect(state.isRevolutionActive)
    }

    @Test("Playing a second quad (Counter-Revolution) deactivates revolution")
    func counterRevolutionDeactivates() throws {
        let p0 = Player(displayName: "P0", hand: allFour(.five) + [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: allFour(.three) + [.regular(.ace, .clubs)])
        var state = makeRevolutionState(players: [p0, p1], ruleEnabled: true)

        // P0 plays quad of 5s → revolution active
        state = try state.apply(.play(cards: allFour(.five), by: p0.id))
        #expect(state.isRevolutionActive)

        // P1 plays quad of 3s; in revolution 3 < 5 normally → stronger, so it beats the quad of 5s
        state = try state.apply(.play(cards: allFour(.three), by: p1.id))
        #expect(!state.isRevolutionActive, "Counter-revolution must deactivate revolution")
    }

    // MARK: Strength inversion

    @Test("After revolution, a 3 beats a 4 as a single")
    func afterRevolutionThreeBeatsForSingle() throws {
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        // Extra card so P1 doesn't go out and trigger round-end (which clears currentTrick)
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .hearts), .regular(.ace, .spades)])
        let fourTrick = try Hand(cards: [.regular(.four, .diamonds)])
        let state = makeRevolutionState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [fourTrick],
            lastPlayedByIndex: 0,
            isRevolutionActive: true
        )

        let next = try state.apply(.play(cards: [.regular(.three, .hearts)], by: p1.id))
        #expect(next.currentTrick.last?.rank == .three)
    }

    @Test("After revolution, quad of 3s beats quad of 4s")
    func afterRevolutionQuadThreeBeatsQuadFour() throws {
        let threes = allFour(.three)
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: threes + [.regular(.two, .clubs)])
        let fourTrick = try Hand(cards: allFour(.four))
        var state = makeRevolutionState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [fourTrick],
            lastPlayedByIndex: 0,
            isRevolutionActive: true
        )

        // Quad of 3s beats quad of 4s in revolution (3 < 4 normally → stronger in revolution)
        state = try state.apply(.play(cards: threes, by: p1.id))
        #expect(state.currentTrick.last?.rank == .three)
        // Playing the second quad triggers counter-revolution
        #expect(!state.isRevolutionActive)
    }

    @Test("After revolution, a normally-strong card (2) cannot beat a 3")
    func afterRevolutionTwoCannotBeatThree() throws {
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.two, .hearts)])
        let threeTrick = try Hand(cards: [.regular(.three, .clubs)])
        let state = makeRevolutionState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [threeTrick],
            lastPlayedByIndex: 0,
            isRevolutionActive: true
        )

        // 2 is normally strongest (raw 15) but weakest in revolution; 3 is strongest in revolution
        #expect(throws: GameError.notStrongerThanCurrent) {
            try state.apply(.play(cards: [.regular(.two, .hearts)], by: p1.id))
        }
    }

    // MARK: Persistence across tricks

    @Test("Revolution state persists when a trick resets")
    func revolutionPersistsAcrossTricks() throws {
        let p0 = Player(displayName: "P0", hand: allFour(.seven) + [.regular(.five, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.four, .diamonds), .regular(.king, .hearts)])
        let p2 = Player(displayName: "P2", hand: [.regular(.eight, .spades)])
        var state = makeRevolutionState(players: [p0, p1, p2], ruleEnabled: true)

        // P0 plays quad of 7s → revolution
        state = try state.apply(.play(cards: allFour(.seven), by: p0.id))
        #expect(state.isRevolutionActive)

        // P1 and P2 both pass → trick resets, P0 leads again
        state = try state.apply(.pass(by: p1.id))
        state = try state.apply(.pass(by: p2.id))
        #expect(state.currentTrick.isEmpty, "Trick must reset after all pass")
        #expect(state.isRevolutionActive, "Revolution must persist across trick reset")

        // P0 leads 5♣; P1's 4♦ beats it in revolution (4 < 5 normally → stronger in revolution)
        state = try state.apply(.play(cards: [.regular(.five, .clubs)], by: p0.id))
        let next = try state.apply(.play(cards: [.regular(.four, .diamonds)], by: p1.id))
        #expect(next.currentTrick.last?.rank == .four)
    }

    // MARK: validMoves reflects revolution

    @Test("validMoves excludes normally-stronger cards when revolution is active")
    func validMovesExcludesNormallyStrongerInRevolution() throws {
        // Trick has a 5. In revolution only ranks numerically below 5 beat it (4, 3).
        // P1 holds [4♦, 6♥, A♠]. Only 4♦ is valid; 6 and ace are excluded.
        let fiveTrick = try Hand(cards: [.regular(.five, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.nine, .clubs)])
        let p1 = Player(displayName: "P1", hand: [
            .regular(.four, .diamonds),
            .regular(.six, .hearts),
            .regular(.ace, .spades),
        ])
        let state = makeRevolutionState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [fiveTrick],
            lastPlayedByIndex: 0,
            isRevolutionActive: true
        )

        let moves = state.validMoves(for: p1.id)
        let playMoves = moves.filter { if case .play = $0 { return true }; return false }

        #expect(playMoves.count == 1)
        #expect(playMoves.contains(.play(cards: [.regular(.four, .diamonds)], by: p1.id)))
    }
}
