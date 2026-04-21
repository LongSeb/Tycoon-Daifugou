import SwiftUI

extension ProfileData {
    static let preview = ProfileData(
        emoji: "😎",
        username: "daifugō_king",
        memberSince: "March 2025",
        wins: 47,
        gamesPlayed: 128,
        winRate: 37,
        currentLevel: 12,
        currentXP: 1750,
        xpForNextLevel: 2000,
        levelStartXP: 1500,
        winStreak: 8,
        totalRevolutions: 23,
        avgGameTime: "6m 14s",
        nextUnlock: UnlockItem(
            name: "Custom avatar frame",
            description: "Golden ring — Millionaire edition",
            level: 13,
            icon: .star
        ),
        upcomingUnlocks: [
            UnlockItem(name: "Card back skin",  description: "Dark Lavender · exclusive pattern", level: 14, icon: .lock),
            UnlockItem(name: "Extended stats",  description: "Session history + trends",          level: 15, icon: .chart),
            UnlockItem(name: "Prestige badge",  description: "Cream star · profile display",      level: 16, icon: .badge),
        ],
        rankStats: [
            RankStat(rank: "Millionaire", count: 47, fraction: 0.37, color: .cardBlush),
            RankStat(rank: "Rich",        count: 31, fraction: 0.24, color: .cardLavender),
            RankStat(rank: "Poor",        count: 29, fraction: 0.23, color: .white.opacity(0.25)),
            RankStat(rank: "Beggar",      count: 21, fraction: 0.16, color: .white.opacity(0.15)),
        ],
        specialPlays: [
            SpecialPlayStat(name: "Revolutions",         subtitle: "Four-of-a-kind plays",      count: 23, badge: .star),
            SpecialPlayStat(name: "Reverse revolutions", subtitle: "Revolution counter-plays",  count: 7,  badge: .arrows),
            SpecialPlayStat(name: "Jokers played",       subtitle: "Wild card uses",            count: 31, badge: .joker),
            SpecialPlayStat(name: "3-Spade reversals",   subtitle: "Joker beats",               count: 4,  badge: .threeSpade),
            SpecialPlayStat(name: "8-stops",             subtitle: "Round-ending eights",       count: 18, badge: .eight),
        ]
    )
}

#Preview {
    ProfileView(profile: .preview)
}
