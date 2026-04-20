import Testing
@testable import TycoonDaifugouKit

// MARK: - Helpers

private func makeBankruptcyState(
    players: [Player],
    currentPlayerIndex: Int = 0,
    currentTrick: [Hand] = [],
    lastPlayedByIndex: Int? = nil,
    defendingMillionaireID: PlayerID? = nil,
    ruleEnabled: Bool = true
) -> GameState {
    let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    return GameState(
        players: players,
        deck: [],
        currentTrick: currentTrick,
        currentPlayerIndex: currentPlayerIndex,
        phase: .playing,
        ruleSet: RuleSet(bankruptcy: ruleEnabled),
        round: 2,
        scoresByPlayer: scores,
        lastPlayedByIndex: lastPlayedByIndex,
        defendingMillionaireID: defendingMillionaireID
    )
}

// MARK: - BankruptcyTests

@Suite("Bankruptcy house rule")
struct BankruptcyTests {

    // MARK: Defending Millionaire keeps title

    @Test("Defending Millionaire finishes 1st: no bankruptcy triggered")
    func defendingMillionaireKeepsTitle() throws {
        let defender = Player(displayName: "Defender", hand: [.regular(.two, .hearts)])
        let p1 = Player(displayName: "P1", hand: [.regular(.five, .clubs), .regular(.six, .clubs)])
        let p2 = Player(displayName: "P2", hand: [.regular(.seven, .clubs)])
        let p3 = Player(displayName: "P3", hand: [.regular(.eight, .clubs)])

        let state = makeBankruptcyState(
            players: [defender, p1, p2, p3],
            currentPlayerIndex: 0,
            defendingMillionaireID: defender.id
        )

        // Defender plays their last card and finishes 1st
        let next = try state.apply(.play(cards: [.regular(.two, .hearts)], by: defender.id))

        let defenderFinal = next.players.first { $0.id == defender.id }!
        #expect(defenderFinal.currentTitle == .millionaire, "Defending Millionaire who finishes 1st keeps their title")
        #expect(!defenderFinal.isBankrupt, "No bankruptcy when Millionaire defends successfully")
        #expect(next.phase == .playing, "Round must continue with 3 remaining players")
    }

    // MARK: Defending Millionaire finishes 2nd — instant Beggar

    @Test("Defending Millionaire finishes 2nd or later: marked bankrupt immediately")
    func defendingMillionaireGoesBankrupt() throws {
        let defender = Player(displayName: "Defender", hand: [.regular(.five, .clubs), .regular(.king, .clubs)])
        let winner = Player(displayName: "Winner", hand: [.regular(.two, .hearts)])
        let p2 = Player(displayName: "P2", hand: [.regular(.six, .clubs)])
        let p3 = Player(displayName: "P3", hand: [.regular(.seven, .clubs)])

        let state = makeBankruptcyState(
            players: [winner, defender, p2, p3],
            currentPlayerIndex: 0,
            defendingMillionaireID: defender.id
        )

        // Winner finishes 1st — defender did NOT go out first
        let next = try state.apply(.play(cards: [.regular(.two, .hearts)], by: winner.id))

        let winnerFinal = next.players.first { $0.id == winner.id }!
        let defenderFinal = next.players.first { $0.id == defender.id }!

        #expect(winnerFinal.currentTitle == .millionaire, "First finisher must be awarded Millionaire")
        #expect(defenderFinal.isBankrupt, "Defending Millionaire who did not finish 1st must be bankrupt")
        #expect(defenderFinal.currentTitle == nil, "Bankrupt player's title is assigned only at round end")
        #expect(next.phase == .playing, "Round must continue — P2 and P3 still active")
    }

