import SwiftUI

/// Renders the back of a playing card with the player's equipped skin.
/// Card FACES are handled by PlayingCardView — this view is for face-down display only.
struct CardBackView: View {
    let skin: CardSkin
    var cornerRadius: CGFloat = 10
    var width: CGFloat = 68
    var height: CGFloat = 100

    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(skin.color)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
                )

            if skin.isFoil {
                foilOverlay
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            withAnimation(
                skin.id == "shiny_black"
                    ? .linear(duration: 2).repeatForever(autoreverses: false)
                    : .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
            ) {
                shimmerPhase = skin.id == "shiny_black" ? 2 : 1
            }
        }
    }

    @ViewBuilder
    private var foilOverlay: some View {
        if skin.id == "shiny_black" {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#FF6B6B").opacity(0.18), location: 0.0),
                            .init(color: Color(hex: "#FFD700").opacity(0.18), location: 0.2),
                            .init(color: Color(hex: "#7FFF00").opacity(0.18), location: 0.4),
                            .init(color: Color(hex: "#00BFFF").opacity(0.18), location: 0.6),
                            .init(color: Color(hex: "#8A2BE2").opacity(0.18), location: 0.8),
                            .init(color: Color(hex: "#FF6B6B").opacity(0.18), location: 1.0),
                        ],
                        startPoint: UnitPoint(x: shimmerPhase - 1, y: 0),
                        endPoint: UnitPoint(x: shimmerPhase, y: 1)
                    )
                )
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.22),
                            Color.white.opacity(0),
                        ],
                        startPoint: UnitPoint(x: shimmerPhase - 0.5, y: 0),
                        endPoint: UnitPoint(x: shimmerPhase + 0.5, y: 1)
                    )
                )
        }
    }
}

#Preview {
    HStack(spacing: 12) {
        CardBackView(
            skin: CardSkin(id: "default", name: "Cream", color: .cardCream, isFoil: false)
        )
        CardBackView(
            skin: CardSkin(id: "royal_red", name: "Royal Red", color: Color(hex: "#AC2317"), isFoil: true)
        )
        CardBackView(
            skin: CardSkin(id: "shiny_black", name: "Shiny Black", color: Color(hex: "#171616"), isFoil: true)
        )
    }
    .padding(24)
    .background(Color.tycoonBlack)
}
