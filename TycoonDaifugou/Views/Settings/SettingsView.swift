import SwiftUI
import TycoonDaifugouKit

struct SettingsView: View {
    let onBack: () -> Void
    var store: GameRecordStore?

    @AppStorage(AppSettings.Key.soundEffectsEnabled) private var soundEffectsEnabled: Bool = true
    @AppStorage(AppSettings.Key.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(AppSettings.Key.foilEffectsEnabled) private var foilEffectsEnabled: Bool = true
    @AppStorage("auth.guestModeEnabled") private var guestModeEnabled: Bool = false

    @Environment(AuthService.self) private var authService
    @Environment(SyncManager.self) private var syncManager

    @State private var showRules = false
    @State private var showTutorial = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tycoonBlack.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                topBar
                settingsCard
                Spacer()
            }

            RulesDrawer(isPresented: $showRules)
                .zIndex(10)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showRules)
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showTutorial) {
            TutorialView(isReplay: true)
        }
        .alert("Sign out?", isPresented: $showSignOutConfirm) {
            Button("Sign out", role: .destructive) {
                authService.signOut()
                guestModeEnabled = false
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll be returned to the sign-in screen.")
        }
        .alert("Delete account?", isPresented: $showDeleteAccountConfirm) {
            Button("Delete", role: .destructive) {
                Task {
                    // Order matters: wipe cloud while still authed (rules require it),
                    // then delete the auth user, then clear local SwiftData.
                    try? await syncManager.deleteCloudData()
                    await authService.deleteAccount()
                    if !authService.isAuthenticated {
                        store?.wipeAllLocalData()
                        guestModeEnabled = false
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and all save data — stats, history, unlocks, and titles. This can't be undone.")
        }
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
            toggleRow(
                title: "Card effects",
                subtitle: "Toggle the holographic effects for some cards.",
                isOn: $foilEffectsEnabled
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
            Button(action: { showTutorial = true }) {
                HStack {
                    Text("Replay tutorial")
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
            if authService.isAuthenticated {
                divider
                Button(action: { showSignOutConfirm = true }) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sign out")
                                .font(.settingsRowTitle)
                                .foregroundStyle(Color.cardRed)

                            if let email = authService.currentUserEmail {
                                Text(email)
                                    .font(.settingsRowSubtitle)
                                    .foregroundStyle(Color.textTertiary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }

                        Spacer()

                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.cardRed.opacity(0.7))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                divider
                Button(action: { showDeleteAccountConfirm = true }) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Delete account")
                                .font(.settingsRowTitle)
                                .foregroundStyle(Color.cardRed)

                            Text("Permanently erase account and save data.")
                                .font(.settingsRowSubtitle)
                                .foregroundStyle(Color.textTertiary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.cardRed.opacity(0.7))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else if guestModeEnabled {
                divider
                Button(action: { guestModeEnabled = false }) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Sign in")
                                .font(.settingsRowTitle)
                                .foregroundStyle(Color.cardLavender)

                            Text("Sync stats and unlock multiplayer.")
                                .font(.settingsRowSubtitle)
                                .foregroundStyle(Color.textTertiary)
                                .lineLimit(1)
                        }

                        Spacer()

                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.cardLavender.opacity(0.7))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
