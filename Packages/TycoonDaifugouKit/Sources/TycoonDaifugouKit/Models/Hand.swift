// MARK: - HandError

public enum HandError: Error, Equatable, Sendable {
    /// No cards provided.
    case empty
    /// Cards have different ranks and don't form a valid sequence.
    case mixedRanks
    /// Sequence ranks aren't consecutive.
    case nonConsecutiveRanks
    /// Sequence has fewer than 3 consecutive ranks.
    case sequenceTooShort
    /// Each rank in a sequence must have the same number of cards (≥ 2).
    case inconsistentGroupSize
}

// MARK: - HandType

/// The structural category of a played hand.
public enum HandType: Sendable, Hashable, Equatable {
    /// One card.
    case single
    /// Two or more cards of the same rank (e.g. pair = 2, triple = 3).
    case multi(count: Int)
    /// Three or more consecutive ranks, each represented by `perRank` cards
    /// (e.g. three consecutive pairs = .sequence(length: 3, perRank: 2)).
    case sequence(length: Int, perRank: Int)
}

// MARK: - Hand

/// A validated, classified set of cards representing a single play.
/// Jokers wildcard for the rank of the surrounding regular cards in
/// single and multi hands. Sequence-with-Joker support is reserved for
/// a future House Rules pass.
public struct Hand: Sendable, Hashable, Equatable {
    public let cards: [Card]
    public let type: HandType

    /// The rank used for strength comparisons. `nil` means a pure-Joker
    /// single, which beats every ranked hand.
    public let effectiveRank: Rank?

    public init(cards: [Card]) throws(HandError) {
        guard !cards.isEmpty else { throw .empty }

        let jokers = cards.filter { $0.isJoker }
        let regularRanks = cards.compactMap { $0.rank }

        if regularRanks.isEmpty {
            // Pure-Joker hand — only valid as a single
            guard cards.count == 1 else { throw .mixedRanks }
            self.cards = cards
            self.type = .single
            self.effectiveRank = nil
            return
        }

        let rankGroups = Dictionary(grouping: regularRanks, by: { $0 })
        let sortedUniqueRanks = rankGroups.keys.sorted()

        if sortedUniqueRanks.count == 1 {
            // All regular cards share a rank; Jokers fill in as that rank.
            let rank = sortedUniqueRanks[0]
            self.cards = cards
            self.type = cards.count == 1 ? .single : .multi(count: cards.count)
            self.effectiveRank = rank
        } else {
            // Multiple ranks — must form a sequence (no Joker gap-filling yet).
            guard jokers.isEmpty else { throw .nonConsecutiveRanks }

            for rankIndex in 1..<sortedUniqueRanks.count {
                guard sortedUniqueRanks[rankIndex].rawValue == sortedUniqueRanks[rankIndex - 1].rawValue + 1 else {
                    throw .nonConsecutiveRanks
                }
            }
            guard sortedUniqueRanks.count >= 3 else { throw .sequenceTooShort }

            let groupSizes = sortedUniqueRanks.map { rankGroups[$0]!.count }
            guard
                let perRank = groupSizes.first,
                perRank >= 2,
                groupSizes.allSatisfy({ $0 == perRank })
            else { throw .inconsistentGroupSize }

            self.cards = cards
            self.type = .sequence(length: sortedUniqueRanks.count, perRank: perRank)
            self.effectiveRank = sortedUniqueRanks.last
        }
    }

    /// Returns `true` if this hand is strictly stronger than `other`.
    /// The caller is responsible for ensuring the two hands share the same type.
    public func beats(_ other: Hand, revolutionActive: Bool = false) -> Bool {
        switch (effectiveRank, other.effectiveRank) {
        case (nil, nil): return false                // both pure-Joker, tied
        case (nil, _):   return true                 // Joker single beats ranked hands
        case (_, nil):   return false                // ranked hand loses to Joker single
        case let (mine?, theirs?):
            return revolutionActive ? mine < theirs : mine > theirs
        }
    }
}
