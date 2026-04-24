import SwiftUI

struct ResultPlayerRow: View {
    let position: Int
    let player: ResultPlayer

    var body: some View {
        HStack(spacing: 10) {
            Text("\(position)")
                .font(.resultPosition)
                .foregroundStyle(player.isPlayer ? Color.cardBlush.opacity(0.5) : Color.white.opacity(0.2))
                .frame(width: 20, alignment: .center)

            Circle()
                .fill(player.isPlayer
                      ? Color.cardBlush.opacity(0.08)
                      : Color.white.opacity(0.05))
                .overlay(
                    Circle().strokeBorder(
                        player.isPlayer ? Color.cardBlush.opacity(0.3) : Color.white.opacity(0.12),
                        lineWidth: 1.5
                    )
                )
                .frame(width: 34, height: 34)
                .overlay(Text(player.emoji).font(.system(size: 16)))

            VStack(alignment: .leading, spacing: 1) {
                Text(player.name)
                    .font(.ruleTitle)
                    .foregroundStyle(player.isPlayer ? Color.cardBlush : Color.textPrimary)
                Text(player.rank)
                    .font(.resultMeta)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text("\(player.totalScore)")
                    .font(.badgeLabel)
                    .foregroundStyle(player.isPlayer ? Color.cardBlush : Color.white.opacity(0.55))
                Text("PTS")
                    .font(.sectionLabel)
                    .foregroundStyle(player.isPlayer ? Color.cardBlush.opacity(0.4) : Color.white.opacity(0.2))
                    .tracking(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(player.isPlayer ? Color.cardBlush.opacity(0.06) : Color.clear)
    }
}
