import SwiftUI

extension HomeViewState {
    static let preview = HomeViewState(
        totalGamesWon: 47,
        lastGame: LastGameData(
            rank: "Tycoon",
            emoji: "👑",
            xp: "+300",
            points: 18,
            duration: "8m 42s",
            ago: "2h ago",
            highlight: "Revolution in Round 2"
        ),
        recentGames: [
            .init(rank: "Rich",   xp: "+200", points: 72, ago: "Yesterday", medal: "🥈", avatarEmoji: "😎"),
            .init(rank: "Tycoon", xp: "+300", points: 90, ago: "2d ago",    medal: "🥇", avatarEmoji: "🦊"),
            .init(rank: "Poor",   xp: "+50",  points: 31, ago: "3d ago",    medal: nil,  avatarEmoji: "🐱"),
            .init(rank: "Beggar", xp: "+25",  points: 12, ago: "4d ago",    medal: nil,  avatarEmoji: "🐼"),
        ]
    )
}

#Preview {
    HomeView(state: .preview, onPlayTapped: {})
}
