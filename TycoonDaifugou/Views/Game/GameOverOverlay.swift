import SwiftUI
import TycoonDaifugouKit

struct GameOverOverlay: View {
    let standings: [(player: Player, xp: Int)]
    let humanID: PlayerID
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 20) {
                Text("GAME OVER")
                    .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
                    .tracking(3)

                if let human = standings.first(where: { $0.player.id == humanID }) {
                    Text(human.player.currentTitle?.displayName ?? "—")
                        .font(.displayL)
                        .foregroundStyle(Color.cardCream)
                }

                VStack(spacing: 10) {
                    ForEach(Array(standings.enumerated()), id: \.element.player.id) { idx, entry in
                        standingRow(position: idx + 1, entry: entry)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button(action: onExit) {
                    Text("EXIT")
                        .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                        .foregroundStyle(Color.tycoonBlack)
                        .tracking(2)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 14)
                        .background(Color.cardBlush)
                        .clipShape(Capsule())
                }
            }
            .padding(24)
        }
    }

    private func standingRow(position: Int, entry: (player: Player, xp: Int)) -> some View {
        let isHuman = entry.player.id == humanID
        return HStack(spacing: 12) {
            Text("\(position)")
                .font(.custom("Fraunces-9ptBlackItalic", size: 18))
                .foregroundStyle(isHuman ? Color.cardBlush : Color.textTertiary)
                .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.player.displayName)
                    .font(.custom("InstrumentSans-Regular", size: 13).weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
                Text(entry.player.currentTitle?.displayName.uppercased() ?? "—")
                    .font(.custom("InstrumentSans-Regular", size: 9).weight(.semibold))
                    .foregroundStyle(Color.textTertiary)
                    .tracking(1)
            }

            Spacer()

            Text("\(entry.xp) XP")
                .font(.custom("Fraunces-9ptBlackItalic", size: 14))
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
