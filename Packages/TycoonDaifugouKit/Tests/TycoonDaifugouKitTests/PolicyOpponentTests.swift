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

@Suite("PolicyOpponent")
struct PolicyOpponentTests {

    @Test("At τ=0, picks the argmax move (deterministic)")
    func zeroTemperatureIsDeterministic() {
        let player = makePlayer("P", cards: [
            .regular(.three, .clubs), .regular(.two, .spades),
        ])
        let state = makeState(players: [player])

        let bot = PolicyOpponent(policy: .greedy, temperature: 0, seed: 1)
        let move = bot.move(for: player.id, in: state)

        // Greedy weights make the 3 strictly cheaper than the 2 — argmax is the 3.
        #expect(move == .play(cards: [.regular(.three, .clubs)], by: player.id))
    }

    @Test("Same seed produces the same move sequence")
    func seededReproducibility() {
        let player = makePlayer("P", cards: [
            .regular(.three, .clubs), .regular(.four, .diamonds), .regular(.king, .hearts),
        ])
        let state = makeState(players: [player])

        let firstBot = PolicyOpponent(policy: .balanced, temperature: 1.0, seed: 42)
        let secondBot = PolicyOpponent(policy: .balanced, temperature: 1.0, seed: 42)

        let firstSequence = (0..<10).map { _ in firstBot.move(for: player.id, in: state) }
        let secondSequence = (0..<10).map { _ in secondBot.move(for: player.id, in: state) }

        #expect(firstSequence == secondSequence)
    }

    @Test("Returns only legal moves (sampling never escapes validMoves)")
    func sampledMoveIsAlwaysLegal() throws {
        let trick = try Hand(cards: [.regular(.five, .clubs)])
        let player = makePlayer("P", cards: [
            .regular(.three, .clubs), .regular(.king, .hearts), .regular(.two, .spades),
        ])
        let state = makeState(
            players: [player],
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        let validMoves = Set(state.validMoves(for: player.id))

        for seed in (1...20).map(UInt64.init) {
            let bot = PolicyOpponent(policy: .balanced, temperature: 1.0, seed: seed)
            let move = bot.move(for: player.id, in: state)
            #expect(validMoves.contains(move))
        }
    }

    @Test("Pass is the only legal move when no card can beat the trick")
    func passWhenNoBeaters() throws {
        let trick = try Hand(cards: [.regular(.two, .diamonds)])
        let player = makePlayer("P", cards: [.regular(.five, .clubs)])
        let state = makeState(
            players: [player],
            currentTrick: [trick],
            lastPlayedByIndex: 0
        )

        let bot = PolicyOpponent(policy: .aggressive, temperature: 1.0, seed: 1)
        let move = bot.move(for: player.id, in: state)

        #expect(move == .pass(by: player.id))
    }

    @Test("High temperature spreads choices across more options than τ=0")
    func highTemperatureIncreasesVariance() {
        let player = makePlayer("P", cards: [
            .regular(.four, .clubs), .regular(.five, .diamonds),
            .regular(.six, .hearts), .regular(.seven, .spades),
        ])
        let state = makeState(players: [player])

        var argmaxCounts: [Move: Int] = [:]
        var sampleCounts: [Move: Int] = [:]

        for seed in (1...50).map(UInt64.init) {
            let argmaxBot = PolicyOpponent(policy: .balanced, temperature: 0, seed: seed)
            let sampleBot = PolicyOpponent(policy: .balanced, temperature: 2.0, seed: seed)
            argmaxCounts[argmaxBot.move(for: player.id, in: state), default: 0] += 1
            sampleCounts[sampleBot.move(for: player.id, in: state), default: 0] += 1
        }

        // Argmax always picks one move; high-τ samples cover at least 2.
        #expect(argmaxCounts.count == 1)
        #expect(sampleCounts.count >= 2)
    }
}
