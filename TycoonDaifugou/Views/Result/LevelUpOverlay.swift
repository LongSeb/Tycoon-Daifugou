import SwiftUI

struct LevelUpOverlay: View {
    let level: Int
    let unlocks: [UnlockDefinition]
    let onDismiss: () -> Void

    @State private var particles: [PrestigeParticle] = []
    private let isPrestige: Bool

    init(level: Int, unlocks: [UnlockDefinition], onDismiss: @escaping () -> Void) {
        self.level = level
        self.unlocks = unlocks
        self.onDismiss = onDismiss
        self.isPrestige = unlocks.contains { if case .prestigeBadge = $0.type { return true }; return false }
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            if isPrestige {
                prestigeParticles
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("🎉 Level \(level)!")
                            .font(.custom("Fraunces-9ptBlackItalic", size: 38))
                            .foregroundStyle(Color.tycoonMint)
                            .tracking(-0.5)

                        if isPrestige {
                            Text("PRESTIGE REACHED")
                                .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                                .foregroundStyle(Color(hex: "#C9A84C").opacity(0.85))
                                .tracking(3)
                        }
                    }

                    VStack(spacing: 10) {
                        ForEach(Array(unlocks.enumerated()), id: \.offset) { _, def in
                            unlockRow(def)
                        }
                    }
                    .padding(.horizontal, 20)

                    Button(action: onDismiss) {
                        Text("Awesome!")
                            .font(.custom("InstrumentSans-Regular", size: 15).weight(.semibold))
                            .foregroundStyle(Color.tycoonBlack)
                            .tracking(0.3)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.tycoonMint)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                }
                .padding(.vertical, 36)
                .background(Color.tycoonSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.tycoonBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .onAppear {
            if isPrestige { spawnParticles() }
        }
    }

    private func unlockRow(_ def: UnlockDefinition) -> some View {
        HStack(spacing: 10) {
            unlockIcon(for: def.type)
                .frame(width: 28, height: 28)
            Text(def.displayName)
                .font(.ruleTitle)
                .foregroundStyle(Color.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func unlockIcon(for type: UnlockType) -> some View {
        switch type {
        case .title:
            Text("✨")
                .font(.system(size: 16))
        case .cardSkin(let skin):
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(skin.color)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
        case .profileBorder(let border):
            Circle()
                .stroke(border.color, lineWidth: 2.5)
        case .featureGate:
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.tycoonMint)
        case .prestigeBadge:
            Text("⭐")
                .font(.system(size: 16))
                .shadow(color: Color.yellow.opacity(0.6), radius: 4)
        }
    }

    // MARK: - Prestige particles

    private struct PrestigeParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var opacity: Double
        var color: Color
    }

    private var prestigeParticles: some View {
        GeometryReader { geo in
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size, height: p.size)
                    .opacity(p.opacity)
                    .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func spawnParticles() {
        let goldColors: [Color] = [
            Color(hex: "#C9A84C"),
            Color(hex: "#FFD700"),
            Color(hex: "#FFF8DC"),
            Color.white.opacity(0.6),
        ]
        particles = (0..<20).map { _ in
            PrestigeParticle(
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...0.6),
                size: CGFloat.random(in: 4...10),
                opacity: Double.random(in: 0.4...0.85),
                color: goldColors.randomElement()!
            )
        }
        withAnimation(.easeOut(duration: 2.0)) {
            particles = particles.map { p in
                var updated = p
                updated.y = p.y + CGFloat.random(in: 0.2...0.5)
                updated.opacity = 0
                return updated
            }
        }
    }
}
