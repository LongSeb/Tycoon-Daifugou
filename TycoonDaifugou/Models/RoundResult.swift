import Foundation
import TycoonDaifugouKit

struct RoundResult {
    let roundNumber: Int
    let playerResults: [PlayerRoundResult]
}

struct PlayerRoundResult {
    let playerID: PlayerID
    let name: String
    let emoji: String
    let isHuman: Bool
    let title: Title
    let pointsEarned: Int
    let cumulativePoints: Int
}
