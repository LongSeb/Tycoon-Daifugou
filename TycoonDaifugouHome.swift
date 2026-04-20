import SwiftUI

// MARK: - Data Models

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

struct RecentGameData: Identifiable {
    let id = UUID()
    let rank: String
    let xp: String
    let ago: String
    let medal: String?
    let highlight: String
}

// MARK: - Main View

struct TycoonDaifugouHome: View {
    let totalWins = 47

    let lastGame = LastGameData(
        rank: "Millionaire",
        emoji: "👑",
        xp: "+300",
        rounds: 3,
        roundsWon: 2,
        cardsPlayed: 31,
        duration: "8m 42s",
        ago: "2h ago",
        highlight: "Revolution in Round 2"
    )

    let recentGames: [RecentGameData] = [
        .init(rank: "Rich",        xp: "+200", ago: "Yesterday", medal: "🥈", highlight: "Played 8-card combo"),
        .init(rank: "Millionaire", xp: "+300", ago: "2d ago",    medal: "🥇", highlight: "3-round sweep"),
        .init(rank: "Poor",        xp: "+50",  ago: "3d ago",    medal: nil,  highlight: "Lost lead in Round 3"),
        .init(rank: "Beggar",      xp: "+25",  ago: "4d ago",    medal: nil,  highlight: "Bad luck on the deal"),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background
            Color.black.ignoresSafeArea()

            // Scrollable content
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

            // Bottom tab bar
            bottomNav
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Text("Tycoon Daifugō")
                .font(.custom("Fraunces-Italic", size: 19))
                .foregroundColor(.white)
                .tracking(-0.4)

            Spacer()

            Button(action: {}) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
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
            Text("\(totalWins)")
                .font(.custom("Fraunces-LightItalic", size: 104))
                .foregroundColor(.white)
                .tracking(-4)
                .lineSpacing(0)

            Text("GAMES WON")
                .font(.custom("InstrumentSans-Medium", size: 11))
                .foregroundColor(.white.opacity(0.4))
                .tracking(2.4)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }

    // MARK: - Play Card

    private var playCard: some View {
        Button(action: {}) {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 14) {
                    // Crown icon
                    Text("👑")
                        .font(.system(size: 26))
                        .frame(width: 48, height: 48)
                        .background(.white.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Classic")
                            .font(.custom("Fraunces-SemiBold", size: 22))
                            .foregroundColor(.black)
                            .tracking(-0.4)

                        Text("3 AI opponents · 3 rounds")
                            .font(.custom("InstrumentSans-Medium", size: 13))
                            .foregroundColor(.black.opacity(0.5))
                    }

                    Spacer()
                }
                .padding(20)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black.opacity(0.3))
                    .padding(20)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.957, blue: 0.902),   // #FFF4E6
                        Color(red: 1.0, green: 0.831, blue: 0.898),   // #FFD4E5
                        Color(red: 0.898, green: 0.831, blue: 1.0),   // #E5D4FF
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Last Game Card

    private var lastGameCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("LAST GAME")
                    .font(.custom("InstrumentSans-Medium", size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2.4)

                Spacer()

                Text(lastGame.ago)
                    .font(.custom("InstrumentSans-Medium", size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.bottom, 16)

            // Rank result
            HStack(spacing: 14) {
                Text(lastGame.emoji)
                    .font(.system(size: 28))
                    .frame(width: 52, height: 52)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.831, blue: 0.898).opacity(0.15),
                                Color(red: 0.898, green: 0.831, blue: 1.0).opacity(0.15),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 2) {
                    Text(lastGame.rank)
                        .font(.custom("Fraunces-SemiBold", size: 22))
                        .foregroundColor(.white)
                        .tracking(-0.4)

                    Text("\(lastGame.xp) XP earned")
                        .font(.custom("InstrumentSans-Medium", size: 13))
                        .foregroundColor(Color(red: 1.0, green: 0.831, blue: 0.898).opacity(0.8))
                }
            }
            .padding(.bottom, 20)

            // Stats row
            HStack(spacing: 1) {
                StatCell(label: "Rounds", value: "\(lastGame.roundsWon)/\(lastGame.rounds)")
                StatCell(label: "Cards",  value: "\(lastGame.cardsPlayed)")
                StatCell(label: "Time",   value: lastGame.duration)
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.bottom, 16)

            // Highlight
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 1.0, green: 0.831, blue: 0.898).opacity(0.7))

                Text(lastGame.highlight)
                    .font(.custom("InstrumentSans-Medium", size: 12))
                    .italic()
                    .foregroundColor(.white.opacity(0.45))
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
                .font(.custom("InstrumentSans-Medium", size: 11))
                .foregroundColor(.white.opacity(0.6))
                .tracking(2.4)
                .padding(.horizontal, 24)

            VStack(spacing: 12) {
                ForEach(recentGames) { game in
                    recentGameRow(game)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private func recentGameRow(_ game: RecentGameData) -> some View {
        HStack(spacing: 12) {
            // Medal or neutral dot
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 28, height: 28)

                if let medal = game.medal {
                    Text(medal)
                        .font(.system(size: 14))
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 6, height: 6)
                }
            }

            // Avatar
            Text("😎")
                .font(.system(size: 20))
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.06))
                .clipShape(Circle())

            // Rank & time
            VStack(alignment: .leading, spacing: 1) {
                Text(game.rank)
                    .font(.custom("InstrumentSans-SemiBold", size: 15))
                    .foregroundColor(.white)
                    .tracking(-0.15)

                Text(game.ago)
                    .font(.custom("InstrumentSans-Regular", size: 12))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            // XP
            Text("\(game.xp) XP")
                .font(.custom("InstrumentSans-Medium", size: 14))
                .foregroundColor(.white.opacity(0.75))
        }
    }

    // MARK: - Bottom Nav

    private var bottomNav: some View {
        HStack {
            Spacer()
            tabItem(icon: "house.fill", label: "Home", isActive: true)
            Spacer()
            Spacer()
            tabItem(icon: "person", label: "Profile", isActive: false)
            Spacer()
        }
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(
            LinearGradient(
                colors: [.black, .black, .black.opacity(0)],
                startPoint: .bottom,
                endPoint: .top
            )
            .ignoresSafeArea()
        )
    }

    private func tabItem(icon: String, label: String, isActive: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                .foregroundColor(isActive ? .white : .white.opacity(0.4))

            Text(label)
                .font(.custom(isActive ? "InstrumentSans-SemiBold" : "InstrumentSans-Medium", size: 10))
                .foregroundColor(isActive ? .white : .white.opacity(0.4))
        }
    }
}

// MARK: - Stat Cell

struct StatCell: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.custom("Fraunces-Italic", size: 17))
                .foregroundColor(.white)
                .tracking(-0.3)

            Text(label.uppercased())
                .font(.custom("InstrumentSans-Medium", size: 10))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1.3)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.05))
    }
}

// MARK: - Preview

#Preview {
    TycoonDaifugouHome()
}
