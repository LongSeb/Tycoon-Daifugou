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

    public init(
        id: PlayerID = PlayerID(),
        displayName: String,
        hand: [Card] = [],
        currentTitle: Title? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.hand = hand
        self.currentTitle = currentTitle
    }

    /// Returns a new `Player` whose hand contains the given cards appended.
    public func adding(_ cards: [Card]) -> Player {
        Player(id: id, displayName: displayName, hand: hand + cards, currentTitle: currentTitle)
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

        return Player(id: id, displayName: displayName, hand: remaining, currentTitle: currentTitle)
    }
}
