import Testing
@testable import TycoonDaifugouKit

// MARK: - Regression tests
//
// Regression tests replay recorded game scenarios and verify final state.
// Unlike pure unit tests, these exercise the full engine — dealing, turn
// order, move validation, scoring — end to end. They serve two purposes:
//
//   1. Catching regressions. When you fix a bug, encode the scenario that
//      triggered it here so it can never silently come back.
//   2. Integration testing the engine. If `apply(move:to:)` is correct but
//      `validMoves(for:state:)` has a bug that prevents a legal move from
//      being recognized, a unit test on either function alone won't catch
//      it. A scenario test will.
//
// PATTERN: define the scenario as data (seed for dealing, list of moves),
// then assert on the final state. Never hand-construct a `GameState` mid-
// scenario — that defeats the point.

@Suite("Engine regression scenarios")
struct RegressionTests {

    // MARK: Helpers

    private static func makePlayers() -> [Player] {
        ["P0", "P1", "P2", "P3"].map { Player(displayName: $0) }
    }

    private static func tradingStrength(_ card: Card) -> Int {
        switch card {
        case .joker: return Int.max
        case .regular(let rank, _): return rank.rawValue
        }
    }

    private static func strongest(_ n: Int, from player: Player) -> [Card] {
        Array(player.hand.sorted { tradingStrength($0) > tradingStrength($1) }.prefix(n))
    }

    // MARK: Scenario: vanilla 4-player, two full rounds with trading

    @Test("4-player base game: round 1 completes, trading executes correctly, round 2 begins")
    func fourPlayerBaseGame() throws {
        let players = Self.makePlayers()
        let initial = GameState.newGame(players: players, ruleSet: .baseOnly, seed: 42)

        // Play round 1 to completion
        let states = SimulatedPlaythrough.states(from: initial)
        guard let roundEnded = states.last, roundEnded.phase == .roundEnded else {
            Issue.record("Round 1 did not reach .roundEnded")
            return
        }

        // All 4 players must have titles after round 1
        #expect(roundEnded.players.allSatisfy { $0.currentTitle != nil })

        // Confirm expected title structure exists for trading
        #expect(roundEnded.players.contains { $0.currentTitle == .millionaire })
        #expect(roundEnded.players.contains { $0.currentTitle == .beggar })

        // Start round 2
        let round2 = roundEnded.startNextRound(seed: 99)
        #expect(round2.phase == .trading)
        #expect(round2.round == 2)

        // 52 cards conserved across the re-deal
        #expect(round2.allCards.count == 52)

        // Pending trades: Beg→Mill×2, Poor→Rich×1, Mill→Beg×2, Rich→Poor×1
        let pending = requiredTrades(for: round2)
        #expect(pending.count == 4)
        #expect(pending[0].cardCount == 2 && pending[0].mustGiveStrongest)
        #expect(pending[1].cardCount == 1 && pending[1].mustGiveStrongest)
        #expect(pending[2].cardCount == 2 && !pending[2].mustGiveStrongest)
        #expect(pending[3].cardCount == 1 && !pending[3].mustGiveStrongest)

        // Apply all trades in the scheduled order
        var state = round2
        for trade in pending {
            let player = state.players.first { $0.id == trade.from }!
            let cards: [Card]
            if trade.mustGiveStrongest {
                cards = Self.strongest(trade.cardCount, from: player)
            } else {
                cards = Array(player.hand.prefix(trade.cardCount))
            }
            state = try state.apply(.trade(cards: cards, from: trade.from, to: trade.to))
        }

        // After all trades, phase must be .playing
        #expect(state.phase == .playing)

        // All titles cleared; 52 cards still conserved
        #expect(state.players.allSatisfy { $0.currentTitle == nil })
        #expect(state.allCards.count == 52)

        // 3♦ holder leads
        let leader = state.players[state.currentPlayerIndex]
        #expect(leader.hand.contains(.regular(.three, .diamonds)))
    }

