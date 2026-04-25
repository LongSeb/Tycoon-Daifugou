import Foundation
import TycoonDaifugouKit

struct CardExchangeState: Equatable {
    let humanLastRank: Title
    let opponentName: String
    let cardsToGive: [Card]          // pre-selected when !engineAllowsSelection; empty otherwise
    let cardsReceived: [Card]
    let requiredGiveCount: Int
    let engineAllowsSelection: Bool  // true when human is Millionaire/Rich (can choose cards)
}
