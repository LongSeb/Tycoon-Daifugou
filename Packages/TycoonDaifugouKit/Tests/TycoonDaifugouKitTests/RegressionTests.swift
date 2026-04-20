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

    @Test("Millionaire who can't keep title becomes Beggar (Bankruptcy)")
    func millionaireBankruptcy() throws {
        // Per the rules doc: "When playing with 4+ players, if the Millionaire
        // is not able to keep their title, they will instantly become the
        // Beggar and are out of play for the remainder of the round."
        //
        // Scenario: hand-crafted 4-player round 2, seat order [winner, defender, p2, p3].
        // winner leads with the only 2♥ — finishes 1st, gets Millionaire.
        // defender (the previous Millionaire) didn't go out first → bankrupt.
        // p2 and p3 pass (can't beat 2), trick resets to p2, p3 beats p2's lead,
        // last-player check fires: p2=poor, defender=beggar, round over.

        // p2 gets TWO cards so that leading 5♣ doesn't immediately end the round.
        let defender = Player(displayName: "Defender", hand: [.regular(.three, .clubs)])
        let winner = Player(displayName: "Winner", hand: [.regular(.two, .hearts)])
        let p2 = Player(displayName: "P2", hand: [.regular(.five, .clubs), .regular(.four, .diamonds)])
        let p3 = Player(displayName: "P3", hand: [.regular(.six, .clubs)])

        let players = [winner, defender, p2, p3]
        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        let totalCards = players.flatMap { $0.hand }.count

        var state = GameState(
            players: players,
            deck: [],
            currentPlayerIndex: 0,
            phase: .playing,
            ruleSet: RuleSet(bankruptcy: true),
            round: 2,
            scoresByPlayer: scores,
            defendingMillionaireID: defender.id
        )

        // winner plays 2♥ (last card) → Millionaire; defender goes bankrupt
        state = try state.apply(.play(cards: [.regular(.two, .hearts)], by: winner.id))
        #expect(state.players.first { $0.id == winner.id }?.currentTitle == .millionaire)
        #expect(state.players.first { $0.id == defender.id }?.isBankrupt == true)
        #expect(state.phase == .playing)

        // p2 and p3 pass; defender is skipped; trick resets to p2
        state = try state.apply(.pass(by: p2.id))
        state = try state.apply(.pass(by: p3.id))
        #expect(state.currentTrick.isEmpty)
        #expect(state.players[state.currentPlayerIndex].id == p2.id)

        // p2 leads 5♣ (keeps 4♦); p3 plays 6♣ (last card, beats 5♣)
        // → p3 rich, p2 poor, defender beggar → round ends
        state = try state.apply(.play(cards: [.regular(.five, .clubs)], by: p2.id))
        #expect(state.phase == .playing, "Round must continue — p3 still needs to play")
        state = try state.apply(.play(cards: [.regular(.six, .clubs)], by: p3.id))

        #expect(state.phase == .roundEnded)
        #expect(state.players.first { $0.id == winner.id }?.currentTitle == .millionaire)
        #expect(state.players.first { $0.id == p3.id }?.currentTitle == .rich)
        #expect(state.players.first { $0.id == p2.id }?.currentTitle == .poor)
        #expect(state.players.first { $0.id == defender.id }?.currentTitle == .beggar)
        #expect(state.allCards.count == totalCards, "Card count must be conserved")
    }

    // MARK: Scenario: 8-Stop House Rule

    @Test("8-Stop clears trick mid-game and returns lead to the 8-player")
    func eightStopClearsTrick() throws {
        // Scenario: 3 players, 8-Stop enabled.
        //   P0 leads 7♣.
        //   P1 plays 8♣ → 8-Stop fires: trick clears, P1 leads next.
        //   P1 leads 5♦.
        //   P2 passes; P0 plays 6♣ (beats 5); P1 and P2 pass → P0 wins trick.
        //   Verify card conservation throughout.

        let p0 = Player(displayName: "P0", hand: [
            .regular(.seven, .clubs),
            .regular(.six, .clubs),
            .regular(.ace, .hearts),
        ])
        let p1 = Player(displayName: "P1", hand: [
            .regular(.eight, .clubs),
            .regular(.five, .diamonds),
            .regular(.king, .spades),
        ])
        let p2 = Player(displayName: "P2", hand: [.regular(.four, .hearts)])

        let players = [p0, p1, p2]
        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        let totalCards = players.flatMap { $0.hand }.count

        var state = GameState(
            players: players,
            deck: [],
            currentPlayerIndex: 0,
            phase: .playing,
            ruleSet: RuleSet(eightStop: true),
            round: 1,
            scoresByPlayer: scores
        )

        // P0 leads 7♣
        state = try state.apply(.play(cards: [.regular(.seven, .clubs)], by: p0.id))
        #expect(state.currentTrick.count == 1)
        #expect(state.currentPlayerIndex == 1)

        // P1 plays 8♣ → 8-Stop fires
        state = try state.apply(.play(cards: [.regular(.eight, .clubs)], by: p1.id))
        #expect(state.currentTrick.isEmpty, "Trick must reset on 8-Stop")
        #expect(state.currentPlayerIndex == 1, "P1 must lead after 8-Stop")
        #expect(state.playedPile.contains(.regular(.seven, .clubs)))
        #expect(state.playedPile.contains(.regular(.eight, .clubs)))
        #expect(state.allCards.count == totalCards)

        // P1 leads 5♦ (fresh trick, no 8-Stop for 5)
        state = try state.apply(.play(cards: [.regular(.five, .diamonds)], by: p1.id))
        #expect(state.currentTrick.count == 1)

        // P2 passes, then P0 plays 6♣ (beats 5)
        state = try state.apply(.pass(by: p2.id))
        state = try state.apply(.play(cards: [.regular(.six, .clubs)], by: p0.id))

        // P1 and P2 pass → P0 wins the trick
        state = try state.apply(.pass(by: p1.id))
        state = try state.apply(.pass(by: p2.id))
        #expect(state.currentTrick.isEmpty, "Trick must clear when all others pass")
        #expect(state.currentPlayerIndex == 0, "P0 wins trick and leads next")
        #expect(state.allCards.count == totalCards, "Card count must be conserved")
    }

    // MARK: Scenario: Joker house rule

    @Test("Solo Joker beats strongest regular single and wins the round at endgame")
    func jokerSoloEndgame() throws {
        // Scenario:
        //   P0 leads 2♣ — the strongest regular single.
        //   P1 holds only a Joker. Joker appears in validMoves.
        //   P1 plays the Joker — it beats 2♣.
        //   P1's hand is now empty; only P0 remains → round ends immediately.

        let p0 = Player(displayName: "P0", hand: [
            .regular(.two, .clubs),
            .regular(.five, .hearts),
        ])
        let p1 = Player(displayName: "P1", hand: [.joker(index: 0)])
        let players = [p0, p1]
        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        let totalCards = players.flatMap { $0.hand }.count

        var state = GameState(
            players: players,
            deck: [],
            currentPlayerIndex: 0,
            phase: .playing,
            ruleSet: RuleSet(jokers: true, jokerCount: 1),
            round: 1,
            scoresByPlayer: scores
        )

        // P0 leads 2♣
        state = try state.apply(.play(cards: [.regular(.two, .clubs)], by: p0.id))
        #expect(state.currentTrick.count == 1)
        #expect(state.currentPlayerIndex == 1)

        // Joker appears in validMoves
        #expect(state.validMoves(for: p1.id).contains(.play(cards: [.joker(index: 0)], by: p1.id)))

        // P1 plays Joker — beats 2♣
        state = try state.apply(.play(cards: [.joker(index: 0)], by: p1.id))

        // P1 went out; P0 is the sole remaining player → round ends
        #expect(state.phase == .roundEnded)
        let p1Final = state.players.first { $0.id == p1.id }!
        let p0Final = state.players.first { $0.id == p0.id }!
        #expect(p1Final.currentTitle == .millionaire)
        #expect(p0Final.currentTitle == .beggar)
        #expect(state.allCards.count == totalCards, "Card count must be conserved")
    }

    // MARK: Rule scenario: 3-Spade Reversal

    @Test("3-Spade Reversal: 3♠ beats a solo Joker, clears trick, and awards lead in a live game")
    func threeSpadeReversalScenario() throws {
        // P0 plays Joker; P1 counters with 3♠, wins the trick, then leads normally.
        let p0 = Player(displayName: "P0", hand: [.joker(index: 0), .regular(.king, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.three, .spades), .regular(.ace, .clubs), .regular(.seven, .diamonds)])
        let scores = Dictionary(uniqueKeysWithValues: [p0, p1].map { ($0.id, 0) })
        let initial = GameState(
            players: [p0, p1],
            deck: [],
            currentTrick: [],
            currentPlayerIndex: 0,
            phase: .playing,
            ruleSet: RuleSet(jokers: true, threeSpadeReversal: true, jokerCount: 1),
            round: 1,
            scoresByPlayer: scores
        )

        // P0 leads with solo Joker
        let afterJoker = try initial.apply(.play(cards: [.joker(index: 0)], by: p0.id))
        #expect(afterJoker.currentTrick.last?.isSoloJoker == true)
        #expect(afterJoker.currentPlayerIndex == 1)

        // P1 counters with 3♠ — reversal fires
        let afterReversal = try afterJoker.apply(.play(cards: [.regular(.three, .spades)], by: p1.id))
        #expect(afterReversal.currentTrick.isEmpty, "Trick must be cleared by 3-Spade Reversal")
        #expect(
            afterReversal.players.first { $0.id == p1.id }?.id == afterReversal.players[afterReversal.currentPlayerIndex].id,
            "P1 must hold the lead after the reversal"
        )
        #expect(afterReversal.playedPile.contains(.joker(index: 0)))
        #expect(afterReversal.playedPile.contains(.regular(.three, .spades)))

        // P1 can now lead normally with A♣
        let afterLead = try afterReversal.apply(.play(cards: [.regular(.ace, .clubs)], by: p1.id))
        #expect(afterLead.currentTrick.last?.rank == .ace)
    }

    // MARK: Past bugs

    // Template for future regression tests. When you fix a bug, add a test
    // here titled `regression_<issueNumber>_<short_description>`. The test
    // body should reproduce the exact scenario that triggered the bug.
}
