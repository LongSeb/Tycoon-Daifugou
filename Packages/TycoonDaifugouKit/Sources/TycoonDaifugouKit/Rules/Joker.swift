enum Joker {
    /// Returns true when `newHand` is a solo Joker and the Joker rule is enabled.
    /// A solo Joker beats any regular single regardless of revolution state.
    static func isSoloStronger(newHand: Hand, ruleEnabled: Bool) -> Bool {
        ruleEnabled && newHand.isSoloJoker
    }
}
