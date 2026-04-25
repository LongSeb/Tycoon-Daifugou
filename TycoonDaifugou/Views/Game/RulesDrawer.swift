import SwiftUI

struct RulesDrawer: View {
    @Binding var isPresented: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            if isPresented {
                Color.black.opacity(0.72)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture { isPresented = false }
            }

            if isPresented {
                drawerPanel
                    .transition(.move(edge: .bottom))
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(isPresented)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPresented)
    }

    private var drawerPanel: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(Color.white.opacity(0.15))
                .frame(width: 32, height: 3)
                .padding(.top, 10)
                .padding(.bottom, 4)

            HStack {
                Text("Rules")
                    .font(.drawerTitle)
                    .foregroundStyle(Color.textPrimary)
                    .tracking(-0.5)

                Spacer()

                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .overlay(
                Divider()
                    .background(Color.white.opacity(0.06)),
                alignment: .bottom
            )

            VStack(spacing: 0) {
                ForEach(Array(GameRule.all.enumerated()), id: \.element.id) { index, rule in
                    RuleRow(rule: rule)
                    if index < GameRule.all.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.04))
                            .padding(.leading, 64)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.tycoonSheet)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

// MARK: - Rule Row

private struct RuleRow: View {
    let rule: GameRule

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RuleBadgeView(badge: rule.badge)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.title)
                    .font(.ruleTitle)
                    .foregroundStyle(Color.textPrimary)

                Text(rule.description)
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
    }
}

// MARK: - Preview

#Preview("Rules Drawer — Open") {
    ZStack {
        Color.tycoonBlack.ignoresSafeArea()
        RulesDrawer(isPresented: .constant(true))
    }
}
