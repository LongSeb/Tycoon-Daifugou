import Foundation

struct ResultPlayer: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let rank: String
    let xpGained: Int
    let totalScore: Int
    let isPlayer: Bool
}

struct XPBreakdownItem: Identifiable {
    let id = UUID()
    let label: String
    let amount: Int
}

struct GameResultData {
    let roundsPlayed: Int
    let playerFinishRank: String
    let highlight: String
    let players: [ResultPlayer]
    let xpGained: Int
    let xpBefore: Int
    let xpAfter: Int
    let levelStartXP: Int
    let xpForNextLevel: Int
    let currentLevel: Int
    let xpBreakdown: [XPBreakdownItem]
    let roundPointsTotal: Int
}
