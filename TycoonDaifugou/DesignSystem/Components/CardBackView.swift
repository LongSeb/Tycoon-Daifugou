import SwiftUI

/// Renders the back of a playing card with the player's equipped skin.
/// Card FACES are handled by PlayingCardView — this view is for face-down display only.
struct CardBackView: View {
    let skin: CardSkin
    var cornerRadius: CGFloat = 10
    var width: CGFloat = 68
    var height: CGFloat = 100

    @AppStorage(AppSettings.Key.foilEffectsEnabled) private var foilEffectsEnabled: Bool = true
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(skin.color)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(skin.showBorder ? Color.black.opacity(0.12) : Color.clear, lineWidth: 1)
                )

            if skin.customAnimation == .subway {
                SubwayMapOverlay(cornerRadius: cornerRadius, width: width, height: height)
                    .allowsHitTesting(false)
            } else if let overlayName = skin.overlayImageName {
                Image(overlayName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
            }

            if skin.isFoil && foilEffectsEnabled {
                foilOverlay
            }
        }
        .frame(width: width, height: height)
        .onAppear {
            guard skin.isFoil && foilEffectsEnabled else { return }
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
        } else if let foilColor = skin.foilColor {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: foilColor.opacity(0),    location: 0.0),
                            .init(color: foilColor.opacity(0),    location: max(0, shimmerPhase - 0.25)),
                            .init(color: foilColor.opacity(0.55), location: shimmerPhase),
                            .init(color: foilColor.opacity(0),    location: min(1, shimmerPhase + 0.25)),
                            .init(color: foilColor.opacity(0),    location: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
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
        CardBackView(
            skin: CardSkin(
                id: "subway", name: "Subway",
                color: Color(hex: "#F5F0E8"), isFoil: false,
                customAnimation: .subway),
            cornerRadius: 10, width: 68, height: 100
        )
    }
    .padding(24)
    .background(Color.tycoonBlack)
}
