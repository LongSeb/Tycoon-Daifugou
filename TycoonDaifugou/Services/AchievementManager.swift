import Foundation
import Observation

@Observable
final class AchievementManager {
    private(set) var achievements: [Achievement]
    private(set) var toastQueue: [Achievement] = []

    private static let storageKey = "achievements.v1"

    init() {
        achievements = AchievementDefinitions.all
        loadState()
    }

    func unlock(id: String) {
        guard let idx = achievements.firstIndex(where: { $0.id == id }),
              !achievements[idx].isUnlocked else { return }
        achievements[idx].isUnlocked = true
        achievements[idx].dateUnlocked = Date()
        saveState()
        toastQueue.append(achievements[idx])
    }

    func dequeueToast() -> Achievement? {
        guard !toastQueue.isEmpty else { return nil }
        return toastQueue.removeFirst()
    }

    var progress: (unlocked: Int, total: Int) {
        (achievements.filter(\.isUnlocked).count, achievements.count)
    }

    private func loadState() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let saved = try? JSONDecoder().decode([String: Date].self, from: data) else { return }
        for (id, date) in saved {
            guard let idx = achievements.firstIndex(where: { $0.id == id }) else { continue }
            achievements[idx].isUnlocked = true
            achievements[idx].dateUnlocked = date
        }
    }

    private func saveState() {
        var dict: [String: Date] = [:]
        for a in achievements {
            if let date = a.dateUnlocked { dict[a.id] = date }
        }
        let data = try? JSONEncoder().encode(dict)
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }
}
