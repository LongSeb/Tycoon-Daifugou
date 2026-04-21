import SwiftUI
import TycoonDaifugouKit

struct OpponentPanel: View {
    let player: Player
    let tint: Color
    let emoji: String
    let isActive: Bool

    private var cardsLeft: Int { player.hand.count }
    private var rankLabel: String { player.currentTitle?.displayName.uppercased() ?? "—" }

    var body: some View {
        ZStack(alignment: .top) {
            tint

            OpponentTag(cardsLeft: cardsLeft, rank: rankLabel, isActive: isActive)
                .padding(.top, 8)
                .padding(.horizontal, 5)

            VStack(spacing: 3) {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Circle().strokeBorder(
                            isActive ? Color.cardBlush.opacity(0.4) : Color.white.opacity(0.08),
                            lineWidth: 1.5
                        )
                    )
                    .frame(width: 42, height: 42)
                    .overlay(Text(emoji).font(.system(size: 18)))

                HStack(spacing: 2) {
                    ForEach(0..<min(cardsLeft, 5), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .frame(width: 10, height: 14)
                    }
                }

                Text(player.displayName.uppercased())
                    .font(.custom("InstrumentSans-Regular", size: 8).weight(.semibold))
                    .foregroundStyle(isActive ? Color.cardBlush.opacity(0.45) : Color.white.opacity(0.25))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 10)
        }
    }
}

private struct OpponentTag: View {
    let cardsLeft: Int
    let rank: String
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("CARDS LEFT")
                .font(.custom("InstrumentSans-Regular", size: 7).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.28))
                .tracking(0.8)

            Text("\(cardsLeft)")
                .font(.custom("Fraunces-9ptBlackItalic", size: 20))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(1)

            Text(rank)
                .font(.custom("InstrumentSans-Regular", size: 7).weight(.semibold))
                .foregroundStyle(isActive ? Color.cardBlush : Color.white.opacity(0.3))
                .tracking(0.4)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isActive
                ? Color(red: 0.098, green: 0.055, blue: 0.071)
                : Color.tycoonBlack
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    isActive ? Color.cardBlush.opacity(0.4) : Color.white.opacity(0.1),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay(
            OpponentTagTriangle()
                .fill(isActive
                      ? Color(red: 0.098, green: 0.055, blue: 0.071)
                      : Color.tycoonBlack)
                .frame(width: 12, height: 8)
                .offset(y: 4),
            alignment: .bottom
        )
        .padding(.bottom, 8)
    }
}

private struct OpponentTagTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX - 6, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX + 6, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
