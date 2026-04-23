enum Joker {
    /// Returns true when `newHand` is a solo Joker and the Joker rule is enabled.
    /// A solo Joker beats any regular single regardless of revolution state.
    static func isSoloStronger(newHand: Hand, ruleEnabled: Bool) -> Bool {
        ruleEnabled && newHand.isSoloJoker
    }

    /// Returns true when `newHand` is a double-Joker pair and the Joker rule is enabled.
    /// A double Joker beats any regular pair regardless of revolution state.
    static func isDoublePairStronger(newHand: Hand, ruleEnabled: Bool) -> Bool {
        ruleEnabled && newHand.isDoubleJoker
    }
}
