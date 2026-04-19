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
    /// True when this hand is exactly one Joker card played solo as a single.
    public let isSoloJoker: Bool

    public init(cards: [Card]) throws {
        guard let handType = HandType(rawValue: cards.count) else {
            throw HandError.wrongCount(cards.count)
        }
        let nonJokers = cards.filter { !$0.isJoker }
        if nonJokers.isEmpty {
            // Only a lone single Joker is valid; two Jokers together are not.
            guard cards.count == 1 else { throw HandError.allJokers }
            self.cards = cards
            self.type = handType
            self.rank = .two  // Placeholder; solo Joker comparisons bypass rank.
            self.isSoloJoker = true
            return
        }
        let ranks = Set(nonJokers.compactMap { $0.rank })
        guard ranks.count == 1, let anchorRank = ranks.first else {
            throw HandError.mixedRanks
        }
        self.cards = cards
        self.type = handType
        self.rank = anchorRank
        self.isSoloJoker = false
    }
}

extension Hand: Comparable {
    public static func < (lhs: Hand, rhs: Hand) -> Bool {
        if rhs.isSoloJoker { return !lhs.isSoloJoker }
        if lhs.isSoloJoker { return false }
        return lhs.rank < rhs.rank
    }
}
