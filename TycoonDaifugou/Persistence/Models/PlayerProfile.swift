import Foundation
import SwiftData
import SwiftUI

enum PlayingStyleArchetype: String {
    case tycoon    = "The Tycoon"
    case gambler   = "The Gambler"
    case hoarder   = "The Hoarder"
    case wildcard  = "The Wildcard"
}

@Model
final class PlayerProfile {
    var username: String
    var emoji: String
    var totalXP: Int
    var currentLevel: Int
    var memberSince: Date

    // Equip state — persisted, always derived-safe to default
    var equippedTitleID: String = "Commoner"
    var equippedSkinID: String = "default"
    var equippedBorderID: String? = nil
    var hasPrestigeBadge: Bool = false
    var hardModeWins: Int = 0

    // MARK: - Extended Stats Tracking Counters (all default to 0)

    var jokersPlayed: Int = 0
    var jokersWonTrick: Int = 0
    var roundFinishPositions: [Int] = []   // 1=Tycoon, 2=Rich, 3=Poor, 4=Beggar
    var comebackCount: Int = 0             // rounds recovered from Poor/Beggar to Rich/Tycoon
    var comebackOpportunities: Int = 0     // rounds started as Poor or Beggar
    var sweepsAchieved: Int = 0            // games where human won all rounds
    var multiRoundGamesPlayed: Int = 0     // games with > 1 round
    var tricksLed: Int = 0                 // times human played on empty pile
    var tricksWon: Int = 0                 // trick resets where human was the leader who won
    var totalPasses: Int = 0
    var totalTurns: Int = 0
    var revolutionsTriggered: Int = 0
    var eightStopsTotal: Int = 0
    var threeSpadesTotal: Int = 0
    var gamesPlayedCount: Int = 0
    var gamesWonCount: Int = 0
    var totalDuration: TimeInterval = 0.0
    var totalRoundsPlayed: Int = 0

    init(
        username: String = "Player",
        emoji: String = "😎",
        totalXP: Int = 0,
        currentLevel: Int = 1,
        memberSince: Date = Date()
    ) {
        self.username = username
        self.emoji = emoji
        self.totalXP = totalXP
        self.currentLevel = currentLevel
        self.memberSince = memberSince
    }

    // MARK: - Computed Unlocks (derived from UnlockRegistry, never persisted)

    var unlockedTitles: [String] {
        UnlockRegistry.unlocks(upToLevel: currentLevel).compactMap {
            if case .title(let t) = $0.type { return t } else { return nil }
        }
    }

    var unlockedSkins: [CardSkin] {
        let defaultSkin = CardSkin(id: "default", name: "Cream", color: .cardCream, isFoil: false)
        let earned = UnlockRegistry.unlocks(upToLevel: currentLevel).compactMap {
            if case .cardSkin(let s) = $0.type { return s } else { return nil }
        }
        return [defaultSkin] + earned
    }

    var unlockedBorders: [ProfileBorder] {
        UnlockRegistry.unlocks(upToLevel: currentLevel).compactMap {
            if case .profileBorder(let b) = $0.type { return b } else { return nil }
        }
    }

    var isExtendedStatsUnlocked: Bool { currentLevel >= 5 }
    var isExpertDifficultyUnlocked: Bool { currentLevel >= 20 && hardModeWins >= 10 }

    var equippedBorder: ProfileBorder? {
        guard let id = equippedBorderID else { return nil }
        return unlockedBorders.first { $0.id == id }
    }

    var equippedSkin: CardSkin {
        unlockedSkins.first { $0.id == equippedSkinID }
            ?? CardSkin(id: "default", name: "Cream", color: .cardCream, isFoil: false)
    }

    // MARK: - Derived Stats (always computed fresh from tracked counters)

    var winRate: Double {
        guard gamesPlayedCount > 0 else { return 0 }
        return Double(gamesWonCount) / Double(gamesPlayedCount)
    }

    var avgTimePerRound: TimeInterval {
        guard totalRoundsPlayed > 0 else { return 0 }
        return totalDuration / Double(totalRoundsPlayed)
    }

    var passRate: Double {
        guard totalTurns > 0 else { return 0 }
        return Double(totalPasses) / Double(totalTurns)
    }

    var earlyFinisherRate: Double {
        guard !roundFinishPositions.isEmpty else { return 0 }
        let earlyCount = roundFinishPositions.filter { $0 <= 2 }.count
        return Double(earlyCount) / Double(roundFinishPositions.count)
    }

