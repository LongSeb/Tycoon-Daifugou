import SwiftUI

struct ProfileView: View {
    let profile: ProfileData
    var store: GameRecordStore?
    var onSettingsTapped: () -> Void = {}

    @Environment(AuthService.self) private var authService
    @AppStorage("auth.guestModeEnabled") private var guestModeEnabled: Bool = false
    @State private var showingEditor = false
    @State private var showingTitlePicker = false
    @State private var showingSkinPicker = false
    @State private var showingGuestPrompt = false
    @State private var showingSignIn = false
    @State private var motion = MotionManager()

    private var isGuest: Bool { !authService.isAuthenticated }

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
        .environment(\.motionManager, motion)
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
        .sheet(isPresented: $showingEditor) {
            NavigationStack {
                ProfileEditorView(
                    initialEmoji: profile.emoji,
                    initialUsername: profile.username,
                    currentLevel: profile.currentLevel,
                    unlockedBorders: profile.unlockedBorders,
                    currentBorderID: profile.equippedBorder?.id,
                    onBorderSelect: { store?.updateEquippedBorder($0) },
                    onSave: { emoji, username in
                        store?.updateProfile(emoji: emoji, username: username)
                    }
                )
            }
        }
        .sheet(isPresented: $showingTitlePicker) {
            TitlePickerSheet(
                titles: profile.unlockedTitles,
                lockedTitles: profile.lockedTitles,
                currentTitle: profile.equippedTitle,
                onSelect: { store?.updateEquippedTitle($0) }
            )
        }
        .sheet(isPresented: $showingSkinPicker) {
            CardSkinPickerSheet(
                skins: profile.unlockedSkins,
                lockedSkins: profile.lockedSkins,
                currentSkinID: profile.equippedSkinID,
                onSelect: { store?.updateEquippedSkin($0.id) }
            )
        }
        .alert("Sign in to customize", isPresented: $showingGuestPrompt) {
            Button("Sign in") { showingSignIn = true }
            Button("Not now", role: .cancel) {}
        } message: {
            Text("Profile customization is available once you sign in.")
        }
        .fullScreenCover(isPresented: $showingSignIn) {
            SignInView(
                onContinueAsGuest: { showingSignIn = false },
                requiresGuestConfirm: false
            )
        }
        .onChange(of: authService.isAuthenticated) { _, isAuthed in
            if isAuthed {
                guestModeEnabled = false
                showingSignIn = false
            }
        }
    }

    // MARK: - Avatar with Border

    private var avatarWithBorder: some View {
        ZStack {
            if let border = profile.equippedBorder {
                HoloBorderRing(diameter: 86, lineWidth: 5, color: border.color)
            }

            Circle()
                .fill(Color.tycoonCard)
                .frame(width: 76, height: 76)
                .overlay(
                    Text(profile.emoji)
                        .font(.system(size: 44))
                )

            if profile.hasPrestigeBadge {
                Text("⭐")
                    .font(.system(size: 12))
                    .shadow(color: Color.yellow.opacity(0.6), radius: 6)
                    .offset(x: -29, y: 29)
            }
        }
        .frame(width: 86, height: 86)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("Tycoon Daifugō")
                .font(.brandTitle)
                .foregroundStyle(Color.textTertiary)
                .tracking(-0.2)

            Spacer()

            Button(action: onSettingsTapped) {
                Image(systemName: "gearshape")
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
                avatarWithBorder

                Button(action: {
                    if isGuest {
                        showingGuestPrompt = true
                    } else {
                        showingEditor = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.tycoonCard)
                            .overlay(
                                Circle().strokeBorder(
                                    isGuest ? Color.textTertiary : Color.cardBlush,
                                    lineWidth: 1.5
                                )
                            )
                            .frame(width: 22, height: 22)

                        Image(systemName: isGuest ? "lock.fill" : "pencil")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(isGuest ? Color.textTertiary : Color.cardBlush)
                    }
                }
                .offset(x: 2, y: 2)
            }
            .padding(.bottom, 12)
            .contextMenu {
                if profile.hasPrestigeBadge {
                    Text("⭐ Level 50 — Prestige")
                }
            }

            Text(profile.username)
                .font(.cardTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.5)
                .padding(.bottom, 2)

            Text(profile.equippedTitle)
                .font(.custom("InstrumentSans-Regular", size: 13).weight(.medium).italic())
                .foregroundStyle(Color.tycoonMint)
                .padding(.bottom, 3)

            Text("Member since \(profile.memberSince)")
                .font(.ruleCaption)
                .foregroundStyle(Color.white.opacity(0.28))
                .padding(.bottom, isGuest ? 8 : 14)

            if isGuest {
                guestModePill
                    .padding(.bottom, 14)
            }

            HStack(spacing: 8) {
                customizeButton(icon: "paintpalette", label: "Card Skin") {
                    if isGuest { showingGuestPrompt = true } else { showingSkinPicker = true }
                }
                customizeButton(icon: "sparkles", label: "Title") {
                    if isGuest { showingGuestPrompt = true } else { showingTitlePicker = true }
                }
            }
            .padding(.bottom, 16)

            HStack(spacing: 8) {
                ProfileStatPill(value: "\(profile.wins)", label: "Wins")
                ProfileStatPill(value: "\(profile.gamesPlayed)", label: "Games")
                ProfileStatPill(value: "\(profile.winRate)%", label: "Win rate", valueColor: .cardBlush)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 22)
    }

    private func customizeButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: isGuest ? "lock.fill" : icon)
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                    .tracking(0.2)
            }
            .foregroundStyle(isGuest ? Color.textTertiary : Color.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.tycoonCard)
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var guestModePill: some View {
        Button(action: { showingSignIn = true }) {
            HStack(spacing: 6) {
                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 11, weight: .medium))
                Text("Guest mode · Sign in to customize")
                    .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                    .tracking(0.2)
            }
            .foregroundStyle(Color.cardLavender)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.cardLavender.opacity(0.08))
            .overlay(
                Capsule()
                    .strokeBorder(Color.cardLavender.opacity(0.35), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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
                    value: profile.avgFinishPlace,
                    label: "Avg Finish",
                    sub: "1 = Best · 4 = Worst",
                    valueColor: .cardLavender
                )
                ProfileStatCell(
                    value: profile.totalTimePlayed,
                    label: "Time played",
                    sub: "In-game total"
                )
            }
            .background(Color.white.opacity(0.06))

            RankBreakdownSection(rankStats: profile.rankStats)

            if profile.isExtendedStatsUnlocked {
                extendedStatsSection
            } else {
                lockedExtendedStatsCard
            }

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

    private var lockedExtendedStatsCard: some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Extended Stats")
                    .font(.ruleTitle)
                    .foregroundStyle(Color.textSecondary)
                Text("Unlock at Level 5")
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.tycoonSurface)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }

    private var extendedStatsSection: some View {
        Group {
            if let stats = profile.extendedStats {
                ExtendedStatsView(stats: stats)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: profile.isExtendedStatsUnlocked)
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
