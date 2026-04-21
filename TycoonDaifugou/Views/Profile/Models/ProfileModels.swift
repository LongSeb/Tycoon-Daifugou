import SwiftUI

struct ProfileData {
    let emoji: String
    let username: String
    let memberSince: String
    let wins: Int
    let gamesPlayed: Int
    let winRate: Int
    let currentLevel: Int
    let currentXP: Int
    let xpForNextLevel: Int
    let levelStartXP: Int
    let winStreak: Int
    let totalRevolutions: Int
    let avgGameTime: String
    let nextUnlock: UnlockItem
    let upcomingUnlocks: [UnlockItem]
    let rankStats: [RankStat]
    let specialPlays: [SpecialPlayStat]
}

struct UnlockItem: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let level: Int
    let icon: UnlockIcon
}

enum UnlockIcon {
    case star, lock, chart, badge
}

struct RankStat: Identifiable {
    let id = UUID()
    let rank: String
    let count: Int
    let fraction: CGFloat
    let color: Color
}

struct SpecialPlayStat: Identifiable {
    let id = UUID()
    let name: String
    let subtitle: String
    let count: Int
    let badge: RuleBadge
}
