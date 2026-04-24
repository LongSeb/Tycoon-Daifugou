import Foundation

struct LevelCalculator {
    static let maxLevel = 50

    // Each entry: level range where that XP cost applies to advance FROM each level.
    // Levels 1–10 each cost 250 to advance (10 transitions), etc.
    private static let tiers: [(range: ClosedRange<Int>, xpPerLevel: Int)] = [
        (1...10,  250),
        (11...20, 500),
        (21...30, 1_000),
        (31...40, 2_000),
        (41...50, 3_775),
    ]

    /// The XP cost to advance FROM the given level (i.e. to gain one level).
    static func xpPerLevel(at level: Int) -> Int {
        for tier in tiers where tier.range.contains(level) {
            return tier.xpPerLevel
        }
        return tiers.last!.xpPerLevel
    }

    /// Total XP needed to first reach `level`. Level 1 = 0 XP.
    static func cumulativeXP(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        var total = 0
        for tier in tiers {
            for lvl in tier.range {
                if lvl >= level { return total }
                total += tier.xpPerLevel
            }
        }
        return total
    }

    /// Current level for a player with `xp` total XP. Clamped to maxLevel.
    static func level(forTotalXP xp: Int) -> Int {
        var remaining = xp
        var current = 1
        for tier in tiers {
            for _ in tier.range {
                guard remaining >= tier.xpPerLevel else { return min(current, maxLevel) }
                remaining -= tier.xpPerLevel
                current += 1
                if current > maxLevel { return maxLevel }
            }
        }
        return maxLevel
    }

    /// 0.0–1.0 progress within the current level. 1.0 at maxLevel.
    static func progressInCurrentLevel(totalXP: Int) -> Double {
        let lvl = level(forTotalXP: totalXP)
        guard lvl < maxLevel else { return 1.0 }
        let start = cumulativeXP(forLevel: lvl)
        let cost = xpPerLevel(at: lvl)
        guard cost > 0 else { return 0.0 }
        return Double(totalXP - start) / Double(cost)
    }

    /// XP remaining until the next level-up. 0 at maxLevel.
    static func xpToNextLevel(totalXP: Int) -> Int {
        let lvl = level(forTotalXP: totalXP)
        guard lvl < maxLevel else { return 0 }
        return cumulativeXP(forLevel: lvl + 1) - totalXP
    }
}
