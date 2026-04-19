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

    @Test("Revolution flips card strength mid-game", .disabled("Not yet implemented"))
    func revolutionFlipsStrength() throws {
        // When a player plays 4-of-a-kind, the next valid move must be
        // evaluated against FLIPPED strength order. Record a scenario where
        // this actually happens and verify the engine enforces it.
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
