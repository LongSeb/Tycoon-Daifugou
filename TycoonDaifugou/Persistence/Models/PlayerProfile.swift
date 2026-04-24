import Foundation
import SwiftData

@Model
final class PlayerProfile {
    var username: String
    var emoji: String
    var totalXP: Int
    var currentLevel: Int
    var memberSince: Date

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
}
