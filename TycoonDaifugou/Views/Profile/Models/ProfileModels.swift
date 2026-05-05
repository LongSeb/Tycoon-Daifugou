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
    let avgFinishPlace: String
    let totalTimePlayed: String
    let nextUnlock: UnlockItem
    let upcomingUnlocks: [UnlockItem]
    let rankStats: [RankStat]
    let specialPlays: [SpecialPlayStat]
    // Equip state
    let equippedTitle: String
    let equippedSkinID: String
    let equippedBorder: ProfileBorder?
    let unlockedBorders: [ProfileBorder]
    let hasPrestigeBadge: Bool
    let prestigeLevel: Int
    let prestigeXP: Int
    let canPrestige: Bool     // eligible for prestige right now (XP capped, below max prestige)
    let isAtMaxLevel: Bool   // true when currentLevel == 50, regardless of prestige state
    let isExtendedStatsUnlocked: Bool
    let extendedStats: ExtendedStatsData?
    // Available unlock lists for pickers
    let unlockedTitles: [String]
    let lockedTitles: [String]
    let unlockedSkins: [CardSkin]
    let lockedSkins: [CardSkin]
}

struct ExtendedStatsData {
    let totalGamesPlayed: Int
    // Derived rates (0.0 – 1.0)
    let passRate: Double
    let earlyFinisherRate: Double
    let comebackRate: Double
    let sweepRate: Double
    let cardHoardingIndex: Double
    let trickWinRate: Double
    let jokerEfficiency: Double
    // Revolution average (per game)
    let avgRevolutionsPerGame: Double
    // Radar axes (0.0 – 1.0)
    let aggressionAxis: Double
    let earlyAxis: Double
    let riskAxis: Double
    let consistencyAxis: Double
    let calculatedAxis: Double
    let dominantAxis: Double
    // Archetype
    let archetype: PlayingStyleArchetype
    let archetypeEmoji: String
    let archetypeDescription: String
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
