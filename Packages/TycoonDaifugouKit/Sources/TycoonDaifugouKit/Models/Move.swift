/// A single action a player can take on their turn.
public enum Move: Sendable, Hashable {
    /// Play one or more cards from hand during the playing phase.
    case play(cards: [Card], by: PlayerID)
    /// Pass without playing cards.
    case pass(by: PlayerID)
    /// Trade cards during the trading phase (between rounds).
    case trade(cards: [Card], from: PlayerID, to: PlayerID)
}
