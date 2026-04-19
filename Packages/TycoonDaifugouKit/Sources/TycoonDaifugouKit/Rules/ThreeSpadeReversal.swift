// MARK: - ThreeSpadeReversal

enum ThreeSpadeReversal {

    /// Returns `true` when playing `newHand` should trigger a 3-Spade Reversal:
    /// the 3 of Spades beats a solo Joker, ends the current trick immediately,
    /// and awards the lead to the player who played it.
    ///
    /// Only fires when both `ruleSet.threeSpadeReversal` and `ruleSet.jokers`
    /// are enabled, `lastHand` is exactly a solo Joker, and `newHand` is
    /// exactly the 3 of Spades played as a single.
    static func triggers(newHand: Hand, onto lastHand: Hand, ruleSet: RuleSet) -> Bool {
        guard ruleSet.threeSpadeReversal && ruleSet.jokers else { return false }
        guard lastHand.isSoloJoker else { return false }
        return newHand.cards == [.regular(.three, .spades)]
    }
}
