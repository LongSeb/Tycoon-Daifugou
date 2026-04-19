import Foundation

public enum Move: Sendable, Hashable {
    case play(cards: [Card], by: PlayerID)
    case pass(by: PlayerID)
    /// Used in the trading phase only.
    case trade(cards: [Card], from: PlayerID, to: PlayerID)
}
