import SwiftUI

struct PrestigeModal: View {
    let currentPrestigeLevel: Int
    let onPrestige: () -> Void
    let onDismiss: () -> Void

    private var nextPrestigeLevel: Int { currentPrestigeLevel + 1 }

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                infoCards
                Spacer(minLength: 0)
                ctaButtons
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 28)
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Text("✦")
                .font(.system(size: 26))
                .padding(.bottom, 2)

            Text("LEVEL 50 COMPLETE")
                .font(.tycoonCaption)
                .foregroundStyle(Color.cardBlush.opacity(0.8))
                .tracking(3)

            Text("Prestige\nAvailable")
                .font(.custom("Fraunces-9ptBlackItalic", size: 42, relativeTo: .largeTitle))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .tracking(-1)

            Text("Reset to Level 1 and earn Prestige \(nextPrestigeLevel) by climbing through the ranks again.")
                .font(.tycoonBody)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
                .padding(.bottom, 16)
        }
    }

    // MARK: - Info Cards

    private var infoCards: some View {
        VStack(spacing: 8) {
            infoRow(
                icon: "arrow.counterclockwise",
                iconColor: .cardBlush,
                title: "You reset to",
                detail: "Level 1 · 0 XP"
            )
            infoRow(
                icon: "checkmark.seal.fill",
                iconColor: .cardMint,
                title: "You keep",
                detail: "All unlocks, titles, skins & stats"
            )
            infoRow(
                icon: "star.fill",
                iconColor: .cardLavender,
                title: "You earn",
                detail: "Prestige \(nextPrestigeLevel) · rare & exclusive rewards · Prestige XP in Levels 1–10"
            )
            if nextPrestigeLevel == LevelCalculator.maxPrestigeLevel {
                infoRow(
                    icon: "crown.fill",
                    iconColor: Color(hex: "#C9A84C"),
                    title: "Max Prestige",
                    detail: "Prestige \(LevelCalculator.maxPrestigeLevel) is the highest rank"
                )
            }
        }
        .padding(.bottom, 8)
    }

    private func infoRow(icon: String, iconColor: Color, title: String, detail: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 34, height: 34)
                .background(iconColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 9))

            VStack(alignment: .leading, spacing: 2) {
                Text(title.uppercased())
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.textTertiary)
                    .tracking(1.2)
                Text(detail)
                    .font(.tycoonBody)
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - CTA Buttons

    private var ctaButtons: some View {
        VStack(spacing: 10) {
            Button(action: onPrestige) {
                HStack(spacing: 7) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Prestige Now")
                        .font(.settingsRowTitle)
                }
                .foregroundStyle(Color.tycoonBlack)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    LinearGradient(
                        colors: [.cardBlush, .cardLavender],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 999))
            }

            Button(action: onDismiss) {
                Text("Not Yet")
                    .font(.tycoonBody)
                    .foregroundStyle(Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 999)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 999))
            }

            Text("You can activate Prestige from your Profile anytime.")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
    }
}

#Preview {
    PrestigeModal(
        currentPrestigeLevel: 0,
        onPrestige: {},
        onDismiss: {}
    )
}
