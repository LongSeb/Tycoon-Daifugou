import Testing
@testable import TycoonDaifugouKit

// MARK: - Helpers

private func makeEightStopState(
    players: [Player],
    currentPlayerIndex: Int = 0,
    currentTrick: [Hand] = [],
    lastPlayedByIndex: Int? = nil,
    ruleEnabled: Bool = true
) -> GameState {
    let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    return GameState(
        players: players,
        deck: [],
        currentTrick: currentTrick,
        currentPlayerIndex: currentPlayerIndex,
        phase: .playing,
        ruleSet: RuleSet(eightStop: ruleEnabled),
        round: 1,
        scoresByPlayer: scores,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

// MARK: - EightStop tests

@Suite("8-Stop house rule")
struct EightStopTests {

    // MARK: Rule disabled

    @Test("Playing an 8 without the rule enabled does not reset the trick")
    func ruleDisabledDoesNotTrigger() throws {
        let sevenTrick = try Hand(cards: [.regular(.seven, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.eight, .hearts), .regular(.five, .spades)])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenTrick],
            lastPlayedByIndex: 0,
            ruleEnabled: false
        )

        let next = try state.apply(.play(cards: [.regular(.eight, .hearts)], by: p1.id))
        #expect(!next.currentTrick.isEmpty, "Trick must continue when rule is disabled")
        #expect(next.currentTrick.last?.rank == .eight)
        #expect(next.currentPlayerIndex == 0, "Turn must advance normally when rule is disabled")
    }

    // MARK: Activation by hand size

    @Test("Single 8 resets the trick and returns lead to the player")
    func singleEightResetsTrick() throws {
        let sevenTrick = try Hand(cards: [.regular(.seven, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.eight, .hearts), .regular(.five, .spades)])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenTrick],
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: [.regular(.eight, .hearts)], by: p1.id))
        #expect(next.currentTrick.isEmpty, "Trick must reset on 8-Stop")
        #expect(next.currentPlayerIndex == 1, "Player who played the 8 must lead next")
    }

    @Test("Pair of 8s resets the trick")
    func pairOfEightsResetsTrick() throws {
        let sevenPair = try Hand(cards: [.regular(.seven, .clubs), .regular(.seven, .diamonds)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [
            .regular(.eight, .clubs), .regular(.eight, .diamonds), .regular(.five, .spades),
        ])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenPair],
            lastPlayedByIndex: 0
        )

        let eightPair: [Card] = [.regular(.eight, .clubs), .regular(.eight, .diamonds)]
        let next = try state.apply(.play(cards: eightPair, by: p1.id))
        #expect(next.currentTrick.isEmpty)
        #expect(next.currentPlayerIndex == 1)
    }

    @Test("Triple of 8s resets the trick")
    func tripleOfEightsResetsTrick() throws {
        let sevenTriple = try Hand(cards: [
            .regular(.seven, .clubs), .regular(.seven, .diamonds), .regular(.seven, .hearts),
        ])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [
            .regular(.eight, .clubs), .regular(.eight, .diamonds), .regular(.eight, .hearts),
            .regular(.five, .spades),
        ])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenTriple],
            lastPlayedByIndex: 0
        )

        let eightTriple: [Card] = [
            .regular(.eight, .clubs), .regular(.eight, .diamonds), .regular(.eight, .hearts),
        ]
        let next = try state.apply(.play(cards: eightTriple, by: p1.id))
        #expect(next.currentTrick.isEmpty)
        #expect(next.currentPlayerIndex == 1)
    }

    @Test("Quad of 8s resets the trick (Revolution disabled)")
    func quadOfEightsResetsTrick() throws {
        let sevenQuad = try Hand(cards: [
            .regular(.seven, .clubs), .regular(.seven, .diamonds),
            .regular(.seven, .hearts), .regular(.seven, .spades),
        ])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [
            .regular(.eight, .clubs), .regular(.eight, .diamonds),
            .regular(.eight, .hearts), .regular(.eight, .spades),
            .regular(.five, .spades),
        ])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenQuad],
            lastPlayedByIndex: 0
        )

        let eightQuad: [Card] = [
            .regular(.eight, .clubs), .regular(.eight, .diamonds),
            .regular(.eight, .hearts), .regular(.eight, .spades),
        ]
        let next = try state.apply(.play(cards: eightQuad, by: p1.id))
        #expect(next.currentTrick.isEmpty)
        #expect(next.currentPlayerIndex == 1)
    }

    // MARK: Joker interaction

    @Test("Pair of [8, Joker] (rank is still 8) triggers 8-Stop")
    func eightWithJokerTriggers() throws {
        let sevenPair = try Hand(cards: [.regular(.seven, .clubs), .regular(.seven, .diamonds)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [
            .regular(.eight, .clubs), .joker(index: 0), .regular(.five, .hearts),
        ])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenPair],
            lastPlayedByIndex: 0
        )

        let next = try state.apply(
            .play(cards: [.regular(.eight, .clubs), .joker(index: 0)], by: p1.id)
        )
        #expect(next.currentTrick.isEmpty, "8-Stop must fire for Joker-8 pair")
        #expect(next.currentPlayerIndex == 1)
    }

    // MARK: Strength check still applies

    @Test("8 cannot beat a 9 — play is rejected before 8-Stop can fire")
    func eightCannotBeatNine() throws {
        let nineTrick = try Hand(cards: [.regular(.nine, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.eight, .hearts)])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [nineTrick],
            lastPlayedByIndex: 0
        )

        #expect(throws: GameError.notStrongerThanCurrent) {
            try state.apply(.play(cards: [.regular(.eight, .hearts)], by: p1.id))
        }
    }

    @Test("8 beats a 7 and then stops the trick")
    func eightBeatsSevenAndStops() throws {
        let sevenTrick = try Hand(cards: [.regular(.seven, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.eight, .hearts), .regular(.five, .spades)])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenTrick],
            lastPlayedByIndex: 0
        )

        // No error — 8 > 7 — and the 8-Stop fires
        let next = try state.apply(.play(cards: [.regular(.eight, .hearts)], by: p1.id))
        #expect(next.currentTrick.isEmpty)
    }

    // MARK: State after 8-Stop

    @Test("Cards from trick and the 8 move to playedPile after 8-Stop")
    func cardsMovedToPlayedPile() throws {
        let sevenTrick = try Hand(cards: [.regular(.seven, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.eight, .hearts), .regular(.five, .spades)])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenTrick],
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: [.regular(.eight, .hearts)], by: p1.id))
        #expect(next.playedPile.contains(.regular(.seven, .clubs)), "7♣ must be in playedPile")
        #expect(next.playedPile.contains(.regular(.eight, .hearts)), "8♥ must be in playedPile")
        #expect(next.allCards.count == state.allCards.count, "Card count must be conserved")
    }

    @Test("passCountSinceLastPlay and lastPlayedByIndex reset after 8-Stop")
    func passStateResetsAfterEightStop() throws {
        let sixTrick = try Hand(cards: [.regular(.six, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.eight, .hearts), .regular(.five, .spades)])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sixTrick],
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: [.regular(.eight, .hearts)], by: p1.id))
        #expect(next.passCountSinceLastPlay == 0)
        #expect(next.lastPlayedByIndex == nil)
    }

    // MARK: Edge cases

    @Test("Playing an 8 as the leader (empty trick) resets the trick and re-leads")
    func eightAsLeaderReLeads() throws {
        let p0 = Player(displayName: "P0", hand: [.regular(.eight, .clubs), .regular(.five, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.king, .spades)])
        // Trick is empty — P0 is the leader
        let state = makeEightStopState(players: [p0, p1], currentPlayerIndex: 0)

        let next = try state.apply(.play(cards: [.regular(.eight, .clubs)], by: p0.id))
        #expect(next.currentTrick.isEmpty)
        #expect(next.currentPlayerIndex == 0, "Leader who plays 8 must still lead next trick")
    }

    @Test("8-Stop does not fire when player goes out on 8s")
    func eightStopDoesNotFireOnGoingOut() throws {
        // P1 has exactly the 8s — playing them empties their hand.
        // Going-out takes priority; the 8-Stop effect does not fire.
        let sevenTrick = try Hand(cards: [.regular(.seven, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs), .regular(.queen, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.eight, .hearts)])
        let state = makeEightStopState(
            players: [p0, p1],
            currentPlayerIndex: 1,
            currentTrick: [sevenTrick],
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: [.regular(.eight, .hearts)], by: p1.id))
        // P1 went out, so 8-Stop must NOT fire — only one player remains (P0), round ends
        #expect(next.phase == .roundEnded)
        #expect(!next.currentTrick.isEmpty || next.phase == .roundEnded)
    }

    // MARK: Revolution + 8-Stop interaction

    @Test("Quad of 8s toggles Revolution AND resets the trick when both rules are enabled")
    func eightStopAndRevolutionBothFire() throws {
        let eightQuad: [Card] = [
            .regular(.eight, .clubs), .regular(.eight, .diamonds),
            .regular(.eight, .hearts), .regular(.eight, .spades),
        ]
        let sevenQuad = try Hand(cards: [
            .regular(.seven, .clubs), .regular(.seven, .diamonds),
            .regular(.seven, .hearts), .regular(.seven, .spades),
        ])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: eightQuad + [.regular(.five, .spades)])
        let scores = Dictionary(uniqueKeysWithValues: [p0, p1].map { ($0.id, 0) })
        let state = GameState(
            players: [p0, p1],
            deck: [],
            currentTrick: [sevenQuad],
            currentPlayerIndex: 1,
            phase: .playing,
            ruleSet: RuleSet(revolution: true, eightStop: true),
            isRevolutionActive: false,
            round: 1,
            scoresByPlayer: scores,
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: eightQuad, by: p1.id))
        #expect(next.isRevolutionActive, "Quad of 8s must toggle Revolution")
        #expect(next.currentTrick.isEmpty, "8-Stop must still reset the trick")
        #expect(next.currentPlayerIndex == 1, "P1 must lead after 8-Stop")
    }

    @Test("In Revolution, an 8 beats a 9 and triggers 8-Stop")
    func eightBeatsNineInRevolutionAndStops() throws {
        let nineTrick = try Hand(cards: [.regular(.nine, .clubs)])
        let p0 = Player(displayName: "P0", hand: [.regular(.king, .clubs)])
        let p1 = Player(displayName: "P1", hand: [.regular(.eight, .hearts), .regular(.five, .spades)])
        let scores = Dictionary(uniqueKeysWithValues: [p0, p1].map { ($0.id, 0) })
        // Revolution is active: lower ranks are stronger, so 8 beats 9
        let state = GameState(
            players: [p0, p1],
            deck: [],
            currentTrick: [nineTrick],
            currentPlayerIndex: 1,
            phase: .playing,
            ruleSet: RuleSet(eightStop: true),
            isRevolutionActive: true,
            round: 1,
            scoresByPlayer: scores,
            lastPlayedByIndex: 0
        )

        let next = try state.apply(.play(cards: [.regular(.eight, .hearts)], by: p1.id))
        #expect(next.currentTrick.isEmpty, "8 beats 9 in Revolution and 8-Stop fires")
        #expect(next.currentPlayerIndex == 1)
    }
}
