import SwiftUI

// MARK: - State

struct HomeViewState {
    let totalGamesWon: Int
    let lastGame: LastGameData
    let recentGames: [RecentGameRowData]
}

struct LastGameData {
    let rank: String
    let emoji: String
    let xp: String
    let rounds: Int
    let roundsWon: Int
    let cardsPlayed: Int
    let duration: String
    let ago: String
    let highlight: String
}

// MARK: - View

struct HomeView: View {
    let state: HomeViewState
    let onPlayTapped: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tycoonBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    winsDisplay
                    playCard
                    lastGameCard
                    recentGamesSection
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

            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
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

    // MARK: - Play Card

    private var playCard: some View {
        Button(action: onPlayTapped) {
            GradientCard(style: .featurePlay) {
                ZStack(alignment: .topTrailing) {
                    HStack(spacing: 14) {
                        Text("👑")
                            .font(.system(size: 26))
                            .frame(width: 48, height: 48)
                            .background(.white.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Classic")
                                .font(.cardTitle)
                                .foregroundStyle(Color.tycoonBlack)
                                .tracking(-0.4)

                            Text("3 AI opponents · 3 rounds")
                                .font(.tycoonCaption)
                                .foregroundStyle(Color.tycoonBlack.opacity(0.5))
                        }

                        Spacer()
                    }
                    .padding(20)

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.tycoonBlack.opacity(0.3))
                        .padding(20)
                }
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Last Game Card

    private var lastGameCard: some View {
        let game = state.lastGame

        return VStack(alignment: .leading, spacing: 0) {
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
                StatCell(label: "Rounds", value: "\(game.roundsWon)/\(game.rounds)")
                StatCell(label: "Cards",  value: "\(game.cardsPlayed)")
                StatCell(label: "Time",   value: game.duration)
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 16)

            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.cardBlush.opacity(0.7))

                Text(game.highlight)
                    .font(.tycoonCaption)
                    .italic()
                    .foregroundStyle(Color.textTertiary)
            }
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
