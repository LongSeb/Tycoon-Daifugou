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
        round: 1,
        scoresByPlayer: scores,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

// MARK: - Tests

@Suite("Policy.score")
struct PolicyScoreTests {

    @Test("All v1 policies expose distinct weight vectors")
    func policiesAreDistinct() {
        let weights = Set(Policy.allV1.map { $0.weights })
        #expect(weights.count == Policy.allV1.count)
    }

    @Test("Greedy strongly prefers cheap singles over expensive ones")
    func greedyPrefersCheapSingles() {
        let player = makePlayer("P", cards: [
            .regular(.three, .clubs), .regular(.two, .spades),
        ])
        let state = makeState(players: [player])

        let cheap = Move.play(cards: [.regular(.three, .clubs)], by: player.id)
        let expensive = Move.play(cards: [.regular(.two, .spades)], by: player.id)

        let cheapScore = Policy.greedy.score(cheap, in: state, hand: player.hand)
        let expensiveScore = Policy.greedy.score(expensive, in: state, hand: player.hand)

        #expect(cheapScore > expensiveScore)
    }

    @Test("ComboKeeper scores playing the whole pair higher than splitting it")
    func comboKeeperPrefersWholeGroup() {
        let cards: [Card] = [
            .regular(.five, .clubs), .regular(.five, .diamonds), .regular(.king, .hearts),
        ]
        let player = makePlayer("P", cards: cards)
        let state = makeState(players: [player])

        let split = Move.play(cards: [.regular(.five, .clubs)], by: player.id)
        let whole = Move.play(
            cards: [.regular(.five, .clubs), .regular(.five, .diamonds)], by: player.id
        )

        let splitScore = Policy.comboKeeper.score(split, in: state, hand: player.hand)
        let wholeScore = Policy.comboKeeper.score(whole, in: state, hand: player.hand)

        #expect(wholeScore > splitScore)
    }

    @Test("Aggressive prefers playing the larger combo on lead")
    func aggressivePrefersBiggerCombo() {
        let cards: [Card] = [
            .regular(.five, .clubs), .regular(.five, .diamonds), .regular(.king, .hearts),
        ]
        let player = makePlayer("P", cards: cards)
        let state = makeState(players: [player])

        let single = Move.play(cards: [.regular(.king, .hearts)], by: player.id)
        let pair = Move.play(
            cards: [.regular(.five, .clubs), .regular(.five, .diamonds)], by: player.id
        )

        let singleScore = Policy.aggressive.score(single, in: state, hand: player.hand)
        let pairScore = Policy.aggressive.score(pair, in: state, hand: player.hand)

        #expect(pairScore > singleScore)
    }

    @Test("PassBias adds only on .pass moves")
    func passBiasAppliesOnlyToPass() throws {
        let trick = try Hand(cards: [.regular(.five, .clubs)])
        let player = makePlayer("P", cards: [.regular(.king, .hearts)])
        let state = makeState(
            players: [player],
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        let weightsZero = FeatureWeights(
            cardsCleared: 0, winLikelihood: 0, comboIntegrity: 0,
            cardValueSpent: 0, passBias: 5.0
        )
        let policy = Policy(id: .greedy, weights: weightsZero)

        let passScore = policy.score(.pass(by: player.id), in: state, hand: player.hand)
        let playScore = policy.score(
            .play(cards: [.regular(.king, .hearts)], by: player.id),
            in: state, hand: player.hand
        )

        #expect(passScore == 5.0)
        #expect(playScore == 0.0)
    }
}
