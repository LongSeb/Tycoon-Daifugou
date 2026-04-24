import Foundation
import SwiftData

@Model
final class GameRecord {
    var id: UUID
    var date: Date
    var finishRank: String
    var xpEarned: Int
    var roundsPlayed: Int
    var roundsWon: Int
    var cardsPlayed: Int
    var duration: TimeInterval
    var highlight: String
    var ruleSetUsed: Data
    var revolutionCount: Int
    var eightStopCount: Int
    var jokerPlayCount: Int
    var threeSpadeCount: Int
    var roundPointsTotal: Int = 0
    var opponentBestPoints: Int = 0
    @Relationship(deleteRule: .cascade) var opponents: [OpponentRecord]

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        finishRank: String,
        xpEarned: Int,
        roundsPlayed: Int,
        roundsWon: Int,
        cardsPlayed: Int,
        duration: TimeInterval,
        highlight: String,
        ruleSetUsed: Data,
        revolutionCount: Int,
        eightStopCount: Int,
        jokerPlayCount: Int,
        threeSpadeCount: Int,
        opponents: [OpponentRecord],
        roundPointsTotal: Int = 0,
        opponentBestPoints: Int = 0
    ) {
        self.id = id
        self.date = date
        self.finishRank = finishRank
        self.xpEarned = xpEarned
        self.roundsPlayed = roundsPlayed
        self.roundsWon = roundsWon
        self.cardsPlayed = cardsPlayed
        self.duration = duration
        self.highlight = highlight
        self.ruleSetUsed = ruleSetUsed
        self.revolutionCount = revolutionCount
        self.eightStopCount = eightStopCount
        self.jokerPlayCount = jokerPlayCount
        self.threeSpadeCount = threeSpadeCount
        self.opponents = opponents
        self.roundPointsTotal = roundPointsTotal
        self.opponentBestPoints = opponentBestPoints
    }
}
