import Foundation
import Observation
import TycoonDaifugouKit

enum AppRoute: Hashable {
    case game
    case results
    case settings
    case onlineLobby
    case multiplayerGame(lobbyId: String)
}

@Observable
@MainActor
final class NavigationCoordinator {
    var path: [AppRoute] = []
    private(set) var gameController: GameController?
    private(set) var lastResult: GameResultData?
    private(set) var currentRuleSet: RuleSet = .baseOnly
    var store: GameRecordStore?
    var syncManager: SyncManager?
    var achievementManager: AchievementManager?

    var showingQuitConfirm = false

    // MARK: - Multiplayer state

    private(set) var multiplayerService: MultiplayerService?
    private(set) var lobbyViewModel: LobbyViewModel?
    private(set) var multiplayerGameController: MultiplayerGameController?

    func startOnlinePlay(myUID: String?) {
        let service = multiplayerService ?? MultiplayerService()
        multiplayerService = service
        let displayName = store?.profile.username ?? "Player"
        let emoji = store?.profile.emoji ?? "😎"
        let title = store?.profile.equippedTitleID ?? "Commoner"
        let borderID = store?.profile.equippedBorderID
        lobbyViewModel = LobbyViewModel(service: service, myUID: myUID, displayName: displayName, emoji: emoji, title: title, borderID: borderID)
        path = [.onlineLobby]
    }

    func startMultiplayerGame(lobbyId: String, myUID: String) {
        guard let service = multiplayerService else { return }
        let controller = MultiplayerGameController(lobbyId: lobbyId, myUID: myUID, service: service)
        multiplayerGameController = controller
        path.append(.multiplayerGame(lobbyId: lobbyId))
    }

    func leaveMultiplayer() {
        multiplayerService?.stopAll()
        multiplayerGameController?.stopListening()
        lobbyViewModel = nil
        multiplayerGameController = nil
        path = []
    }

    /// Leave the current game or lobby but stay on the Play Online menu.
    func returnToOnlineMenu() {
        multiplayerService?.stopListeningToGame()
        multiplayerGameController?.stopListening()
        multiplayerGameController = nil
        lobbyViewModel?.cleanupLocally()  // resets phase to .idle
        path = [.onlineLobby]
    }

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

        let rosterSeed = UInt64.random(in: .min ... .max)
        let cpus = CPURoster.sample(count: resolvedOpponentCount, seed: rosterSeed)

        let human = Player(displayName: "You")
        let aiPlayers = cpus.map { Player(displayName: $0.name) }

        var emojiMap: [PlayerID: String] = [human.id: "😎"]
        for (player, profile) in zip(aiPlayers, cpus) {
            emojiMap[player.id] = profile.emoji
        }

        let resolvedDifficulty = AppSettings.loadDifficulty()
        let opponents = OpponentRoster.randomAssignments(
            playerIDs: aiPlayers.map { $0.id },
            difficulty: resolvedDifficulty,
            seed: UInt64.random(in: .min ... .max)
        )

        gameController = GameController(
            players: [human] + aiPlayers,
            ruleSet: resolvedRuleSet,
            seed: UInt64.random(in: .min ... .max),
            humanPlayerID: human.id,
            opponents: opponents,
            playerEmojis: emojiMap,
            maxRounds: resolvedRounds,
            difficulty: resolvedDifficulty
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
        let winsCountBefore = store?.profile.gamesWonCount ?? 0
        var result = Self.buildResult(from: controller, profile: store?.profile)
        if let saved = store?.save(controller: controller, result: result, ruleSet: currentRuleSet) {
            syncManager?.didSaveGameLocally(saved)
        }
        result.levelUpUnlocks = store?.pendingLevelUpUnlocks
        checkEndGameAchievements(controller: controller, result: result, winsCountBefore: winsCountBefore)
        lastResult = result
        path.append(.results)
    }

    private func checkEndGameAchievements(
        controller: GameController,
        result: GameResultData,
        winsCountBefore: Int
    ) {
        guard let am = achievementManager else { return }
        let winsAfter = store?.profile.gamesWonCount ?? 0
        let humanWon = winsAfter > winsCountBefore

        if winsAfter == 1 { am.unlock(id: "first_win") }
        if winsAfter >= 20 { am.unlock(id: "veteran") }

        if humanWon {
            let isSweep = controller.humanMillionaireRounds >= 3 && controller.maxRounds == 3
            if isSweep { am.unlock(id: "tycoon_dynasty") }
            if controller.humanEnteredRoundAsBeggar { am.unlock(id: "rags_to_riches") }
            if controller.totalPassesCount == 0 { am.unlock(id: "no_hesitation") }
        }
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

        let players: [ResultPlayer] = standings.map { entry in
            let isHuman = entry.player.id == humanID
            let emoji: String
            if isHuman {
                emoji = profile?.emoji ?? "😎"
            } else {
                emoji = controller.emoji(for: entry.player.id)
            }
            return ResultPlayer(
                name: isHuman ? "You" : entry.player.displayName,
                emoji: emoji,
                rank: entry.player.currentTitle?.displayName ?? "—",
                xpGained: entry.xp,
                totalScore: controller.cumulativePoints[entry.player.id] ?? 0,
                isPlayer: isHuman
            )
        }

        // XP is now determined by cumulative round-points bracket + bonus events.
        let isSweep = controller.humanMillionaireRounds >= controller.maxRounds
            && controller.maxRounds == 3
        let isFirstGameOfDay: Bool = {
            guard let last = profile?.lastDailyBonusDate else { return true }
            return Date().timeIntervalSince(last) >= 25 * 3600
        }()
        let xpResult = XPRewardCalculator.compute(
            cumulativePoints: controller.humanCumulativePoints,
            revolutionsTriggered: controller.revolutionCount,
            counterRevolutionsTriggered: controller.counterRevolutionCount,
            jokersPlayed: controller.jokerPlayCount,
            wasThreeRoundSweep: isSweep,
            wasShutOut: controller.wasShutOut,
            comebackRounds: controller.comebackRoundsCount,
            isFirstGameOfDay: isFirstGameOfDay
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

        let baseLabel = "\(controller.humanCumulativePoints) pts"
        var breakdown: [XPBreakdownItem] = [XPBreakdownItem(label: baseLabel, amount: xpResult.baseXP)]
        breakdown.append(contentsOf: xpResult.bonuses.map { XPBreakdownItem(label: $0.label, amount: $0.amount) })

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
            xpBreakdown: breakdown,
            roundPointsTotal: controller.humanRoundPointsTotal,
            earnedDailyBonus: isFirstGameOfDay
        )
    }
}
