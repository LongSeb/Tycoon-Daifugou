import SwiftUI

struct ProfileView: View {
    let profile: ProfileData
    var store: GameRecordStore?

    @State private var showingEditor = false

    var body: some View {
        ZStack {
            Color.tycoonBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    profileHero
                    levelCard
                    statsCard
                }
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                ProfileEditorView(
                    initialEmoji: profile.emoji,
                    initialUsername: profile.username,
                    onSave: { emoji, username in
                        store?.updateProfile(emoji: emoji, username: username)
                    }
                )
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("Tycoon Daifugō")
                .font(.brandTitle)
                .foregroundStyle(Color.textTertiary)
                .tracking(-0.2)

            Spacer()

            Button(action: {}) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Color.tycoonCard)
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: - Profile Hero

    private var profileHero: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.cardBlush)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Circle()
                            .fill(Color.tycoonCard)
                            .frame(width: 76, height: 76)
                            .overlay(
                                Text(profile.emoji)
                                    .font(.system(size: 32))
                            )
                    )

                Button(action: { showingEditor = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.tycoonCard)
                            .overlay(Circle().strokeBorder(Color.cardBlush, lineWidth: 1.5))
                            .frame(width: 22, height: 22)

                        Image(systemName: "pencil")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Color.cardBlush)
                    }
                }
            }
            .padding(.bottom, 12)

            Text(profile.username)
                .font(.cardTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.5)
                .padding(.bottom, 3)

            Text("Member since \(profile.memberSince)")
                .font(.ruleCaption)
                .foregroundStyle(Color.white.opacity(0.28))
                .padding(.bottom, 14)

            HStack(spacing: 8) {
                ProfileStatPill(value: "\(profile.wins)", label: "Wins")
                ProfileStatPill(value: "\(profile.gamesPlayed)", label: "Games")
                ProfileStatPill(value: "\(profile.winRate)%", label: "Win rate", valueColor: .cardBlush)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 22)
    }

    // MARK: - Level Card

    private var levelCard: some View {
        VStack(spacing: 0) {
            cardHeader(
                title: "LEVEL PROGRESSION",
                badge: "Lvl \(profile.currentLevel) → \(profile.currentLevel + 1)"
            )

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(profile.currentLevel)")
                                .font(.profileLevel)
                                .foregroundStyle(Color.textPrimary)
                                .tracking(-1)

                            Text("LVL")
                                .font(.sectionLabel)
                                .foregroundStyle(Color.textTertiary)
                                .tracking(1)
                        }

                        Text("\(profile.currentXP.formatted()) XP total")
                            .font(.ruleCaption)
                            .foregroundStyle(Color.textTertiary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(profile.xpForNextLevel - profile.currentXP) XP to go")
                            .font(.ruleCaption)
                            .foregroundStyle(Color.cardBlush.opacity(0.7))

                        Text("Until level \(profile.currentLevel + 1)")
                            .font(.ruleCaption)
                            .foregroundStyle(Color.white.opacity(0.25))
                    }
                }
                .padding(.bottom, 10)

                XPProgressBar(
                    currentXP: profile.currentXP,
                    levelStartXP: profile.levelStartXP,
                    xpForNextLevel: profile.xpForNextLevel
                )
                .frame(height: 5)
                .padding(.bottom, 6)

                HStack {
                    Text("Level \(profile.currentLevel)")
                        .font(.ruleCaption)
                        .foregroundStyle(Color.textTertiary)

                    Spacer()

                    Text("\(profile.currentXP.formatted()) / \(profile.xpForNextLevel.formatted()) XP")
                        .font(.ruleCaption)
                        .foregroundStyle(Color.cardBlush.opacity(0.7))
                }
                .padding(.bottom, 12)

                NextUnlockRow(item: profile.nextUnlock)

                UpcomingUnlocksSection(unlocks: profile.upcomingUnlocks)
            }
            .padding(12)
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

    // MARK: - Stats Card

    private var statsCard: some View {
        VStack(spacing: 0) {
            cardHeader(title: "STATISTICS", badge: nil)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
                ProfileStatCell(
                    value: "\(profile.wins)",
                    label: "Games won",
                    sub: "of \(profile.gamesPlayed) played",
                    valueColor: .cardBlush
                )
                ProfileStatCell(
                    value: "\(profile.winStreak)",
                    label: "Win streak",
                    sub: "Personal best"
                )
                ProfileStatCell(
                    value: "\(profile.totalRevolutions)",
                    label: "Revolutions",
                    sub: "Across all games",
                    valueColor: .cardLavender
                )
                ProfileStatCell(
                    value: profile.avgGameTime,
                    label: "Avg game time",
                    sub: "Per round"
                )
            }
            .background(Color.white.opacity(0.06))

            RankBreakdownSection(rankStats: profile.rankStats)

            SpecialPlaysSection(plays: profile.specialPlays)
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

    // MARK: - Helpers

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
}
