import SwiftUI
import TycoonDaifugouKit

// MARK: - Sample data

private extension RoundResult {
    /// Round 2 of 3 — mid-game, "Start Round 3" CTA.
    static let round2of3 = RoundResult(
        roundNumber: 2,
        playerResults: [
            PlayerRoundResult(
                playerID: PlayerID(), name: "You",   emoji: "😎", isHuman: true,
                title: .millionaire, pointsEarned: 30, cumulativePoints: 50
            ),
            PlayerRoundResult(
                playerID: PlayerID(), name: "Ryo",   emoji: "🎩", isHuman: false,
                title: .rich,        pointsEarned: 20, cumulativePoints: 40
            ),
            PlayerRoundResult(
                playerID: PlayerID(), name: "Kai",   emoji: "😏", isHuman: false,
                title: .poor,        pointsEarned: 10, cumulativePoints: 30
            ),
            PlayerRoundResult(
                playerID: PlayerID(), name: "Hana",  emoji: "😤", isHuman: false,
                title: .beggar,      pointsEarned: 0,  cumulativePoints: 10
            ),
        ]
    )

    /// Round 3 of 3 — final round, "See Final Results" CTA.
    static let round3of3 = RoundResult(
        roundNumber: 3,
        playerResults: [
            PlayerRoundResult(
                playerID: PlayerID(), name: "Ryo",   emoji: "🎩", isHuman: false,
                title: .millionaire, pointsEarned: 30, cumulativePoints: 70
            ),
            PlayerRoundResult(
                playerID: PlayerID(), name: "You",   emoji: "😎", isHuman: true,
                title: .rich,        pointsEarned: 20, cumulativePoints: 70
            ),
            PlayerRoundResult(
                playerID: PlayerID(), name: "Hana",  emoji: "😤", isHuman: false,
                title: .poor,        pointsEarned: 10, cumulativePoints: 40
            ),
            PlayerRoundResult(
                playerID: PlayerID(), name: "Kai",   emoji: "😏", isHuman: false,
                title: .beggar,      pointsEarned: 0,  cumulativePoints: 30
            ),
        ]
    )
}

// MARK: - Previews

#Preview("Mid-game — Round 2 of 3") {
    InterRoundResultsView(
        result: .round2of3,
        isLastRound: false,
        onContinue: {},
        onShowFinalResults: {}
    )
}

#Preview("Final round — Round 3 of 3") {
    InterRoundResultsView(
        result: .round3of3,
        isLastRound: true,
        onContinue: {},
        onShowFinalResults: {}
    )
}
