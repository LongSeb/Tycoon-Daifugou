// MARK: - Revolution

enum Revolution {

    /// Whether `newRank` is stronger than `currentRank` given the current revolution state.
    static func isStronger(_ newRank: Rank, than currentRank: Rank, revolutionActive: Bool) -> Bool {
        revolutionActive ? newRank < currentRank : newRank > currentRank
    }

    /// Whether `newHand` is stronger than `currentHand` given the current revolution state.
    static func isStronger(_ newHand: Hand, than currentHand: Hand, revolutionActive: Bool) -> Bool {
        isStronger(newHand.rank, than: currentHand.rank, revolutionActive: revolutionActive)
    }

    /// Returns the revolution state after playing `hand` with `ruleEnabled`.
    /// Toggles if `hand` is a quad and the rule is on; otherwise returns `active` unchanged.
    static func newState(active: Bool, after hand: Hand, ruleEnabled: Bool) -> Bool {
        guard ruleEnabled, hand.type == .quad else { return active }
        return !active
    }
}
