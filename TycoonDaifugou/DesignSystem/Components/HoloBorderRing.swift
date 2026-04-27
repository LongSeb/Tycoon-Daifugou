import SwiftUI

/// A holographic border ring: the border's own color as the base stroke, with
/// a tight white specular flare (same technique as the Royal Red card skin) that
/// either follows the gyroscope or slowly orbits when motion is unavailable.
struct HoloBorderRing: View {
    var diameter: CGFloat
    var lineWidth: CGFloat = 5
    var color: Color

    @Environment(\.motionManager) private var motion
    @State private var shimmerAngle: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(color, lineWidth: lineWidth)

            if let motion, motion.isActive {
                // rotationEffect is clockwise for positive values in SwiftUI.
                // roll > 0 = tilt right → positive rotation → flare sweeps right. ✓
                Circle()
                    .stroke(flareGradient, lineWidth: lineWidth)
                    .rotationEffect(.degrees(Double(motion.roll) * 300))
            } else {
                Circle()
                    .stroke(flareGradient, lineWidth: lineWidth)
                    .rotationEffect(.degrees(shimmerAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                            shimmerAngle = 360
                        }
                    }
            }
        }
        .frame(width: diameter, height: diameter)
    }

    private var flareGradient: AngularGradient {
        // startAngle 90° (6 o'clock) → clockwise → location 0.5 lands at 270° (12 o'clock).
        // rotationEffect(+N°) then sweeps the flare clockwise, matching tilt direction.
        AngularGradient(
            stops: [
                .init(color: .clear,                    location: 0.00),
                .init(color: .clear,                    location: 0.42),
                .init(color: Color.white.opacity(0.50), location: 0.47),
                .init(color: Color.white.opacity(0.90), location: 0.50),
                .init(color: Color.white.opacity(0.50), location: 0.53),
                .init(color: .clear,                    location: 0.58),
                .init(color: .clear,                    location: 1.00),
            ],
            center: .center,
            startAngle: .degrees(90),
            endAngle: .degrees(450)
        )
    }
}