    var comebackRate: Double {
        guard comebackOpportunities > 0 else { return 0 }
        return Double(comebackCount) / Double(comebackOpportunities)
    }

    var sweepRate: Double {
        guard multiRoundGamesPlayed > 0 else { return 0 }
        return Double(sweepsAchieved) / Double(multiRoundGamesPlayed)
    }

    var jokerEfficiency: Double {
        guard jokersPlayed > 0 else { return 0 }
        return Double(jokersWonTrick) / Double(jokersPlayed)
    }

    var trickWinRate: Double {
        guard tricksLed > 0 else { return 0 }
        return Double(tricksWon) / Double(tricksLed)
    }

    var avgRevolutionsPerGame: Double {
        guard gamesPlayedCount > 0 else { return 0 }
        return Double(revolutionsTriggered) / Double(gamesPlayedCount)
    }

    var cardHoardingIndex: Double {
        guard gamesPlayedCount > 0 else { return 0 }
        if totalRoundsPlayed < 5 {
            // Insufficient time data — proxy via eightStops frequency (more = aggressive shedding)
            let avgEights = Double(eightStopsTotal) / Double(gamesPlayedCount)
            return max(0, min(1, 1.0 - avgEights / 3.0))
        }
        let timeNorm = min(avgTimePerRound / 300.0, 1.0)  // 300s/round = max hoarding
        let lossNorm = 1.0 - winRate
        return (timeNorm + lossNorm) / 2.0
    }

    // MARK: - Playing Style Axes (0.0 – 1.0)

    var aggressionAxis: Double {
        max(0, min(1, 1.0 - passRate))
    }

    var earlyAxis: Double {
        earlyFinisherRate
    }

    var riskAxis: Double {
        let revNorm = min(avgRevolutionsPerGame / 3.0, 1.0)
        let jokerEff = jokerEfficiency
        let threeSpadeNorm: Double = gamesPlayedCount > 0
            ? min(Double(threeSpadesTotal) / Double(gamesPlayedCount) / 2.0, 1.0)
            : 0.0
        return (revNorm + jokerEff + threeSpadeNorm) / 3.0
    }

    var consistencyAxis: Double {
        guard roundFinishPositions.count >= 2 else { return 0.5 }
        let mean = Double(roundFinishPositions.reduce(0, +)) / Double(roundFinishPositions.count)
        let variance = roundFinishPositions
            .map { pow(Double($0) - mean, 2) }
            .reduce(0, +) / Double(roundFinishPositions.count)
        // Low variance = high consistency; max possible stddev for 1-4 range ≈ 1.5
        return max(0, min(1, 1.0 - sqrt(variance) / 1.5))
    }

    // MARK: - Playing Style Archetype

    var archetype: PlayingStyleArchetype {
        let a = aggressionAxis
        let e = earlyAxis
        let r = riskAxis
        let c = consistencyAxis
        // Nearest archetype by Euclidean distance in 4D axis space
        let profiles: [(PlayingStyleArchetype, Double, Double, Double, Double)] = [
            (.tycoon,   1.0, 1.0, 0.0, 1.0),
            (.gambler,  1.0, 1.0, 1.0, 0.0),
            (.hoarder,  0.0, 0.0, 0.0, 1.0),
            (.wildcard, 0.0, 0.0, 1.0, 0.0),
        ]
        return profiles.min { lhs, rhs in
            let d1 = pow(a - lhs.1, 2) + pow(e - lhs.2, 2) + pow(r - lhs.3, 2) + pow(c - lhs.4, 2)
            let d2 = pow(a - rhs.1, 2) + pow(e - rhs.2, 2) + pow(r - rhs.3, 2) + pow(c - rhs.4, 2)
            return d1 < d2
        }!.0
    }

    var archetypeEmoji: String {
        switch archetype {
        case .tycoon:   return "👑"
        case .gambler:  return "🎭"
        case .hoarder:  return "🐢"
        case .wildcard: return "⚡"
        }
    }

    var archetypeDescription: String {
        switch archetype {
        case .tycoon:
            return "Methodical and consistent. You play efficiently, shed cards early, and rarely take unnecessary risks."
        case .gambler:
            return "High energy and unpredictable. You play aggressively and love a revolution, but results can vary wildly."
        case .hoarder:
            return "Patient and calculated. You wait for the perfect moment, hold strong cards, and rarely show your hand."
        case .wildcard:
            return "Chaotic and hard to read. You hold back but strike with high-risk plays that keep opponents guessing."
        }
    }
}