    @Test("Bankrupt player is skipped during subsequent turns")
    func bankruptPlayerSkippedByNextActive() throws {
        let defender = Player(displayName: "Defender", hand: [.regular(.five, .clubs), .regular(.king, .clubs)])
        let winner = Player(displayName: "Winner", hand: [.regular(.two, .hearts)])
        let p2 = Player(displayName: "P2", hand: [.regular(.six, .clubs)])
        let p3 = Player(displayName: "P3", hand: [.regular(.seven, .clubs)])

        // Seat order: winner(0), defender(1), p2(2), p3(3)
        var state = makeBankruptcyState(
            players: [winner, defender, p2, p3],
            currentPlayerIndex: 0,
            defendingMillionaireID: defender.id
        )

        // Winner plays their last card; defender goes bankrupt
        state = try state.apply(.play(cards: [.regular(.two, .hearts)], by: winner.id))
        // Next player after winner(0) should be p2(2), skipping bankrupt defender(1)
        #expect(state.players[state.currentPlayerIndex].id == p2.id,
                "Bankrupt player must be skipped — p2 should be next")
    }

    @Test("Bankrupt player receives Beggar title when round ends")
    func bankruptPlayerGetsBeggarAtRoundEnd() throws {
        // 4 players. winner goes out first (mill), defender goes bankrupt.
        // p2 leads a trick; p3 goes out on that trick (rich); p2 is the last
        // active player → poor; defender → beggar.
        //
        // p2 gets TWO cards so that leading 5♣ doesn't immediately end the round.
        let defender = Player(displayName: "Defender", hand: [.regular(.three, .clubs)])
        let winner = Player(displayName: "Winner", hand: [.regular(.two, .hearts)])
        let p2 = Player(displayName: "P2", hand: [.regular(.five, .clubs), .regular(.four, .diamonds)])
        let p3 = Player(displayName: "P3", hand: [.regular(.six, .clubs)])

        let totalCards = [defender, winner, p2, p3].flatMap { $0.hand }.count

        var state = makeBankruptcyState(
            players: [winner, defender, p2, p3],
            currentPlayerIndex: 0,
            defendingMillionaireID: defender.id
        )

        // Step 1: winner plays 2♥ → mill; defender goes bankrupt
        state = try state.apply(.play(cards: [.regular(.two, .hearts)], by: winner.id))
        #expect(state.players.first { $0.id == winner.id }?.currentTitle == .millionaire)
        #expect(state.players.first { $0.id == defender.id }?.isBankrupt == true)

        // Step 2: p2 and p3 pass (can't beat 2♥); defender skipped → trick resets to p2
        state = try state.apply(.pass(by: p2.id))
        state = try state.apply(.pass(by: p3.id))
        #expect(state.currentTrick.isEmpty, "Trick must reset after all active players pass")
        #expect(state.players[state.currentPlayerIndex].id == p2.id, "p2 must lead after trick reset")

        // Step 3: p2 leads 5♣ (still holds 4♦ so does not go out)
        state = try state.apply(.play(cards: [.regular(.five, .clubs)], by: p2.id))
        #expect(state.phase == .playing, "Round must continue — p3 still needs to play")

        // Step 4: p3 plays 6♣ (last card, beats 5♣) → p3 is 2nd finisher (rich);
        // p2 is the last non-bankrupt untitled player → poor; defender → beggar → round ends
        state = try state.apply(.play(cards: [.regular(.six, .clubs)], by: p3.id))
        #expect(state.phase == .roundEnded)

        let finalWinner = state.players.first { $0.id == winner.id }!
        let finalP3 = state.players.first { $0.id == p3.id }!
        let finalP2 = state.players.first { $0.id == p2.id }!
        let finalDefender = state.players.first { $0.id == defender.id }!

        #expect(finalWinner.currentTitle == .millionaire)
        #expect(finalP3.currentTitle == .rich)
        #expect(finalP2.currentTitle == .poor)
        #expect(finalDefender.currentTitle == .beggar, "Bankrupt defending Millionaire must end as Beggar")
        #expect(state.allCards.count == totalCards, "Card count must be conserved (bankrupt hand included)")
    }

    // MARK: Rule does not apply with fewer than 4 players

    @Test("3-player game: bankruptcy rule never fires even when enabled")
    func threePlayerBankruptcyDoesNotApply() throws {
        let defender = Player(displayName: "Defender", hand: [.regular(.five, .clubs), .regular(.king, .clubs)])
        let winner = Player(displayName: "Winner", hand: [.regular(.two, .hearts)])
        let p2 = Player(displayName: "P2", hand: [.regular(.six, .clubs)])

        let scores = Dictionary(uniqueKeysWithValues: [defender, winner, p2].map { ($0.id, 0) })
        let state = GameState(
            players: [winner, defender, p2],
            deck: [],
            currentPlayerIndex: 0,
            phase: .playing,
            ruleSet: RuleSet(bankruptcy: true),
            round: 2,
            scoresByPlayer: scores,
            defendingMillionaireID: defender.id
        )

        let next = try state.apply(.play(cards: [.regular(.two, .hearts)], by: winner.id))

        let defenderFinal = next.players.first { $0.id == defender.id }!
        #expect(!defenderFinal.isBankrupt, "Bankruptcy must not fire with only 3 players")
    }

    // MARK: Regression scenario

    @Test("regression: 4-player round 2 bankruptcy triggers and round completes correctly")
    func regression_bankruptcyRound2FullCompletion() throws {
        // Round 1: play a full base game to get titles.
        let players = ["P0", "P1", "P2", "P3"].map { Player(displayName: $0) }
        let round1 = GameState.newGame(players: players, ruleSet: RuleSet(bankruptcy: true), seed: 1)

        let round1States = SimulatedPlaythrough.states(from: round1)
        guard let round1End = round1States.last, round1End.phase == .roundEnded else {
            Issue.record("Round 1 did not reach .roundEnded")
            return
        }
        #expect(round1End.players.allSatisfy { $0.currentTitle != nil }, "All players must have titles after round 1")

        guard let r1Millionaire = round1End.players.first(where: { $0.currentTitle == .millionaire }) else {
            Issue.record("No Millionaire after round 1")
            return
        }

        // Round 2 start: startNextRound must record the defending Millionaire.
        let round2 = round1End.startNextRound(seed: 7)
        #expect(round2.defendingMillionaireID == r1Millionaire.id,
                "startNextRound must record the defending Millionaire's ID")

        // Complete any pending trades then play round 2 until bankruptcy fires or round ends.
        var state = round2
        // Exhaust the trading phase using strongest/weakest card heuristic.
        while state.phase == .trading {
            let pending = requiredTrades(for: state)
            guard let trade = pending.first else { break }
            let giver = state.players.first { $0.id == trade.from }!
            let cards: [Card]
            if trade.mustGiveStrongest {
                cards = Array(giver.hand.sorted { $0.tradingStrengthForTest > $1.tradingStrengthForTest }.prefix(trade.cardCount))
            } else {
                cards = Array(giver.hand.prefix(trade.cardCount))
            }
            state = try state.apply(.trade(cards: cards, from: trade.from, to: trade.to))
        }

        // The defending Millionaire ID must survive through the trading phase.
        #expect(state.defendingMillionaireID == r1Millionaire.id,
                "defendingMillionaireID must be preserved after trading completes")

        // Play round 2 to completion.
        let round2States = SimulatedPlaythrough.states(from: state)
        guard let round2End = round2States.last, round2End.phase == .roundEnded else {
            Issue.record("Round 2 did not reach .roundEnded")
            return
        }

        // Every player must have a title.
        #expect(round2End.players.allSatisfy { $0.currentTitle != nil },
                "All players must have titles after round 2")

        // If the defending Millionaire was bankrupted, they must hold Beggar.
        let defenderR2 = round2End.players.first { $0.id == r1Millionaire.id }!
        if defenderR2.isBankrupt {
            #expect(defenderR2.currentTitle == .beggar,
                    "Bankrupt defending Millionaire must end the round as Beggar")
        }

        // Card conservation must hold across both rounds.
        let expectedCardCount = 52 + (state.ruleSet.jokerCount)
        #expect(round2End.allCards.count == expectedCardCount,
                "All cards must be accounted for at round 2 end")
    }
}

// MARK: - Test helper

extension Card {
    fileprivate var tradingStrengthForTest: Int {
        switch self {
        case .joker: return Int.max
        case .regular(let rank, _): return rank.rawValue
        }
    }
}
