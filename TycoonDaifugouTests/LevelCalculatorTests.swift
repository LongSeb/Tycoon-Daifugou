import Testing
@testable import TycoonDaifugou

@Suite("LevelCalculator")
struct LevelCalculatorTests {

    // MARK: - level(forTotalXP:)

    @Test("level 1 at 0 XP")
    func levelAtZeroXP() {
        #expect(LevelCalculator.level(forTotalXP: 0) == 1)
    }

    @Test("level 1 just before first threshold (49 XP)")
    func levelJustBelowFirstThreshold() {
        #expect(LevelCalculator.level(forTotalXP: 49) == 1)
    }

    @Test("level 2 at exactly 50 XP")
    func levelAtFirstThreshold() {
        #expect(LevelCalculator.level(forTotalXP: 50) == 2)
    }

    @Test("level 9 at 549 XP (one short of level 10 threshold)")
    func levelJustBelowTier2Cap() {
        // cumXP(10) = 5×50 + 4×75 = 550; 549 is inside level 9.
        #expect(LevelCalculator.level(forTotalXP: 549) == 9)
    }

    @Test("level 10 at exactly 550 XP")
    func levelAtTier2Cap() {
        #expect(LevelCalculator.level(forTotalXP: 550) == 10)
    }

    @Test("level 11 at exactly 625 XP (start of tier 3)")
    func levelAtTier3Start() {
        // cumXP(11) = 5×50 + 5×75 = 625
        #expect(LevelCalculator.level(forTotalXP: 625) == 11)
    }

    @Test("level 20 at 1750 XP")
    func levelAtTier3End() {
        #expect(LevelCalculator.level(forTotalXP: 1_750) == 20)
    }

    @Test("level 30 at 4125 XP")
    func levelAtTier4End() {
        #expect(LevelCalculator.level(forTotalXP: 4_125) == 30)
    }

    @Test("level 40 at 7975 XP")
    func levelAtTier5End() {
        #expect(LevelCalculator.level(forTotalXP: 7_975) == 40)
    }

    @Test("level 50 at 14225 XP")
    func levelAt14225XP() {
        #expect(LevelCalculator.level(forTotalXP: 14_225) == 50)
    }

    @Test("level capped at 50 for arbitrarily high XP")
    func levelCappedAtMax() {
        #expect(LevelCalculator.level(forTotalXP: 999_999) == 50)
    }

    // MARK: - cumulativeXP(forLevel:)

    @Test("cumulative XP to reach level 1 is 0")
    func cumulativeXPForLevel1() {
        #expect(LevelCalculator.cumulativeXP(forLevel: 1) == 0)
    }

    @Test("cumulative XP to reach level 2 is 50")
    func cumulativeXPForLevel2() {
        #expect(LevelCalculator.cumulativeXP(forLevel: 2) == 50)
    }

    @Test("cumulative XP to reach level 11 is 625")
    func cumulativeXPForLevel11() {
        // 5×50 + 5×75 = 250 + 375 = 625
        #expect(LevelCalculator.cumulativeXP(forLevel: 11) == 625)
    }

    @Test("cumulative XP to reach level 50 is 14225")
    func cumulativeXPForLevel50() {
        // 5×50 + 5×75 + 10×125 + 10×250 + 10×400 + 9×650 = 14225
        #expect(LevelCalculator.cumulativeXP(forLevel: 50) == 14_225)
    }

    // MARK: - xpPerLevel(at:)

    @Test("tier 1 cost is 50 at level 5")
    func xpPerLevelTier1() {
        #expect(LevelCalculator.xpPerLevel(at: 5) == 50)
    }

    @Test("tier 2 cost is 75 at level 8")
    func xpPerLevelTier2() {
        #expect(LevelCalculator.xpPerLevel(at: 8) == 75)
    }

    @Test("tier 3 cost is 125 at level 15")
    func xpPerLevelTier3() {
        #expect(LevelCalculator.xpPerLevel(at: 15) == 125)
    }

    @Test("tier 4 cost is 250 at level 25")
    func xpPerLevelTier4() {
        #expect(LevelCalculator.xpPerLevel(at: 25) == 250)
    }

    @Test("tier 5 cost is 400 at level 35")
    func xpPerLevelTier5() {
        #expect(LevelCalculator.xpPerLevel(at: 35) == 400)
    }

    @Test("tier 6 cost is 650 at level 45")
    func xpPerLevelTier6() {
        #expect(LevelCalculator.xpPerLevel(at: 45) == 650)
    }

    // MARK: - progressInCurrentLevel(totalXP:)

    @Test("progress is 0.0 at 0 XP")
    func progressAtZeroXP() {
        #expect(LevelCalculator.progressInCurrentLevel(totalXP: 0) == 0.0)
    }

    @Test("progress is 0.5 at 25 XP (halfway through level 1)")
    func progressHalfwayThroughLevel1() {
        #expect(abs(LevelCalculator.progressInCurrentLevel(totalXP: 25) - 0.5) < 0.0001)
    }

    @Test("progress is 1.0 at max level")
    func progressAtMaxLevel() {
        #expect(LevelCalculator.progressInCurrentLevel(totalXP: 14_225) == 1.0)
    }

    // MARK: - xpToNextLevel(totalXP:)

    @Test("50 XP to next level at 0 XP")
    func xpToNextLevelAtZeroXP() {
        #expect(LevelCalculator.xpToNextLevel(totalXP: 0) == 50)
    }

    @Test("0 XP to next level at max level")
    func xpToNextLevelAtMaxLevel() {
        #expect(LevelCalculator.xpToNextLevel(totalXP: 14_225) == 0)
    }
}
