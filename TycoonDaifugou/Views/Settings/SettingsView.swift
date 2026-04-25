import SwiftUI
import TycoonDaifugouKit

struct SettingsView: View {
    let onBack: () -> Void

    @AppStorage(AppSettings.Key.soundEffectsEnabled) private var soundEffectsEnabled: Bool = true
    @AppStorage(AppSettings.Key.hapticsEnabled) private var hapticsEnabled: Bool = true

    @State private var showRules = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tycoonBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    settingsCard
                }
                .padding(.bottom, 40)
            }

            RulesDrawer(isPresented: $showRules)
                .zIndex(10)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showRules)
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Color.tycoonCard)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                    .clipShape(Circle())
            }

            Spacer()

            Text("Settings")
                .font(.brandTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.2)

            Spacer()

            Color.clear.frame(width: 32, height: 32)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(spacing: 0) {
            toggleRow(
                title: "Sound effects",
                subtitle: "Card plays, revolutions, and round chimes.",
                isOn: $soundEffectsEnabled
            )
            divider
            toggleRow(
                title: "Haptics",
                subtitle: "Tactile feedback on taps and game events.",
                isOn: $hapticsEnabled
            )
            divider
            Link(destination: URL(string: "mailto:tycoon@tothecosmos.com")!) {
                HStack {
                    Text("Send feedback")
                        .font(.settingsRowTitle)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Image(systemName: "envelope")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            divider
            Button(action: {}) {
                HStack {
                    Text("Share the app")
                        .font(.settingsRowTitle)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            divider
            Button(action: { showRules = true }) {
                HStack {
                    Text("Rules reference")
                        .font(.settingsRowTitle)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            divider
            Link(destination: URL(string: "https://joshzullo.com/privacy")!) {
                HStack {
                    Text("Privacy policy")
                        .font(.settingsRowTitle)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            divider
            HStack {
                Text("Version")
                    .font(.ruleTitle)
                    .foregroundStyle(Color.textPrimary)

                Spacer()

                Text(appVersion)
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Row components

    private func toggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        disabled: Bool = false
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.settingsRowTitle)
                    .foregroundStyle(disabled ? Color.textTertiary : Color.textPrimary)

                Text(subtitle)
                    .font(.settingsRowSubtitle)
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.tycoonMint)
                .disabled(disabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .opacity(disabled ? 0.55 : 1)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.05))
            .frame(height: 1)
    }

    private func cardHeader(title: String, badge: String?) -> some View {
        HStack {
            Text(title)
                .font(.sectionLabel)
                .foregroundStyle(Color.white.opacity(0.25))
                .tracking(2)

            Spacer()

            if let badge {
                Text(badge)
                    .font(.ruleCaption)
                    .foregroundStyle(Color.cardBlush.opacity(0.6))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    // MARK: - Helpers

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
