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
    /// True when this hand is exactly two Jokers played together as a pair trump.
    public let isDoubleJoker: Bool

    public init(cards: [Card]) throws {
        guard let handType = HandType(rawValue: cards.count) else {
            throw HandError.wrongCount(cards.count)
        }
        let nonJokers = cards.filter { !$0.isJoker }
        if nonJokers.isEmpty {
            // Solo Joker (single) and double Joker (pair) are both legal trump plays.
            switch cards.count {
            case 1:
                self.cards = cards
                self.type = handType
                self.rank = .two  // Placeholder; solo Joker comparisons bypass rank.
                self.isSoloJoker = true
                self.isDoubleJoker = false
                return
            case 2:
                self.cards = cards
                self.type = handType
                self.rank = .two  // Placeholder; double Joker comparisons bypass rank.
                self.isSoloJoker = false
                self.isDoubleJoker = true
                return
            default:
                throw HandError.allJokers
            }
        }
        let ranks = Set(nonJokers.compactMap { $0.rank })
        guard ranks.count == 1, let anchorRank = ranks.first else {
            throw HandError.mixedRanks
        }
        self.cards = cards
        self.type = handType
        self.rank = anchorRank
        self.isSoloJoker = false
        self.isDoubleJoker = false
    }
}

extension Hand: Comparable {
    public static func < (lhs: Hand, rhs: Hand) -> Bool {
        if rhs.isDoubleJoker { return !lhs.isDoubleJoker }
        if lhs.isDoubleJoker { return false }
        if rhs.isSoloJoker { return !lhs.isSoloJoker }
        if lhs.isSoloJoker { return false }
        return lhs.rank < rhs.rank
    }
}
