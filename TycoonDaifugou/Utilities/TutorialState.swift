import Foundation

enum TutorialState {
    static let storageKey = "hasCompletedTutorial"

    static var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: storageKey) }
        set { UserDefaults.standard.set(newValue, forKey: storageKey) }
    }
}
