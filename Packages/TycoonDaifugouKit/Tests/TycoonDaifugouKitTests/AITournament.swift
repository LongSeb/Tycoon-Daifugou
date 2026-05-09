import Testing
import Foundation
@testable import TycoonDaifugouKit

// MARK: - AITournament
//
// Calibration harness. Pits configured opponent lineups against each other
// across many seeded games, reports per-seat Millionaire rate, and is the
// data source for tuning τ values, weight presets, and the Expert lookahead.
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

// MARK: - Reference baselines

/// Picks a uniformly random legal move. Models a true "no-skill" baseline —
/// useful as a calibration ref for the spec line "Easy ≈ no edge over
/// random play". Seedable for reproducibility.
final class RandomOpponent: Opponent, @unchecked Sendable {
    private var rng: Xoshiro256StarStar

    init(seed: UInt64) { self.rng = Xoshiro256StarStar(seed: seed) }

    func move(for playerID: PlayerID, in state: GameState) -> Move {
        let moves = state.validMoves(for: playerID).sorted { lhs, rhs in
            String(describing: lhs) < String(describing: rhs)
        }
        if moves.isEmpty { return .pass(by: playerID) }
        let idx = Int(rng.next() % UInt64(moves.count))
        return moves[idx]
    }
}

// MARK: - Match Runner

enum TournamentBot {
    case configured(policy: Policy, difficulty: Difficulty)
    case random
}

struct TournamentEntrant {
    let label: String
    let bot: TournamentBot

    init(label: String, policy: Policy, difficulty: Difficulty) {
        self.label = label
        self.bot = .configured(policy: policy, difficulty: difficulty)
    }

    init(label: String, randomBaseline: Bool) {
        precondition(randomBaseline)
        self.label = label
        self.bot = .random
    }
}

struct TournamentResult {
    let entrants: [TournamentEntrant]
    /// Number of times each seat finished as Millionaire.
    let millionaireWinsBySeat: [Int]
    /// Sum of finish positions (1 = millionaire, playerCount = beggar) per seat.
    /// Used to compute mean rank — a richer skill signal than Millionaire-rate
    /// in 4-player Tycoon, where deal-luck caps single-round Millionaire rate
    /// near ~45% even for a perfect heuristic.
    let finishRankSumBySeat: [Int]
    let games: Int
    let playerCount: Int

