import SwiftUI

// MARK: - State

struct HomeViewState {
    let totalGamesWon: Int
    let lastGame: LastGameData?
    let recentGames: [RecentGameRowData]
    var isExpertUnlocked: Bool = false

    static let empty = HomeViewState(totalGamesWon: 0, lastGame: nil, recentGames: [])
}

struct LastGameData {
    let rank: String
    let emoji: String
    let xp: String
    let points: Int
    let duration: String
    let ago: String
    let highlight: String
}

// MARK: - View

struct HomeView: View {
    let state: HomeViewState
    let onPlayTapped: () -> Void
    var onCustomPlayTapped: () -> Void = {}
    var onSettingsTapped: () -> Void = {}

    @State private var showCustomSettings = false
    @State private var showDifficultyPicker = false
    @State private var scrolledMode: GameMode? = .classic

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tycoonBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    winsDisplay
                    gameModeSelector
                    lastGameSection
                    if !state.recentGames.isEmpty {
                        recentGamesSection
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("Tycoon Daifugō")
                .font(.brandTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.4)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }

    // MARK: - Wins Display

    private var winsDisplay: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(state.totalGamesWon)")
                .font(.displayWins)
                .foregroundStyle(Color.textPrimary)
                .tracking(-4)

            Text("GAMES WON")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)
                .tracking(2.4)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    // MARK: - Game Mode Selector

    private var gameModeSelector: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                let cardWidth = geo.size.width - 48
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        GameModeCard(
                            mode: .classic,
                            width: cardWidth,
                            onTap: { showDifficultyPicker = true }
                        )
                        .id(GameMode.classic)

                        GameModeCard(
                            mode: .custom,
                            width: cardWidth,
                            onTap: onCustomPlayTapped,
                            onEditTapped: { showCustomSettings = true }
                        )
                        .id(GameMode.custom)
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 24)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $scrolledMode)
            }
            .frame(height: 120)

            HStack(spacing: 6) {
                Circle()
                    .fill(scrolledMode == .custom ? Color.white.opacity(0.25) : Color.tycoonPink)
                    .frame(width: 6, height: 6)
                Circle()
                    .fill(scrolledMode == .custom ? Color.tycoonPink : Color.white.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
            .animation(.easeInOut(duration: 0.2), value: scrolledMode)
        }
        .padding(.bottom, 20)
        .sheet(isPresented: $showCustomSettings) {
            CustomGameSettingsView(isExpertUnlocked: state.isExpertUnlocked)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showDifficultyPicker) {
            DifficultyPickerSheet(
                isPresented: $showDifficultyPicker,
                isExpertUnlocked: state.isExpertUnlocked,
                onSelect: { _ in onPlayTapped() }
            )
        }
    }

    // MARK: - Last Game Section

    @ViewBuilder
    private var lastGameSection: some View {
        if let game = state.lastGame {
            lastGameCard(game: game)
        } else {
            emptyGamesCard
        }
    }

    private var emptyGamesCard: some View {
        VStack(spacing: 12) {
            Text("🎴")
                .font(.system(size: 32))

            Text("No games yet")
                .font(.cardTitle)
                .foregroundStyle(Color.textPrimary)
                .tracking(-0.4)

            Text("Tap Classic above to play your first!")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(Color.white.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func lastGameCard(game: LastGameData) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("LAST GAME")
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.textTertiary)
                    .tracking(2.4)

                Spacer()

                Text(game.ago)
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.white.opacity(0.35))
            }
            .padding(.bottom, 16)

            HStack(spacing: 14) {
                Text(game.emoji)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [.cardBlush.opacity(0.15), .cardLavender.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text(game.rank)
                        .font(.cardTitle)
                        .foregroundStyle(Color.textPrimary)
                        .tracking(-0.4)

                    Text("\(game.xp) XP earned")
                        .font(.tycoonCaption)
                        .foregroundStyle(Color.cardBlush.opacity(0.8))
                }
            }
            .padding(.bottom, 20)

            HStack(spacing: 1) {
                StatCell(label: "Points", value: "\(game.points)")
                VStack(spacing: 3) {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.cardBlush.opacity(0.7))
                        Text(game.highlight)
                            .font(.statFigure)
                            .foregroundStyle(Color.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.75)
                    }
                    Text("HIGHLIGHT")
                        .font(.tycoonCaption)
                        .foregroundStyle(Color.textTertiary)
                        .tracking(1.3)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white.opacity(0.05))
                StatCell(label: "Time",   value: game.duration)
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(20)
        .background(Color.white.opacity(0.04))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Recent Games

    private var recentGamesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EARLIER")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textSecondary)
                .tracking(2.4)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ForEach(state.recentGames) { game in
                    RecentGameRow(game: game)
                }
            }
            .padding(.horizontal, 24)
        }
    }

}
