import SwiftUI

#Preview {
    ResultsView(result: .sample)
}

extension GameResultData {
    static let sample = GameResultData(
        roundsPlayed: 3,
        playerFinishRank: "Tycoon",
        highlight: "Revolution in Round 2 · 3-round sweep",
        players: [
            ResultPlayer(name: "You",  emoji: "😎", rank: "Tycoon", xpGained: 300, totalScore: 90, isPlayer: true),
            ResultPlayer(name: "Kai",  emoji: "😏", rank: "Rich",        xpGained: 200, totalScore: 60, isPlayer: false),
            ResultPlayer(name: "Ryo",  emoji: "🎩", rank: "Poor",        xpGained: 75,  totalScore: 30, isPlayer: false),
            ResultPlayer(name: "Hana", emoji: "😤", rank: "Beggar",      xpGained: 25,  totalScore: 0,  isPlayer: false),
        ],
        xpGained: 185,
        xpBefore: 1450,
        xpAfter: 1635,
        levelStartXP: 1200,
        xpForNextLevel: 2000,
        currentLevel: 12,
        xpBreakdown: [
            XPBreakdownItem(label: "90 pts", amount: 100),
            XPBreakdownItem(label: "Revolution",         amount: 30),
            XPBreakdownItem(label: "3-round sweep",      amount: 35),
            XPBreakdownItem(label: "Joker played",       amount: 10),
            XPBreakdownItem(label: "Shut-out finish",    amount: 10),
        ],
        roundPointsTotal: 80
    )
}
