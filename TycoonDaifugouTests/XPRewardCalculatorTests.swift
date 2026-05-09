import Testing
@testable import TycoonDaifugou

@Suite("XPRewardCalculator")
struct XPRewardCalculatorTests {

    private func compute(
        points: Int,
        revolutions: Int = 0,
        counterRevolutions: Int = 0,
        jokers: Int = 0,
        sweep: Bool = false,
        shutOut: Bool = false,
        comebacks: Int = 0
    ) -> XPRewardCalculator.GameXPResult {
        XPRewardCalculator.compute(
            cumulativePoints: points,
            revolutionsTriggered: revolutions,
            counterRevolutionsTriggered: counterRevolutions,
            jokersPlayed: jokers,
            wasThreeRoundSweep: sweep,
            wasShutOut: shutOut,
            comebackRounds: comebacks
        )
    }

    // MARK: - Base XP brackets

    @Test("90 pts → 75 base XP, no bonuses")
    func bracket90NoBonus() {
        let result = compute(points: 90)
        #expect(result.baseXP == 75)
        #expect(result.bonuses.isEmpty)
        #expect(result.totalXP == 75)
    }

    @Test("0 pts → 10 base XP")
    func bracket0() {
        let result = compute(points: 0)
        #expect(result.baseXP == 10)
    }

    @Test("60 pts → 50 base XP (lower bracket boundary)")
    func bracket60() {
        let result = compute(points: 60)
        #expect(result.baseXP == 50)
    }

    @Test("30 pts → 25 base XP (lower bracket boundary)")
    func bracket30() {
        let result = compute(points: 30)
        #expect(result.baseXP == 25)
    }

    @Test("29 pts → 10 base XP (just below 30 boundary)")
    func bracket29() {
        let result = compute(points: 29)
        #expect(result.baseXP == 10)
    }

    // MARK: - Bonus stacking

    @Test("90 pts + 2 revolutions + 1 joker = 100 XP")
    func revolutionsAndJoker() {
        let result = compute(points: 90, revolutions: 2, jokers: 1)
        #expect(result.baseXP == 75)
        #expect(result.totalXP == 100)  // 75 + 20 (2×10) + 5 (1 joker)
    }

    @Test("90 pts + sweep + shutout + 1 comeback stacks all bonuses")
    func allBonusesStack() {
        let result = compute(points: 90, sweep: true, shutOut: true, comebacks: 1)
        let expectedTotal = 75 + 20 + 15 + 20  // base + sweep + shutOut + comeback
        #expect(result.totalXP == expectedTotal)
        #expect(result.bonuses.count == 3)
    }

    @Test("bonuses array only contains entries that fired")
    func bonusesOnlyFiredEntries() {
        let result = compute(points: 60, revolutions: 1)
        #expect(result.bonuses.count == 1)
        #expect(result.bonuses[0].amount == 10)
    }

    @Test("counter-revolution awards 20 XP per occurrence")
    func counterRevolutionBonus() {
        let result = compute(points: 30, counterRevolutions: 1)
        #expect(result.totalXP == 25 + 20)
    }

    @Test("no bonus entries when no events fired")
    func noBonusesWhenNoEvents() {
        let result = compute(points: 0)
        #expect(result.bonuses.isEmpty)
    }
}
