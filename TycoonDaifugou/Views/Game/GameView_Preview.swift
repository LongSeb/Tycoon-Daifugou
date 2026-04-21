import SwiftUI
import TycoonDaifugouKit

extension GameController {
    /// Builds a 4-player game (1 human + 3 GreedyOpponents) for previews/fresh matches.
    static func newMatch(seed: UInt64) -> GameController {
        let human = Player(displayName: "You")
        let ryo = Player(displayName: "Ryo")
        let kai = Player(displayName: "Kai")
        let hana = Player(displayName: "Hana")

        let opponents: [PlayerID: any Opponent] = [
            ryo.id: GreedyOpponent(),
            kai.id: GreedyOpponent(),
            hana.id: GreedyOpponent(),
        ]

        return GameController(
            players: [human, ryo, kai, hana],
            ruleSet: .allRules,
            seed: seed,
            humanPlayerID: human.id,
            opponents: opponents
        )
    }
}

#Preview("Game — New Match") {
    GameView(controller: .newMatch(seed: 42))
}
