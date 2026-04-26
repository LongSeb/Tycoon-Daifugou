import Testing
@testable import TycoonDaifugouKit

// MARK: - GreedyParityTests
//
// Validates that the new framework faithfully reproduces the legacy
// `GreedyOpponent` behavior on a large corpus of real game states.
//
// Methodology:
//   - Deal 4-player games across many seeds and walk forward via
//     `validMoves`-driven simulation, snapshotting every state where it's
//     player 0's turn.
//   - For each snapshot state, ask both `GreedyOpponent()` and
//     `PolicyOpponent(.greedy, τ=0)` for a move.
//   - Allow agreement on (a) the exact same move, OR (b) a tied-score move
//     under the greedy policy. The legacy bot has its own tie-breaking
//     (sort order in `validMoves`), so equal-score divergence is fine.
//
// Failure cases are pinpointed with the seed + move number.

private func collectCorpus(
    seeds: [UInt64],
    movesPerGame: Int = 80
) -> [(seed: UInt64, step: Int, state: GameState, playerID: PlayerID)] {
    var corpus: [(UInt64, Int, GameState, PlayerID)] = []
    for seed in seeds {
        let players = (0..<4).map { Player(displayName: "P\($0)") }
        var state = GameState.newGame(players: players, ruleSet: .baseOnly, seed: seed)
        for step in 0..<movesPerGame {
            guard state.phase == .playing else { break }
            let active = state.players[state.currentPlayerIndex]
            if active.id == players[0].id {
                corpus.append((seed, step, state, active.id))
            }
            let candidates = state.validMoves(for: active.id)
            guard let next = candidates.first.flatMap({ try? state.apply($0) }) else { break }
            state = next
        }
    }
    return corpus
}

@Suite("GreedyParity")
struct GreedyParityTests {

    @Test("PolicyOpponent(.greedy, τ=0) matches GreedyOpponent on a 80+ state corpus")
    func parityAcrossCorpus() {
        let seeds = (1...8).map { UInt64($0) &* 1_000_003 }
        let corpus = collectCorpus(seeds: seeds)
        #expect(corpus.count >= 80, "corpus too small: \(corpus.count)")

        let legacy = GreedyOpponent()
        var disagreements: [(UInt64, Int)] = []

        for entry in corpus {
            let policy = PolicyOpponent(policy: .greedy, temperature: 0, seed: 1)
            let legacyMove = legacy.move(for: entry.playerID, in: entry.state)
            let policyMove = policy.move(for: entry.playerID, in: entry.state)
            if legacyMove == policyMove { continue }

            // Tie-breaking divergence is acceptable as long as the policy's
            // chosen move scores at least as high as the legacy's choice.
            let policyScore = Policy.greedy.score(
                policyMove,
                in: entry.state,
                hand: entry.state.players.first(where: { $0.id == entry.playerID })?.hand ?? []
            )
            let legacyScore = Policy.greedy.score(
                legacyMove,
                in: entry.state,
                hand: entry.state.players.first(where: { $0.id == entry.playerID })?.hand ?? []
            )
            if abs(policyScore - legacyScore) > 1e-9 {
                disagreements.append((entry.seed, entry.step))
            }
        }

        #expect(
            disagreements.isEmpty,
            "Score disagreements at: \(disagreements.prefix(5))"
        )
    }
}
