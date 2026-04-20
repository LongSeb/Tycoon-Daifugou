// MARK: - Bankruptcy

enum Bankruptcy {

    /// Whether the bankruptcy rule is in effect for the given configuration.
    /// Requires at least 4 players.
    static func isApplicable(ruleSet: RuleSet, playerCount: Int) -> Bool {
        ruleSet.bankruptcy && playerCount >= 4
    }

    /// Whether the defending Millionaire should be bankrupted right now.
    /// Triggers when the first player to finish (`finishPosition == 0`) is NOT
    /// the defending Millionaire themselves.
    static func shouldTrigger(
        finishPosition: Int,
        finishedPlayerID: PlayerID,
        defendingMillionaireID: PlayerID?,
        ruleSet: RuleSet,
        playerCount: Int
    ) -> Bool {
        guard isApplicable(ruleSet: ruleSet, playerCount: playerCount) else { return false }
        guard finishPosition == 0 else { return false }
        guard let defendingID = defendingMillionaireID else { return false }
        return finishedPlayerID != defendingID
    }
}
