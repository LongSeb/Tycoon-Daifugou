import Foundation
import Observation
import TycoonDaifugouKit

enum AppRoute: Hashable {
    case game
    case results
}

@Observable
@MainActor
final class NavigationCoordinator {
    var path: [AppRoute] = []
    private(set) var gameController: GameController?
    private(set) var lastResult: GameResultData?
    private(set) var currentRuleSet: RuleSet = .baseOnly

    var showingQuitConfirm = false

    private static let opponentEmojis = ["🎩", "😏", "😤", "🦊"]

    func startNewGame(ruleSet: RuleSet = .baseOnly) {
        currentRuleSet = ruleSet

        let human = Player(displayName: "You")
        let ryo = Player(displayName: "Ryo")
        let kai = Player(displayName: "Kai")
        let hana = Player(displayName: "Hana")

        let opponents: [PlayerID: any Opponent] = [
            ryo.id: GreedyOpponent(),
            kai.id: GreedyOpponent(),
            hana.id: GreedyOpponent(),
        ]

        gameController = GameController(
            players: [human, ryo, kai, hana],
            ruleSet: ruleSet,
            seed: UInt64.random(in: .min ... .max),
            humanPlayerID: human.id,
            opponents: opponents
        )
        lastResult = nil
        path = [.game]
    }

    func showResults(for controller: GameController) {
        lastResult = Self.buildResult(from: controller)
        path.append(.results)
    }

    func returnToHome() {
        gameController = nil
        lastResult = nil
        path = []
    }

    // MARK: - Result mapping

    private static func buildResult(from controller: GameController) -> GameResultData {
        let state = controller.state
        let humanID = controller.humanPlayerID
        let standings = controller.finalStandings
        let humanTitle = controller.humanPlayer?.currentTitle

        var oppIndex = 0
        let players: [ResultPlayer] = standings.map { entry in
            let isHuman = entry.player.id == humanID
            let emoji: String
            if isHuman {
                emoji = "😎"
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

        let humanXP = state.scoresByPlayer[humanID] ?? 0
        let highlight: String
        if let title = humanTitle {
            highlight = "\(state.round)-round match · \(title.displayName) finish"
        } else {
            highlight = "\(state.round)-round match complete"
        }

        var breakdown: [XPBreakdownItem] = []
        if let title = humanTitle, humanXP > 0 {
            breakdown.append(XPBreakdownItem(label: "\(title.displayName) finish", amount: humanXP))
        }

        return GameResultData(
            roundsPlayed: state.round,
            playerFinishRank: humanTitle?.displayName ?? "—",
            highlight: highlight,
            players: players,
            xpGained: humanXP,
            xpBefore: 0,
            xpAfter: humanXP,
            levelStartXP: 0,
            xpForNextLevel: max(humanXP + 1, 10),
            currentLevel: 1,
            xpBreakdown: breakdown
        )
    }
}
