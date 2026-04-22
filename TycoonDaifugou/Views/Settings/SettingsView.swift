import SwiftUI
import TycoonDaifugouKit

struct SettingsView: View {
    let onBack: () -> Void

    @AppStorage(AppSettings.Key.ruleSetJSON) private var ruleSetJSON: String = AppSettings.encode(AppSettings.defaultRuleSet)
    @AppStorage(AppSettings.Key.opponentCount) private var opponentCount: Int = AppSettings.defaultOpponentCount
    @AppStorage(AppSettings.Key.roundsPerGame) private var roundsPerGame: Int = AppSettings.defaultRoundsPerGame

    @State private var ruleSet: RuleSet = AppSettings.defaultRuleSet
    @State private var showRules = false
    @State private var showResetConfirm = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tycoonBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    houseRulesCard
                    gameCard
                    aboutCard
                    resetButton
                }
                .padding(.bottom, 40)
            }

            if showRules {
                RulesDrawer(isPresented: $showRules)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showRules)
        .preferredColorScheme(.dark)
        .onAppear {
            ruleSet = decodedRuleSet()
            opponentCount = max(
                AppSettings.minOpponentCount,
                min(AppSettings.maxOpponentCount, opponentCount)
            )
            roundsPerGame = max(
                AppSettings.minRoundsPerGame,
                min(AppSettings.maxRoundsPerGame, roundsPerGame)
            )
        }
        .onChange(of: ruleSet) { _, newValue in
            ruleSetJSON = AppSettings.encode(newValue)
        }
        .alert("Reset settings?", isPresented: $showResetConfirm) {
            Button("Reset", role: .destructive) { resetToDefaults() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("House rules, opponent count, and rounds per game will return to defaults.")
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

    // MARK: - House Rules

    private var houseRulesCard: some View {
        VStack(spacing: 0) {
            cardHeader(title: "HOUSE RULES", badge: nil)

            VStack(spacing: 0) {
                toggleRow(
                    title: "Revolution",
                    subtitle: "Four-of-a-kind inverts card strength.",
                    isOn: binding(\.revolution)
                )
                divider
                toggleRow(
                    title: "8-Stop",
                    subtitle: "Playing an 8 ends the current round.",
                    isOn: binding(\.eightStop)
                )
                divider
                toggleRow(
                    title: "Jokers",
                    subtitle: "Wild cards that beat almost anything.",
                    isOn: jokersBinding
                )

                if ruleSet.jokers {
                    divider
                    jokerCountRow
                }

                divider
                toggleRow(
                    title: "3-Spade Reversal",
                    subtitle: ruleSet.jokers
                        ? "The only card that beats a Joker."
                        : "Requires Jokers.",
                    isOn: binding(\.threeSpadeReversal),
                    disabled: !ruleSet.jokers
                )
                divider
                toggleRow(
                    title: "Bankruptcy",
                    subtitle: "Lose a round as Tycoon → demoted to Beggar.",
                    isOn: binding(\.bankruptcy)
                )
            }
        }
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var jokerCountRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Joker count")
                    .font(.ruleTitle)
                    .foregroundStyle(Color.textPrimary)

                Text("\(ruleSet.jokerCount) in deck")
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Stepper(
                "",
                value: Binding(
                    get: { ruleSet.jokerCount },
                    set: { ruleSet.jokerCount = max(1, min(2, $0)) }
                ),
                in: 1...2
            )
            .labelsHidden()
            .tint(Color.tycoonPink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - Game

    private var gameCard: some View {
        VStack(spacing: 0) {
            cardHeader(title: "GAME", badge: nil)

            VStack(spacing: 0) {
                opponentsRow
                divider
                roundsRow
            }
        }
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var opponentsRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Number of opponents")
                    .font(.ruleTitle)
                    .foregroundStyle(Color.textPrimary)

                Text("\(opponentCount + 1) players total")
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Text("\(opponentCount)")
                .font(.statFigure)
                .foregroundStyle(Color.textPrimary)
                .frame(minWidth: 18, alignment: .trailing)
                .padding(.trailing, 4)

            Stepper(
                "",
                value: $opponentCount,
                in: AppSettings.minOpponentCount...AppSettings.maxOpponentCount
            )
            .labelsHidden()
            .tint(Color.tycoonPink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    private var roundsRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rounds per game")
                    .font(.ruleTitle)
                    .foregroundStyle(Color.textPrimary)

                Text("\(roundsPerGame) round\(roundsPerGame == 1 ? "" : "s")")
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Text("\(roundsPerGame)")
                .font(.statFigure)
                .foregroundStyle(Color.textPrimary)
                .frame(minWidth: 18, alignment: .trailing)
                .padding(.trailing, 4)

            Stepper(
                "",
                value: $roundsPerGame,
                in: AppSettings.minRoundsPerGame...AppSettings.maxRoundsPerGame
            )
            .labelsHidden()
            .tint(Color.tycoonPink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
    }

    // MARK: - About

    private var aboutCard: some View {
        VStack(spacing: 0) {
            cardHeader(title: "ABOUT", badge: nil)

            VStack(spacing: 0) {
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

                divider

                Button(action: { showRules = true }) {
                    HStack {
                        Text("Rules reference")
                            .font(.ruleTitle)
                            .foregroundStyle(Color.textPrimary)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.tycoonBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button(action: { showResetConfirm = true }) {
            Text("Reset to defaults")
                .font(.ruleTitle)
                .foregroundStyle(Color.tycoonPink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.tycoonSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.tycoonBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    private func resetToDefaults() {
        ruleSet = AppSettings.defaultRuleSet
        opponentCount = AppSettings.defaultOpponentCount
        roundsPerGame = AppSettings.defaultRoundsPerGame
    }

    // MARK: - Row components

    private func toggleRow(
        title: String,
        subtitle: String,
        isOn: Binding<Bool>,
        disabled: Bool = false
    ) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.ruleTitle)
                    .foregroundStyle(disabled ? Color.textTertiary : Color.textPrimary)

                Text(subtitle)
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(Color.tycoonPink)
                .disabled(disabled)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
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

    // MARK: - Bindings

    private func binding(_ keyPath: WritableKeyPath<RuleSet, Bool>) -> Binding<Bool> {
        Binding(
            get: { ruleSet[keyPath: keyPath] },
            set: { ruleSet[keyPath: keyPath] = $0 }
        )
    }

    private var jokersBinding: Binding<Bool> {
        Binding(
            get: { ruleSet.jokers },
            set: { newValue in
                ruleSet.jokers = newValue
                if newValue {
                    if ruleSet.jokerCount == 0 { ruleSet.jokerCount = 1 }
                } else {
                    ruleSet.jokerCount = 0
                    ruleSet.threeSpadeReversal = false
                }
            }
        )
    }

    // MARK: - Helpers

    private func decodedRuleSet() -> RuleSet {
        guard let data = ruleSetJSON.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(RuleSet.self, from: data) else {
            return AppSettings.defaultRuleSet
        }
        return decoded
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}