    // MARK: Scenario: Revolution House Rule

    @Test("Revolution flips card strength mid-game")
    func revolutionFlipsStrength() throws {
        // Scenario:
        //   P0 holds a quad of 7s (revolution trigger) and a 5♣ (lead after winning the trick).
        //   P1 holds a 4♣ (weaker than 5 normally, stronger in revolution) and a 6♣ (stronger
        //   than 5 normally, weaker in revolution) and an A♥ (extra card so P1 doesn't go out).
        //   P2 holds an 8♠ so the round doesn't end prematurely.
        //
        //   1. P0 plays quad of 7s → revolution activates.
        //   2. P1 and P2 pass → P0 wins the trick; revolution persists.
        //   3. P0 leads 5♣.
        //   4. P1's 6♣ (normally stronger than 5) is rejected — weakened by revolution.
        //   5. P1's 4♣ (normally weaker than 5) is accepted — strengthened by revolution.

        let p0 = Player(displayName: "P0", hand: [
            .regular(.seven, .clubs), .regular(.seven, .diamonds),
            .regular(.seven, .hearts), .regular(.seven, .spades),
            .regular(.five, .clubs),
        ])
        let p1 = Player(displayName: "P1", hand: [
            .regular(.four, .clubs),
            .regular(.six, .clubs),
            .regular(.ace, .hearts),
        ])
        let p2 = Player(displayName: "P2", hand: [.regular(.eight, .spades)])
        let players = [p0, p1, p2]
        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })

        var state = GameState(
            players: players,
            deck: [],
            currentPlayerIndex: 0,
            phase: .playing,
            ruleSet: RuleSet(revolution: true),
            isRevolutionActive: false,
            round: 1,
            scoresByPlayer: scores
        )

        // Step 1: P0 plays quad of 7s
        let quadOf7s: [Card] = [
            .regular(.seven, .clubs), .regular(.seven, .diamonds),
            .regular(.seven, .hearts), .regular(.seven, .spades),
        ]
        state = try state.apply(.play(cards: quadOf7s, by: p0.id))
        #expect(state.isRevolutionActive, "Quad must trigger revolution")

        // Step 2: P1 and P2 pass; P0 wins the trick
        state = try state.apply(.pass(by: p1.id))
        state = try state.apply(.pass(by: p2.id))
        #expect(state.currentTrick.isEmpty, "Trick must reset after all pass")
        #expect(state.currentPlayerIndex == 0, "P0 (last to play) must lead the new trick")
        #expect(state.isRevolutionActive, "Revolution must persist across the trick reset")

        // Step 3: P0 leads 5♣
        state = try state.apply(.play(cards: [.regular(.five, .clubs)], by: p0.id))

        // Step 4: P1's 6♣ is normally stronger than 5 but weaker in revolution — rejected
        #expect(throws: GameError.notStrongerThanCurrent) {
            try state.apply(.play(cards: [.regular(.six, .clubs)], by: p1.id))
        }

        // Step 5: P1's 4♣ is normally weaker than 5 but stronger in revolution — accepted
        let afterFour = try state.apply(.play(cards: [.regular(.four, .clubs)], by: p1.id))
        #expect(afterFour.currentTrick.last?.rank == .four, "4 must beat 5 in revolution")
    }

    // MARK: Scenario: Bankruptcy rule

    @Test("Millionaire who can't keep title becomes Beggar (Bankruptcy)", .disabled("Not yet implemented"))
    func millionaireBankruptcy() throws {
        // Per the rules doc: "When playing with 4+ players, if the Millionaire
        // is not able to keep their title, they will instantly become the
        // Beggar and are out of play for the remainder of the round."
    }

    // MARK: Past bugs

    // Template for future regression tests. When you fix a bug, add a test
    // here titled `regression_<issueNumber>_<short_description>`. The test
    // body should reproduce the exact scenario that triggered the bug.
}
