import Foundation

// MARK: - Title

/// The social ranking assigned to a player at the end of each round,
/// ordered from highest (millionaire) to lowest (beggar).
public enum Title: String, Sendable, Hashable, Codable, CaseIterable {
    case millionaire
    case rich
    case commoner
    case poor
    case beggar
}

// MARK: - PlayerError

public enum PlayerError: Error, Equatable {
    /// Thrown when `removing(_:)` is called with cards the player doesn't hold.
    case missingCards([Card])
}

// MARK: - Player

/// A value-type snapshot of a single player's state. All mutations return a
/// new `Player` — nothing changes in place, keeping `GameState` fully immutable.
public struct Player: Sendable, Hashable {
    public let id: PlayerID
    public let displayName: String
    public let hand: [Card]
    public let currentTitle: Title?
    /// The title this player carried into the current round (i.e. the title they
    /// earned at the end of the previous round). Persists through trading and play
    /// so the UI can show the player's rank even after `currentTitle` is cleared.
    public let previousTitle: Title?
    /// True when the Bankruptcy house rule has removed this player from active play.
    /// A bankrupt player keeps their cards but skips all turns until the round ends.
    public let isBankrupt: Bool

    public init(
        id: PlayerID = PlayerID(),
        displayName: String,
        hand: [Card] = [],
        currentTitle: Title? = nil,
        previousTitle: Title? = nil,
        isBankrupt: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.hand = hand
        self.currentTitle = currentTitle
        self.previousTitle = previousTitle
        self.isBankrupt = isBankrupt
    }

    /// Title to surface in the UI: the title assigned this round if one exists,
    /// otherwise the title carried over from the previous round.
    public var displayTitle: Title? { currentTitle ?? previousTitle }

    /// Returns a new `Player` whose hand contains the given cards appended.
    public func adding(_ cards: [Card]) -> Player {
        Player(
            id: id, displayName: displayName, hand: hand + cards,
            currentTitle: currentTitle, previousTitle: previousTitle, isBankrupt: isBankrupt
        )
    }

    /// Returns a new `Player` with `title` set, preserving all other fields.
    public func withTitle(_ title: Title) -> Player {
        Player(
            id: id, displayName: displayName, hand: hand,
            currentTitle: title, previousTitle: previousTitle, isBankrupt: isBankrupt
        )
    }

    /// Returns a new `Player` marked as bankrupt, preserving all other fields.
    public func withBankruptcy() -> Player {
        Player(
            id: id, displayName: displayName, hand: hand,
            currentTitle: currentTitle, previousTitle: previousTitle, isBankrupt: true
        )
    }

    /// Returns a new `Player` with the given cards removed from the hand.
    /// Throws `PlayerError.missingCards` listing every card that was absent.
    public func removing(_ cards: [Card]) throws -> Player {
        var remaining = hand
        var missing: [Card] = []

        for card in cards {
            if let index = remaining.firstIndex(of: card) {
                remaining.remove(at: index)
            } else {
                missing.append(card)
            }
        }

        if !missing.isEmpty {
            throw PlayerError.missingCards(missing)
        }

        return Player(
            id: id, displayName: displayName, hand: remaining,
            currentTitle: currentTitle, previousTitle: previousTitle, isBankrupt: isBankrupt
        )
    }
}
