import Testing
@testable import TycoonDaifugou

@Suite("LevelCalculator")
struct LevelCalculatorTests {

    // MARK: - level(forTotalXP:)

    @Test("level 1 at 0 XP")
    func levelAtZeroXP() {
        #expect(LevelCalculator.level(forTotalXP: 0) == 1)
    }

    @Test("level 1 just before first tier-1 threshold")
    func levelJustBelowFirstThreshold() {
        #expect(LevelCalculator.level(forTotalXP: 249) == 1)
    }

    @Test("level 2 at exactly 250 XP")
    func levelAtFirstThreshold() {
        #expect(LevelCalculator.level(forTotalXP: 250) == 2)
    }

    @Test("level 9 at 2249 XP (one short of level 10 threshold)")
    func levelJustBelowTier1Cap() {
        // cumXP(10) = 9 × 250 = 2250; 2249 is inside level 9.
        #expect(LevelCalculator.level(forTotalXP: 2249) == 9)
    }

    @Test("level 10 at exactly 2250 XP")
    func levelAtTier1Cap() {
        #expect(LevelCalculator.level(forTotalXP: 2250) == 10)
    }

    @Test("level 11 at exactly 2500 XP (start of tier 2)")
    func levelAtTier2Start() {
        #expect(LevelCalculator.level(forTotalXP: 2500) == 11)
    }

    @Test("level 20 at 7250 XP")
    func levelMidTier2() {
        #expect(LevelCalculator.level(forTotalXP: 7250) == 20)
    }

    @Test("level 30 at 17250 XP")
    func levelMidTier3() {
        #expect(LevelCalculator.level(forTotalXP: 17250) == 30)
    }

    @Test("level 40 at 37250 XP")
    func levelMidTier4() {
        #expect(LevelCalculator.level(forTotalXP: 37250) == 40)
    }

    @Test("level 50 at 75000 XP")
    func levelAt75000XP() {
        #expect(LevelCalculator.level(forTotalXP: 75000) == 50)
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

    @Test("cumulative XP to reach level 2 is 250")
    func cumulativeXPForLevel2() {
        #expect(LevelCalculator.cumulativeXP(forLevel: 2) == 250)
    }

    @Test("cumulative XP to reach level 11 is 2500")
    func cumulativeXPForLevel11() {
        #expect(LevelCalculator.cumulativeXP(forLevel: 11) == 2500)
    }

    @Test("cumulative XP to reach level 50 is 71475")
    func cumulativeXPForLevel50() {
        // 10×250 + 10×500 + 10×1000 + 10×2000 + 9×3775 = 71475
        #expect(LevelCalculator.cumulativeXP(forLevel: 50) == 71_475)
    }

    // MARK: - xpPerLevel(at:)

    @Test("tier 1 cost is 250 at level 5")
    func xpPerLevelTier1() {
        #expect(LevelCalculator.xpPerLevel(at: 5) == 250)
    }

    @Test("tier 2 cost is 500 at level 15")
    func xpPerLevelTier2() {
        #expect(LevelCalculator.xpPerLevel(at: 15) == 500)
    }

    @Test("tier 3 cost is 1000 at level 25")
    func xpPerLevelTier3() {
        #expect(LevelCalculator.xpPerLevel(at: 25) == 1_000)
    }

    @Test("tier 4 cost is 2000 at level 35")
    func xpPerLevelTier4() {
        #expect(LevelCalculator.xpPerLevel(at: 35) == 2_000)
    }

    @Test("tier 5 cost is 3775 at level 45")
    func xpPerLevelTier5() {
        #expect(LevelCalculator.xpPerLevel(at: 45) == 3_775)
    }

    // MARK: - progressInCurrentLevel(totalXP:)

    @Test("progress is 0.0 at 0 XP")
    func progressAtZeroXP() {
        #expect(LevelCalculator.progressInCurrentLevel(totalXP: 0) == 0.0)
    }

    @Test("progress is 0.5 at 125 XP (halfway through level 1)")
    func progressHalfwayThroughLevel1() {
        #expect(abs(LevelCalculator.progressInCurrentLevel(totalXP: 125) - 0.5) < 0.0001)
    }

    @Test("progress is 1.0 at max level")
    func progressAtMaxLevel() {
        #expect(LevelCalculator.progressInCurrentLevel(totalXP: 75_000) == 1.0)
    }

    // MARK: - xpToNextLevel(totalXP:)

    @Test("250 XP to next level at 0 XP")
    func xpToNextLevelAtZeroXP() {
        #expect(LevelCalculator.xpToNextLevel(totalXP: 0) == 250)
    }

    @Test("0 XP to next level at max level")
    func xpToNextLevelAtMaxLevel() {
        #expect(LevelCalculator.xpToNextLevel(totalXP: 75_000) == 0)
    }
}
