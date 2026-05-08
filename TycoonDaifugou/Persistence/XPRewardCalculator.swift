import Foundation

struct XPRewardCalculator {
    struct GameXPResult {
        let baseXP: Int
        let bonuses: [(label: String, amount: Int)]
        var totalXP: Int { baseXP + bonuses.reduce(0) { $0 + $1.amount } }
    }

    // cumulativePoints → base XP. Checked in descending order.
    private static let baseBrackets: [(minPoints: Int, xp: Int)] = [
        (90, 100),
        (60, 70),
        (30, 45),
        (0,  20),
    ]

    static func compute(
        cumulativePoints: Int,
        revolutionsTriggered: Int,
        counterRevolutionsTriggered: Int,
        jokersPlayed: Int,
        wasThreeRoundSweep: Bool,
        wasShutOut: Bool,
        comebackRounds: Int,
        isFirstGameOfDay: Bool = false
    ) -> GameXPResult {
        let base = baseBrackets.first { cumulativePoints >= $0.minPoints }?.xp ?? 20

        var bonuses: [(label: String, amount: Int)] = []
        if revolutionsTriggered > 0 {
            bonuses.append(("Revolution\(revolutionsTriggered > 1 ? " ×\(revolutionsTriggered)" : "")", 15 * revolutionsTriggered))
        }
        if counterRevolutionsTriggered > 0 {
            bonuses.append(("Counter-revolution\(counterRevolutionsTriggered > 1 ? " ×\(counterRevolutionsTriggered)" : "")", 20 * counterRevolutionsTriggered))
        }
        if wasThreeRoundSweep {
            bonuses.append(("3-round sweep", 25))
        }
        if jokersPlayed > 0 {
            bonuses.append(("Joker\(jokersPlayed > 1 ? " ×\(jokersPlayed)" : "") played", 5 * jokersPlayed))
        }
        if wasShutOut {
            bonuses.append(("Shut-out finish", 15))
        }
        if comebackRounds > 0 {
            bonuses.append(("Comeback\(comebackRounds > 1 ? " ×\(comebackRounds)" : "")", 20 * comebackRounds))
        }
        if isFirstGameOfDay {
            bonuses.append(("First game of the day", 10))
        }

        return GameXPResult(baseXP: base, bonuses: bonuses)
    }
}
