import Foundation

/// Level N occupies the XP range [(N-1)×200, N×200).
/// Level 1 = 0–199 XP, Level 2 = 200–399 XP, and so on.
enum LevelCalculator {
    static func level(for totalXP: Int) -> Int {
        max(1, totalXP / 200 + 1)
    }

    static func levelStartXP(for level: Int) -> Int {
        max(0, level - 1) * 200
    }

    static func xpForNextLevel(for level: Int) -> Int {
        level * 200
    }
}
