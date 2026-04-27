import Foundation
import SwiftData
import SwiftUI

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

    // MARK: - Computed unlocks (derived from UnlockRegistry, never persisted)

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
}
