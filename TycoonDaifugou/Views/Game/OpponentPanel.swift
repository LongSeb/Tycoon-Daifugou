import SwiftUI
import TycoonDaifugouKit

struct OpponentPanel: View {
    let player: Player
    let tint: Color
    let emoji: String
    let isActive: Bool
    let aiPlayCount: Int
    let pendingCard: Card?
    let cardNamespace: Namespace.ID

    @State private var isFlashing = false

    private var cardsLeft: Int { player.isBankrupt ? 0 : player.hand.count }
    private var rankLabel: String {
        player.isBankrupt ? "BANKRUPT" : (player.displayTitle?.displayName.uppercased() ?? "COMMONER")
    }

    var body: some View {
        ZStack(alignment: .top) {
            tint

            OpponentTag(cardsLeft: cardsLeft, rank: rankLabel, isActive: isActive, isBankrupt: player.isBankrupt)
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

            // Pending card — shown face-up while the AI is "committing" to the play.
            // Tagged with matchedGeometryEffect so it flies to the pile when state updates.
            if let card = pendingCard {
                PlayingCardView(card: card, style: .hand)
                    .matchedGeometryEffect(id: card, in: cardNamespace)
                    .rotationEffect(.degrees(-8))
                    // Insertion scales in; removal fades while the pile card flies from this position.
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.6).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(10)
            }
        }
        .overlay(
            Rectangle()
                .strokeBorder(
                    Color.tycoonMint.opacity(isFlashing ? 0.7 : 0),
                    lineWidth: 1.5
                )
                .animation(.easeOut(duration: 0.35), value: isFlashing)
        )
        .onChange(of: aiPlayCount) { _, _ in
            guard aiPlayCount > 0 else { return }
            withAnimation(.easeIn(duration: 0.1)) { isFlashing = true }
            Task {
                try? await Task.sleep(nanoseconds: 350_000_000)
                withAnimation(.easeOut(duration: 0.3)) { isFlashing = false }
            }
        }
    }
}

private struct OpponentTag: View {
    let cardsLeft: Int
    let rank: String
    let isActive: Bool
    let isBankrupt: Bool

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
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardsLeft)

            Text(rank)
                .font(.custom("InstrumentSans-Regular", size: 7).weight(.semibold))
                .foregroundStyle(
                    isBankrupt
                        ? Color.cardCream.opacity(0.75)
                        : (isActive ? Color.cardBlush : Color.white.opacity(0.3))
                )
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
