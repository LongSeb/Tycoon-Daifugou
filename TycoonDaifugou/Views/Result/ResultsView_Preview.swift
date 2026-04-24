import SwiftUI

#Preview {
    ResultsView(result: .sample)
}

extension GameResultData {
    static let sample = GameResultData(
        roundsPlayed: 3,
        playerFinishRank: "Millionaire",
        highlight: "Revolution in Round 2 · 3-round sweep",
        players: [
            ResultPlayer(name: "You",  emoji: "😎", rank: "Millionaire", xpGained: 300, isPlayer: true),
            ResultPlayer(name: "Kai",  emoji: "😏", rank: "Rich",        xpGained: 200, isPlayer: false),
            ResultPlayer(name: "Ryo",  emoji: "🎩", rank: "Poor",        xpGained: 75,  isPlayer: false),
            ResultPlayer(name: "Hana", emoji: "😤", rank: "Beggar",      xpGained: 25,  isPlayer: false),
        ],
        xpGained: 300,
        xpBefore: 1450,
        xpAfter: 1750,
        levelStartXP: 1200,
        xpForNextLevel: 2000,
        currentLevel: 12,
        xpBreakdown: [
            XPBreakdownItem(label: "Millionaire finish", amount: 200),
            XPBreakdownItem(label: "Revolution",         amount: 60),
            XPBreakdownItem(label: "3-round sweep",      amount: 40),
        ],
        roundPointsTotal: 80
    )
}
