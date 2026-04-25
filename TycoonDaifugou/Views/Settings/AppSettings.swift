import Foundation
import TycoonDaifugouKit

/// Shared UserDefaults keys for app-level settings. Views use `@AppStorage(AppSettings.Key.x)` to
/// bind values directly; non-view code (e.g. NavigationCoordinator) reads via the static helpers.
enum AppSettings {
    enum Key {
        static let ruleSetJSON = "settings.ruleSetJSON"
        static let opponentCount = "settings.opponentCount"
        static let roundsPerGame = "settings.roundsPerGame"
        static let soundEffectsEnabled = "settings.soundEffectsEnabled"
        static let hapticsEnabled = "settings.hapticsEnabled"
    }

    static let minOpponentCount = 2
    static let maxOpponentCount = 7
    static let defaultOpponentCount = 3
    static let minRoundsPerGame = 1
    static let maxRoundsPerGame = 5
    static let defaultRoundsPerGame = 3

    static let defaultRuleSet: RuleSet = .allRules

    static func loadRuleSet() -> RuleSet {
        guard let data = UserDefaults.standard.string(forKey: Key.ruleSetJSON)?.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(RuleSet.self, from: data) else {
            return defaultRuleSet
        }
        return decoded
    }

    static func loadOpponentCount() -> Int {
        let stored = UserDefaults.standard.integer(forKey: Key.opponentCount)
        let resolved = stored == 0 ? defaultOpponentCount : stored
        return max(minOpponentCount, min(maxOpponentCount, resolved))
    }

    static func loadRoundsPerGame() -> Int {
        let stored = UserDefaults.standard.integer(forKey: Key.roundsPerGame)
        let resolved = stored == 0 ? defaultRoundsPerGame : stored
        return max(minRoundsPerGame, min(maxRoundsPerGame, resolved))
    }

    static func encode(_ ruleSet: RuleSet) -> String {
        guard let data = try? JSONEncoder().encode(ruleSet),
              let string = String(data: data, encoding: .utf8) else {
            return ""
        }
        return string
    }
}
