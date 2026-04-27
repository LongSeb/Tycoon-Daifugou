import CoreMotion
import SwiftUI

@Observable
final class MotionManager {
    private let cm = CMMotionManager()
    private(set) var roll: Double = 0
    private(set) var pitch: Double = 0
    private(set) var isActive: Bool = false

    func start() {
        guard cm.isDeviceMotionAvailable else { return }
        cm.deviceMotionUpdateInterval = 1.0 / 60.0
        cm.startDeviceMotionUpdates(to: .main) { [weak self] data, _ in
            guard let data else { return }
            // gravity.x/z are 0 when the phone is held upright in portrait,
            // giving a natural centered starting position for the foil shimmer.
            self?.roll = data.gravity.x
            self?.pitch = data.gravity.z
            self?.isActive = true
        }
    }

    func stop() {
        cm.stopDeviceMotionUpdates()
        roll = 0
        pitch = 0
        isActive = false
    }
}

extension EnvironmentValues {
    @Entry var motionManager: MotionManager? = nil
}
