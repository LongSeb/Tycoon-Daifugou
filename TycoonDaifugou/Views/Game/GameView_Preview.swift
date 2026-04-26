import SwiftUI
import TycoonDaifugouKit

extension GameController {
    /// Builds a 4-player game (1 human + 3 random-personality CPUs at Medium) for previews/fresh matches.
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

    #if DEBUG
    /// Scenario: revolution is active, the seat next to the human just played
    /// a solo Joker, and the human holds the 3 of Spades. The reversal play
    /// should appear as a legal move in the human's hand UI.
    static func threeSpadeReversalUnderRevolutionScenario() -> GameController {
        let human = Player(displayName: "You", hand: [
            .regular(.three, .spades),
            .regular(.king, .hearts),
            .regular(.seven, .clubs),
            .regular(.nine, .diamonds),
            .regular(.queen, .diamonds),
        ])
        let ryo = Player(displayName: "Ryo", hand: [
            .regular(.five, .clubs),
            .regular(.eight, .hearts),
            .regular(.jack, .spades),
        ])
        let kai = Player(displayName: "Kai", hand: [
            .regular(.four, .diamonds),
            .regular(.six, .hearts),
            .regular(.ten, .spades),
        ])
        let hana = Player(displayName: "Hana", hand: [
            .regular(.jack, .clubs),
            .regular(.two, .hearts),
            .regular(.ace, .diamonds),
        ])

        let players = [human, ryo, kai, hana]
        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
        let jokerHand = (try? Hand(cards: [.joker(index: 0)])) ?? (try! Hand(cards: [.regular(.three, .clubs)]))

        let scenarioState = GameState(
            players: players,
            deck: [],
            currentTrick: [jokerHand],
            currentPlayerIndex: 0,            // human's turn to respond
            phase: .playing,
            ruleSet: RuleSet(
                revolution: true,
                eightStop: true,
                jokers: true,
                threeSpadeReversal: true,
                bankruptcy: false,
                jokerCount: 1
            ),
            isRevolutionActive: true,
            round: 1,
            scoresByPlayer: scores,
            lastPlayedByIndex: 1              // Ryo just dropped the Joker
        )

        let opponents: [PlayerID: any Opponent] = [
            ryo.id:  PolicyOpponent(policy: .balanced, temperature: 0.3, seed: 1),
            kai.id:  PolicyOpponent(policy: .balanced, temperature: 0.3, seed: 2),
            hana.id: PolicyOpponent(policy: .balanced, temperature: 0.3, seed: 3),
        ]

        let emojis: [PlayerID: String] = [
            human.id: "😎",
            ryo.id:   "🐯",
            kai.id:   "🦊",
            hana.id:  "🌸",
        ]

        return GameController(
            scenarioState: scenarioState,
            humanPlayerID: human.id,
            opponents: opponents,
            playerEmojis: emojis
        )
    }
    #endif
}

#Preview("Game — New Match") {
    GameView(controller: .newMatch(seed: 42), onExitRequest: {}, onGameEnded: { _ in })
}

#if DEBUG
#Preview("Scenario — 3♠ Reversal under Revolution") {
    GameView(
        controller: .threeSpadeReversalUnderRevolutionScenario(),
        onExitRequest: {},
        onGameEnded: { _ in }
    )
}
#endif
