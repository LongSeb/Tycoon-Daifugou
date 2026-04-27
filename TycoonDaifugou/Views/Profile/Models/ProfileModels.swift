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
    // Equip state
    let equippedTitle: String
    let equippedSkinID: String
    let equippedBorder: ProfileBorder?
    let hasPrestigeBadge: Bool
    let isExtendedStatsUnlocked: Bool
    // Available unlock lists for pickers
    let unlockedTitles: [String]
    let lockedTitles: [String]
    let unlockedSkins: [CardSkin]
    let lockedSkins: [CardSkin]
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
