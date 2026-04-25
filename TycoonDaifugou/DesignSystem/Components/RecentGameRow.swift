import SwiftUI

struct RecentGameRowData: Identifiable {
    let id = UUID()
    let rank: String
    let xp: String
    let ago: String
    let medal: String?
    let avatarEmoji: String
}

struct RecentGameRow: View {
    let game: RecentGameRowData

    var body: some View {
        HStack(spacing: 12) {
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

            PlayerAvatar(game.avatarEmoji)

            VStack(alignment: .leading, spacing: 1) {
                Text(game.rank)
                    .font(.tycoonBody.weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                    .tracking(-0.15)

                Text(game.ago)
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Text("\(game.xp) XP")
                .font(.tycoonBody)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        RecentGameRow(game: .init(rank: "Rich", xp: "+200", ago: "Yesterday", medal: "🥈", avatarEmoji: "😎"))
        RecentGameRow(game: .init(rank: "Tycoon", xp: "+300", ago: "2d ago", medal: "🥇", avatarEmoji: "🦊"))
        RecentGameRow(game: .init(rank: "Poor", xp: "+50", ago: "3d ago", medal: nil, avatarEmoji: "🐱"))
    }
    .padding()
    .background(Color.tycoonBlack)
}