    var winRatesBySeat: [Double] {
        millionaireWinsBySeat.map { Double($0) / Double(games) }
    }
    /// Mean finish rank per seat. Range: 1.0 (always Millionaire) to
    /// playerCount (always Beggar). Random play averages near `(n+1)/2`.
    var meanRankBySeat: [Double] {
        finishRankSumBySeat.map { Double($0) / Double(games) }
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
    var rankSum = Array(repeating: 0, count: entrants.count)

    for gameIndex in 0..<gameCount {
        let seed = baseSeed &+ UInt64(gameIndex) &* 0x9E37_79B9_7F4A_7C15
        let players = entrants.indices.map { Player(displayName: entrants[$0].label) }
        let bots = entrants.enumerated().map { (index, entrant) -> any Opponent in
            let botSeed = seed &+ UInt64(index) &* 17
            switch entrant.bot {
            case .configured(let policy, let difficulty):
                return OpponentRoster.opponent(
                    policy: policy, difficulty: difficulty, seed: botSeed
                )
            case .random:
                return RandomOpponent(seed: botSeed)
            }
        }

        var state = GameState.newGame(players: players, ruleSet: ruleSet, seed: seed)

        // Play one round to round-end.
        playOutRound(state: &state, bots: bots, players: players)

        if let winnerIndex = state.players.firstIndex(where: { $0.currentTitle == .millionaire }) {
            wins[winnerIndex] += 1
        }
        for (seat, player) in state.players.enumerated() {
            rankSum[seat] += finishRank(of: player, playerCount: entrants.count)
        }
    }

    return TournamentResult(
        entrants: entrants,
        millionaireWinsBySeat: wins,
        finishRankSumBySeat: rankSum,
        games: gameCount,
        playerCount: entrants.count
    )
}

/// 1-indexed finish rank from the player's `currentTitle`. Beggar = lowest.
/// An unfinished player (defensive — shouldn't happen given safetyCap) is
/// treated as last place.
private func finishRank(of player: Player, playerCount: Int) -> Int {
    guard let title = player.currentTitle else { return playerCount }
    switch title {
    case .millionaire: return 1
    case .rich:        return 2
    case .commoner:    return 3
    case .poor:        return playerCount - 1
    case .beggar:      return playerCount
    }
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

    @Test("Snapshot — Greedy vs Aggressive vs ComboKeeper vs Balanced (Medium)")
    func snapshotMediumDifficulty() {
        let entrants: [TournamentEntrant] = [
            TournamentEntrant(label: "Greedy",      policy: .greedy,      difficulty: .medium),
            TournamentEntrant(label: "Aggressive",  policy: .aggressive,  difficulty: .medium),
            TournamentEntrant(label: "ComboKeeper", policy: .comboKeeper, difficulty: .medium),
            TournamentEntrant(label: "Balanced",    policy: .balanced,    difficulty: .medium),
        ]
        let result = runTournament(entrants: entrants, gameCount: 1_000)
        printReport(result)
    }

    @Test("Snapshot — v2 personalities vs Balanced (Medium)")
    func snapshotV2Personalities() {
        let entrants: [TournamentEntrant] = [
            TournamentEntrant(label: "Counter",       policy: .counter,       difficulty: .medium),
            TournamentEntrant(label: "EndgameRusher", policy: .endgameRusher, difficulty: .medium),
            TournamentEntrant(label: "Balanced",      policy: .balanced,      difficulty: .medium),
            TournamentEntrant(label: "Balanced",      policy: .balanced,      difficulty: .medium),
        ]
        let result = runTournament(entrants: entrants, gameCount: 1_000)
        printReport(result)
    }

    @Test("Calibration — Difficulty curve (1 subject vs 3 Easy-Balanced refs)")
    func difficultyCurve() {
        for difficulty in Difficulty.allCases {
            let entrants: [TournamentEntrant] = [
                TournamentEntrant(
                    label: "Subject-\(difficulty)",
                    policy: .balanced,
                    difficulty: difficulty
                ),
                TournamentEntrant(label: "Ref-Balanced-Easy", policy: .balanced, difficulty: .easy),
                TournamentEntrant(label: "Ref-Balanced-Easy", policy: .balanced, difficulty: .easy),
                TournamentEntrant(label: "Ref-Balanced-Easy", policy: .balanced, difficulty: .easy),
            ]
            let result = runTournament(entrants: entrants, gameCount: 1_000)
            printReport(result)
        }
    }

    @Test("Calibration — Difficulty curve vs 3 random-move refs (no-skill baseline)")
    func difficultyCurveVsRandom() {
        for difficulty in Difficulty.allCases {
            let entrants: [TournamentEntrant] = [
                TournamentEntrant(
                    label: "Subject-\(difficulty)",
                    policy: .balanced,
                    difficulty: difficulty
                ),
                TournamentEntrant(label: "Ref-Random", randomBaseline: true),
                TournamentEntrant(label: "Ref-Random", randomBaseline: true),
                TournamentEntrant(label: "Ref-Random", randomBaseline: true),
            ]
            let result = runTournament(entrants: entrants, gameCount: 1_000)
            printReport(result)
        }
    }

    @Test("Calibration — Difficulty curve vs 3 Easy-Greedy refs (passive heuristic)")
    func difficultyCurveVsEasyGreedy() {
        for difficulty in Difficulty.allCases {
            let entrants: [TournamentEntrant] = [
                TournamentEntrant(
                    label: "Subject-\(difficulty)",
                    policy: .balanced,
                    difficulty: difficulty
                ),
                TournamentEntrant(label: "Ref-Greedy-Easy", policy: .greedy, difficulty: .easy),
                TournamentEntrant(label: "Ref-Greedy-Easy", policy: .greedy, difficulty: .easy),
                TournamentEntrant(label: "Ref-Greedy-Easy", policy: .greedy, difficulty: .easy),
            ]
            let result = runTournament(entrants: entrants, gameCount: 1_000)
            printReport(result)
        }
    }

    @Test("Snapshot — Expert lookahead vs three Hard refs")
    func expertVsHard() {
        let entrants: [TournamentEntrant] = [
            TournamentEntrant(label: "Expert-Balanced", policy: .balanced, difficulty: .expert),
            TournamentEntrant(label: "Hard-Balanced",   policy: .balanced, difficulty: .hard),
            TournamentEntrant(label: "Hard-Balanced",   policy: .balanced, difficulty: .hard),
            TournamentEntrant(label: "Hard-Balanced",   policy: .balanced, difficulty: .hard),
        ]
        let result = runTournament(entrants: entrants, gameCount: 500)
        printReport(result)
    }
}

// MARK: - Reporting

private func printReport(_ result: TournamentResult) {
    print("--- Tournament Report (\(result.games) games, \(result.playerCount) seats) ---")
    let randomBaseline = Double(result.playerCount + 1) / 2.0
    for (index, entrant) in result.entrants.enumerated() {
        let rate = result.winRatesBySeat[index]
        let pct = String(format: "%.1f%%", rate * 100)
        let meanRank = result.meanRankBySeat[index]
        let rankStr = String(format: "%.2f", meanRank)
        let descriptor: String
        switch entrant.bot {
        case .configured(let policy, let difficulty):
            descriptor = "\(policy.id.rawValue) / \(difficulty.rawValue)"
        case .random:
            descriptor = "random"
        }
        print("  Seat \(index) [\(entrant.label) / \(descriptor)]: " +
              "\(pct) Mil · mean rank \(rankStr) (random≈\(String(format: "%.2f", randomBaseline)))")
    }
}
