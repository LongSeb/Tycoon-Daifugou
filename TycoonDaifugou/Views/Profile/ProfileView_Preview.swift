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
        avgFinishPlace: "2.4",
        totalTimePlayed: "3h 12m",
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
            RankStat(rank: "Tycoon", count: 47, fraction: 0.37, color: .cardBlush),
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
        ],
        equippedTitle: "Card Shark",
        equippedSkinID: "royal_red",
        equippedBorder: ProfileBorder(id: "silver", name: "Silver", color: Color(hex: "#C0C0C0"), isAnimated: false),
        unlockedBorders: [
            ProfileBorder(id: "bronze", name: "Bronze", color: Color(hex: "#CD7F32"), isAnimated: false),
            ProfileBorder(id: "royal_red_border", name: "Royal Red", color: Color(hex: "#AC2317"), isAnimated: false),
            ProfileBorder(id: "silver", name: "Silver", color: Color(hex: "#C0C0C0"), isAnimated: false),
        ],
        hasPrestigeBadge: false,
        prestigeLevel: 0,
        prestigeXP: 0,
        canPrestige: false,
        isAtMaxLevel: false,
        isExtendedStatsUnlocked: true,
        extendedStats: ExtendedStatsData(
            totalGamesPlayed: 128,
            passRate: 0.22,
            earlyFinisherRate: 0.61,
            comebackRate: 0.30,
            sweepRate: 0.18,
            cardHoardingIndex: 0.27,
            trickWinRate: 0.69,
            jokerEfficiency: 0.58,
            avgRevolutionsPerGame: 1.1,
            aggressionAxis: 0.78,
            earlyAxis: 0.61,
            riskAxis: 0.22,
            consistencyAxis: 0.74,
            calculatedAxis: 0.68,
            dominantAxis: 0.52,
            archetype: .tycoon,
            archetypeEmoji: "👑",
            archetypeDescription: "Methodical and consistent. You play efficiently, rip cards early, and don't take risks."
        ),
        unlockedTitles: ["Commoner", "The Joker", "Flower Queen", "Card Shark"],
        lockedTitles: ["All The Primes", "Lady Amagi", "Kissing Kings", "Truth Seeker", "Kingpin of Steel", "The High Roller", "Chad", "Tycoon"],
        unlockedSkins: [
            CardSkin(id: "default", name: "Cream", color: .cardCream, isFoil: false),
            CardSkin(id: "royal_red", name: "Royal Red", color: Color(hex: "#AC2317"), isFoil: true),
        ],
        lockedSkins: [
            CardSkin(id: "vine_green", name: "Vine Green", color: Color(hex: "#D2DCB6"), isFoil: false),
            CardSkin(id: "wake_up_yellow", name: "Wake Up Yellow", color: Color(hex: "#FFF799"), isFoil: false),
            CardSkin(id: "pretty_pink", name: "Pretty Pink", color: Color(hex: "#FFD4E5"), isFoil: false),
            CardSkin(id: "repeat_blue", name: "Repeat Blue", color: Color(hex: "#99DAFF"), isFoil: false),
            CardSkin(id: "orange", name: "Orange", color: Color(hex: "#FFDCA9"), isFoil: false),
            CardSkin(id: "plum_purple", name: "Plum Purple", color: Color(hex: "#545B77"), isFoil: false),
            CardSkin(id: "shiny_black", name: "Shiny Black", color: Color(hex: "#171616"), isFoil: true),
        ]
    )
}

#Preview {
    ProfileView(profile: .preview)
        .environment(AuthService())
}
