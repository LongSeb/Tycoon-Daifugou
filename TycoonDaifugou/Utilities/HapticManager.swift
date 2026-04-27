import UIKit

enum HapticManager {
    static var isSuppressed: Bool = false

    private static var isEnabled: Bool {
        !isSuppressed && (UserDefaults.standard.object(forKey: AppSettings.Key.hapticsEnabled) as? Bool ?? true)
    }

    static func cardTap() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func cardPlay() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func cardPlayError() {
        guard isEnabled else { return }
        // Double rigid thud — more physically noticeable than a notification pattern
        let g = UIImpactFeedbackGenerator(style: .rigid)
        g.prepare()
        g.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            g.impactOccurred()
        }
    }

    static func pass() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }

    /// 3 heavy pulses spaced 120ms apart.
    static func revolution() {
        guard isEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        let delays: [TimeInterval] = [0, 0.12, 0.24]
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                g.impactOccurred()
            }
        }
    }

    static func roundEnd() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// 8 heavy pulses spaced 55ms apart.
    static func eightStop() {
        guard isEnabled else { return }
        let g = UIImpactFeedbackGenerator(style: .heavy)
        g.prepare()
        for i in 0..<8 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.055) {
                g.impactOccurred()
            }
        }
    }
}
