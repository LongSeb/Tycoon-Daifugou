import Foundation
import Observation
import TycoonDaifugouKit

enum AppRoute: Hashable {
    case game
    case results
    case settings
}

@Observable
@MainActor
final class NavigationCoordinator {
    var path: [AppRoute] = []
    private(set) var gameController: GameController?
    private(set) var lastResult: GameResultData?
    private(set) var currentRuleSet: RuleSet = .baseOnly
    var store: GameRecordStore?

    var showingQuitConfirm = false

    private static let opponentEmojis = ["🎩", "😏", "😤", "🦊", "🐻", "🦁", "🐼"]
    private static let opponentNames = ["Ryo", "Kai", "Hana", "Sora", "Yuki", "Rin", "Mei"]

    /// Starts a new game using the provided rule set and player/round counts.
    /// If `ruleSet` is nil, loads the persisted settings (see AppSettings).
    func startNewGame(
        ruleSet: RuleSet? = nil,
        opponentCount: Int? = nil,
        roundsPerGame: Int? = nil
    ) {
        let resolvedRuleSet = ruleSet ?? AppSettings.loadRuleSet()
        let resolvedOpponentCount = max(
            AppSettings.minOpponentCount,
            min(AppSettings.maxOpponentCount, opponentCount ?? AppSettings.loadOpponentCount())
        )
        let resolvedRounds = max(1, min(5, roundsPerGame ?? AppSettings.loadRoundsPerGame()))

        currentRuleSet = resolvedRuleSet

        let human = Player(displayName: "You")
        let aiPlayers = Self.opponentNames
            .prefix(resolvedOpponentCount)
            .map { Player(displayName: $0) }

        var opponents: [PlayerID: any Opponent] = [:]
        for ai in aiPlayers {
            opponents[ai.id] = GreedyOpponent()
        }

        gameController = GameController(
            players: [human] + aiPlayers,
            ruleSet: resolvedRuleSet,
            seed: UInt64.random(in: .min ... .max),
            humanPlayerID: human.id,
            opponents: opponents,
            maxRounds: resolvedRounds
        )
        lastResult = nil
        path = [.game]
    }

    func showSettings() {
        path.append(.settings)
    }

    func popSettings() {
        if path.last == .settings {
            path.removeLast()
        }
    }

    func showResults(for controller: GameController) {
        let result = Self.buildResult(from: controller, profile: store?.profile)
        lastResult = result
        store?.save(controller: controller, result: result, ruleSet: currentRuleSet)
        path.append(.results)
    }

    func returnToHome() {
        gameController = nil
        lastResult = nil
        path = []
    }

    // MARK: - Result mapping

    private static func buildResult(from controller: GameController, profile: PlayerProfile?) -> GameResultData {
        let state = controller.state
        let humanID = controller.humanPlayerID
        let standings = controller.finalStandings
        let humanTitle = controller.humanPlayer?.currentTitle

        var oppIndex = 0
        let players: [ResultPlayer] = standings.map { entry in
            let isHuman = entry.player.id == humanID
            let emoji: String
            if isHuman {
                emoji = profile?.emoji ?? "😎"
            } else {
                emoji = opponentEmojis[oppIndex % opponentEmojis.count]
                oppIndex += 1
            }
            return ResultPlayer(
                name: isHuman ? "You" : entry.player.displayName,
                emoji: emoji,
                rank: entry.player.currentTitle?.displayName ?? "—",
                xpGained: entry.xp,
                isPlayer: isHuman
            )
        }

        // XP is now determined by cumulative round-points bracket + bonus events.
        let isSweep = controller.humanMillionaireRounds >= controller.maxRounds
            && controller.maxRounds == 3
        let xpResult = XPRewardCalculator.compute(
            cumulativePoints: controller.humanCumulativePoints,
            revolutionsTriggered: controller.revolutionCount,
            counterRevolutionsTriggered: controller.counterRevolutionCount,
            jokersPlayed: controller.jokerPlayCount,
            wasThreeRoundSweep: isSweep,
            wasShutOut: controller.wasShutOut,
            comebackRounds: controller.comebackRoundsCount
        )
        let humanXP = xpResult.totalXP

        let xpBefore = profile?.totalXP ?? 0
        let xpAfter = xpBefore + humanXP
        let level = LevelCalculator.level(forTotalXP: xpAfter)
        let levelStart = LevelCalculator.cumulativeXP(forLevel: level)
        let xpForNext = level < LevelCalculator.maxLevel
            ? LevelCalculator.cumulativeXP(forLevel: level + 1)
            : xpAfter  // at cap: "to go" = 0

        let highlight: String
        if !controller.gameHighlight.isEmpty {
            highlight = controller.gameHighlight
        } else if let title = humanTitle {
            highlight = "\(state.round)-round match · \(title.displayName) finish"
        } else {
            highlight = "\(state.round)-round match complete"
        }

        let breakdown = xpResult.bonuses.map { bonus in
            XPBreakdownItem(label: bonus.label, amount: bonus.amount)
        }

        return GameResultData(
            roundsPlayed: state.round,
            playerFinishRank: humanTitle?.displayName ?? "—",
            highlight: highlight,
            players: players,
            xpGained: humanXP,
            xpBefore: xpBefore,
            xpAfter: xpAfter,
            levelStartXP: levelStart,
            xpForNextLevel: xpForNext,
            currentLevel: level,
            xpBreakdown: breakdown
        )
    }
}
