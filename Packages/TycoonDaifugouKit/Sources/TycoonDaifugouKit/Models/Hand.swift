import Foundation

public enum HandError: Error, Sendable, Equatable {
    case wrongCount(Int)
    case mixedRanks
    case allJokers
}

public struct Hand: Sendable, Hashable {
    public let cards: [Card]
    public let type: HandType
    public let rank: Rank

    public init(cards: [Card]) throws {
        guard let handType = HandType(rawValue: cards.count) else {
            throw HandError.wrongCount(cards.count)
        }
        let nonJokers = cards.filter { !$0.isJoker }
        guard !nonJokers.isEmpty else {
            throw HandError.allJokers
        }
        let ranks = Set(nonJokers.compactMap { $0.rank })
        guard ranks.count == 1, let anchorRank = ranks.first else {
            throw HandError.mixedRanks
        }
        self.cards = cards
        self.type = handType
        self.rank = anchorRank
    }
}

extension Hand: Comparable {
    public static func < (lhs: Hand, rhs: Hand) -> Bool {
        lhs.rank < rhs.rank
    }
}
