// MARK: - EightStop

enum EightStop {

    /// Returns `true` when playing `hand` should trigger an 8-Stop:
    /// the current trick resets immediately and the player who played leads next.
    ///
    /// Requires `ruleEnabled` to be `true` and the hand's rank to be `.eight`.
    /// The hand must have already passed the normal strength check — this method
    /// only determines whether the 8-Stop *effect* fires, not whether the play
    /// is legal.
    static func triggers(hand: Hand, ruleEnabled: Bool) -> Bool {
        ruleEnabled && hand.rank == .eight
    }
}
