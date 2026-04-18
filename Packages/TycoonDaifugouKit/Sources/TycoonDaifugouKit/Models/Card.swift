import Foundation

// MARK: - Suit

/// The four French-deck suits. In base Tycoon, suit rarely matters — the one
/// notable exception is the 3 of Spades in the House Rule "3-Spade Reversal",
/// where it can beat a single Joker. Suit is stored regardless so rules can
/// pattern-match on it when needed.
public enum Suit: String, CaseIterable, Sendable, Hashable {
    case clubs
    case diamonds
    case hearts
    case spades
}

// MARK: - Rank

/// The rank of a card in Tycoon. Unlike Western convention, in Tycoon the
/// weakest card is 3 and the strongest non-Joker card is 2 (Ace is second-
/// strongest). We encode strength via the raw integer value so we can compare
/// directly without a lookup table.
///
/// A Revolution does not change these raw values — it changes how the engine
/// compares them. Rules logic reads the raw value and inverts comparison
/// when `GameState.isRevolutionActive` is true.
public enum Rank: Int, CaseIterable, Sendable, Hashable, Comparable {
    case three = 3
    case four  = 4
    case five  = 5
    case six   = 6
    case seven = 7
    case eight = 8
    case nine  = 9
    case ten   = 10
    case jack  = 11
    case queen = 12
    case king  = 13
    case ace   = 14
    case two   = 15

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Card

/// A single playing card. A card is either a regular rank+suit pair, or a
/// Joker (indexed 0 or 1 — we allow up to 2 Jokers per deck per the rules doc,
/// though by default a deck ships with 0).
///
/// `Equatable` + `Hashable` come for free from the automatic synthesis.
public enum Card: Sendable, Hashable {
    case regular(Rank, Suit)
    case joker(index: Int)

    /// The rank of this card if it's a regular card, or `nil` if it's a Joker.
    /// Jokers take on whatever rank they're used as at play time, so the
    /// intrinsic rank is meaningless.
    public var rank: Rank? {
        switch self {
        case .regular(let rank, _): return rank
        case .joker: return nil
        }
    }

    /// The suit of this card, or `nil` for a Joker.
    public var suit: Suit? {
        switch self {
        case .regular(_, let suit): return suit
        case .joker: return nil
        }
    }

    /// True if this card is a Joker.
    public var isJoker: Bool {
        if case .joker = self { return true }
        return false
    }
}

// MARK: - Deck

public enum Deck {
    /// Returns a fresh, unshuffled 52-card deck with no Jokers.
    /// Callers that want Jokers or shuffling should do that themselves —
    /// we keep this deterministic.
    public static func standard52() -> [Card] {
        var cards: [Card] = []
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                cards.append(.regular(rank, suit))
            }
        }
        return cards
    }

    /// Returns a 52 + `jokers`-card deck. `jokers` must be 0...2.
    public static func deck(withJokers jokers: Int) -> [Card] {
        precondition((0...2).contains(jokers), "Deck supports 0, 1, or 2 Jokers")
        var cards = standard52()
        for i in 0..<jokers {
            cards.append(.joker(index: i))
        }
        return cards
    }
}
