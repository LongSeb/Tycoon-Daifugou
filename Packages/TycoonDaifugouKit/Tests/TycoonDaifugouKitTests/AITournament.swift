import Testing
import Foundation
@testable import TycoonDaifugouKit

// MARK: - AITournament
//
// Calibration harness. Pits configured opponent lineups against each other
// across many seeded games, reports per-seat Millionaire rate, and is the
// data source for tuning τ values and personality weights.
//
// All tests in this suite are tagged `.aiTournament` and gated behind the
// `RUN_AI_TOURNAMENT` environment variable so they don't slow CI. Run with:
//
//   RUN_AI_TOURNAMENT=1 swift test --package-path Packages/TycoonDaifugouKit \
//     --filter AITournament

extension Tag {
    @Tag static var aiTournament: Self
}

private let tournamentEnabled = ProcessInfo.processInfo.environment["RUN_AI_TOURNAMENT"] == "1"

// MARK: - Match Runner

struct TournamentEntrant {
    let label: String
    let policy: Policy
    let temperature: Double
}

struct TournamentResult {
    let entrants: [TournamentEntrant]
    /// Number of times each seat finished as Millionaire.
    let millionaireWinsBySeat: [Int]
    let games: Int

    var winRatesBySeat: [Double] {
        millionaireWinsBySeat.map { Double($0) / Double(games) }
    }
}

/// Runs `gameCount` 4-player games using the supplied entrants in seat order
/// and reports millionaire-rate per seat. Uses `.allRules` to match the
/// app's default match config — calibration should reflect real play.
func runTournament(
    entrants: [TournamentEntrant],
    gameCount: Int,
    baseSeed: UInt64 = 0xC0FFEE,
    ruleSet: RuleSet = .allRules
) -> TournamentResult {
    precondition(entrants.count >= 3 && entrants.count <= 8, "3–8 players supported")
    var wins = Array(repeating: 0, count: entrants.count)

    for gameIndex in 0..<gameCount {
        let seed = baseSeed &+ UInt64(gameIndex) &* 0x9E37_79B9_7F4A_7C15
        let players = entrants.indices.map { Player(displayName: entrants[$0].label) }
        let bots = entrants.enumerated().map { (index, entrant) -> any Opponent in
            PolicyOpponent(
                policy: entrant.policy,
                temperature: entrant.temperature,
                seed: seed &+ UInt64(index) &* 17
            )
        }

        var state = GameState.newGame(players: players, ruleSet: ruleSet, seed: seed)

        // Play one round to round-end.
        playOutRound(state: &state, bots: bots, players: players)

        if let winnerIndex = state.players.firstIndex(where: { $0.currentTitle == .millionaire }) {
            wins[winnerIndex] += 1
        }
    }

    return TournamentResult(entrants: entrants, millionaireWinsBySeat: wins, games: gameCount)
}

private func playOutRound(
    state: inout GameState,
    bots: [any Opponent],
    players: [Player],
    safetyCap: Int = 1_000
) {
    for _ in 0..<safetyCap {
        if state.phase != .playing { return }
        let activeIndex = state.currentPlayerIndex
        let move = bots[activeIndex].move(for: players[activeIndex].id, in: state)
        guard let next = try? state.apply(move) else { return }
        state = next
    }
}

// MARK: - Tests

@Suite("AITournament", .tags(.aiTournament), .disabled(if: !tournamentEnabled))
struct AITournamentTests {

    @Test("Snapshot — Greedy vs Aggressive vs ComboKeeper vs Balanced (τ=Medium)")
    func snapshotMediumDifficulty() {
        let entrants: [TournamentEntrant] = [
            TournamentEntrant(label: "Greedy",      policy: .greedy,      temperature: Difficulty.medium.temperature),
            TournamentEntrant(label: "Aggressive",  policy: .aggressive,  temperature: Difficulty.medium.temperature),
            TournamentEntrant(label: "ComboKeeper", policy: .comboKeeper, temperature: Difficulty.medium.temperature),
            TournamentEntrant(label: "Balanced",    policy: .balanced,    temperature: Difficulty.medium.temperature),
        ]
        let result = runTournament(entrants: entrants, gameCount: 1_000)
        printReport(result)
    }

    @Test("Calibration — Difficulty curve (1 difficulty bot vs 3 Easy-Balanced refs)")
    func difficultyCurve() {
        for difficulty in Difficulty.allCases {
            let entrants: [TournamentEntrant] = [
                TournamentEntrant(
                    label: "Subject-\(difficulty)",
                    policy: .balanced,
                    temperature: difficulty.temperature
                ),
                TournamentEntrant(label: "Ref-Balanced-Easy", policy: .balanced, temperature: Difficulty.easy.temperature),
                TournamentEntrant(label: "Ref-Balanced-Easy", policy: .balanced, temperature: Difficulty.easy.temperature),
                TournamentEntrant(label: "Ref-Balanced-Easy", policy: .balanced, temperature: Difficulty.easy.temperature),
            ]
            let result = runTournament(entrants: entrants, gameCount: 1_000)
            printReport(result)
        }
    }
}

// MARK: - Reporting

private func printReport(_ result: TournamentResult) {
    print("--- Tournament Report (\(result.games) games) ---")
    for (index, entrant) in result.entrants.enumerated() {
        let rate = result.winRatesBySeat[index]
        let pct = String(format: "%.1f%%", rate * 100)
        let policyLabel = entrant.policy.id.rawValue
        let tau = String(format: "%.2f", entrant.temperature)
        print("  Seat \(index) [\(entrant.label) / \(policyLabel) / τ=\(tau)]: \(pct) Millionaire")
    }
}
