import SwiftUI
import TycoonDaifugouKit

extension GameController {
    /// Builds a 4-player game (1 human + 3 GreedyOpponents) for previews/fresh matches.
    static func newMatch(seed: UInt64) -> GameController {
        let human = Player(displayName: "You")
        let ryo = Player(displayName: "Ryo")
        let kai = Player(displayName: "Kai")
        let hana = Player(displayName: "Hana")

        let opponents = OpponentRoster.randomAssignments(
            playerIDs: [ryo.id, kai.id, hana.id],
            difficulty: .medium,
            seed: seed
        )

        let playerEmojis: [PlayerID: String] = [
            human.id: "😎",
            ryo.id: "🐯",
            kai.id: "🦊",
            hana.id: "🌸",
        ]

        return GameController(
            players: [human, ryo, kai, hana],
            ruleSet: .allRules,
            seed: seed,
            humanPlayerID: human.id,
            opponents: opponents,
            playerEmojis: playerEmojis
        )
    }
}

#Preview("Game — New Match") {
    GameView(controller: .newMatch(seed: 42), onExitRequest: {}, onGameEnded: { _ in })
}
