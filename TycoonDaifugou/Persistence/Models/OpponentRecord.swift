import Foundation
import SwiftData

@Model
final class OpponentRecord {
    var name: String
    var emoji: String
    var finishRank: String
    var xpEarned: Int

    init(name: String, emoji: String, finishRank: String, xpEarned: Int) {
        self.name = name
        self.emoji = emoji
        self.finishRank = finishRank
        self.xpEarned = xpEarned
    }
}
