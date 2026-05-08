import SwiftUI

struct AchievementToast: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: achievement.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Achievement Unlocked")
                    .font(.custom("InstrumentSans-Regular", size: 10).weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
                    .kerning(0.8)
                    .textCase(.uppercase)
                Text(achievement.title)
                    .font(.custom("Fraunces-9ptBlackItalic", size: 15))
                    .foregroundStyle(.white)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(iconColor.opacity(0.3), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 8)
        .padding(.horizontal, 20)
    }

    private var iconColor: Color {
        achievement.category == .milestone ? Color.cardGold : Color.cardBlush
    }
}

// MARK: - View Modifier

private struct AchievementToastModifier: ViewModifier {
    @Environment(AchievementManager.self) private var manager
    @State private var currentToast: Achievement? = nil
    @State private var visible = false

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = currentToast {
                    AchievementToast(achievement: toast)
                        .padding(.top, 56)
                        .opacity(visible ? 1 : 0)
                        .offset(y: visible ? 0 : -16)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: visible)
                        .zIndex(100)
                }
            }
            .onAppear {
                if !manager.toastQueue.isEmpty {
                    Task {
                        try? await Task.sleep(for: .seconds(1))
                        if !visible { showNextToast() }
                    }
                }
            }
            .onChange(of: manager.toastQueue.count) { _, count in
                if count > 0 && !visible { showNextToast() }
            }
    }

    private func showNextToast() {
        guard let achievement = manager.dequeueToast() else { return }
        currentToast = achievement
        withAnimation { visible = true }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { visible = false }
            try? await Task.sleep(for: .seconds(0.4))
            currentToast = nil
            if !manager.toastQueue.isEmpty { showNextToast() }
        }
    }
}

extension View {
    func achievementToastOverlay() -> some View {
        modifier(AchievementToastModifier())
    }
}
