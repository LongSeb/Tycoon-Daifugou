import SwiftUI
import TycoonDaifugouKit

struct PlayingCardView: View {
    enum Style {
        case hand
        case pile
    }

    let card: Card
    var style: Style = .hand
    var isSelected: Bool = false
    var playable: Bool = true
    var skin: CardSkin? = nil

    @Environment(\.motionManager) private var motion
    @AppStorage(AppSettings.Key.foilEffectsEnabled) private var foilEffectsEnabled: Bool = true
    @State private var shimmerPhase: CGFloat = -1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )

            if skin?.customAnimation == .subway {
                SubwayMapOverlay(cornerRadius: cornerRadius, width: width, height: height, animateStations: foilEffectsEnabled)
                    .allowsHitTesting(false)
            }

            if card.isJoker {
                Text("JKR")
                    .font(numberFont(size: jokerCornerFontSize))
                    .foregroundStyle(inkColor)
                    .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)
                    .padding(.leading, cornerPadding)
                    .padding(.top, cornerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Text("JKR")
                    .font(numberFont(size: jokerCornerFontSize))
                    .foregroundStyle(inkColor)
                    .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)
                    .rotationEffect(.degrees(180))
                    .padding(.trailing, cornerPadding)
                    .padding(.bottom, cornerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                jokerCenterImage
                    .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)
            } else {
                cornerLabel
                    .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)
                    .padding(.leading, cornerPadding)
                    .padding(.top, cornerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                cornerLabel
                    .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)
                    .rotationEffect(.degrees(180))
                    .padding(.trailing, cornerPadding)
                    .padding(.bottom, cornerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                Text(card.displaySuit)
                    .font(.system(size: centerSuitFontSize))
                    .foregroundStyle(inkColor)
                    .darkOutline(darkOutlined)
                    .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)

            }

            if skin?.isFoil == true && foilEffectsEnabled {
                foilOverlay
            }

            if let overlayName = skin?.overlayImageName {
                Image(overlayName)
                    .resizable()
                    .renderingMode(.original)
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .allowsHitTesting(false)
            }

            if skin?.showKanjiCorners == true, let kanji = kanjiForCard(card) {
                if kanji.count == 1 {
                    Text(kanji)
                        .font(numberFont(size: kanjiCornerFontSize))
                        .foregroundStyle(inkColor)
                        .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)
                        .padding(.trailing, cornerPadding)
                        .padding(.top, cornerPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                    Text(kanji)
                        .font(numberFont(size: kanjiCornerFontSize))
                        .foregroundStyle(inkColor)
                        .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)
                        .rotationEffect(.degrees(180))
                        .padding(.leading, cornerPadding)
                        .padding(.bottom, cornerPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                } else {
                    kanjiSideLabel(kanji)
                        .padding(.trailing, cornerPadding)
                        .padding(.top, cornerPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                    kanjiSideLabel(kanji)
                        .rotationEffect(.degrees(180))
                        .padding(.leading, cornerPadding)
                        .padding(.bottom, cornerPadding)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }

            if isSelected {
                Circle()
                    .fill(skin?.isDark == true ? Color.white.opacity(0.6) : (skin?.selectionColor ?? Color.cardSelectAccent))
                    .frame(width: selectionDotSize, height: selectionDotSize)
                    .offset(y: selectionDotOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }

            if skin?.showFallingPetals == true {
                CherryBlossomPetalOverlay(width: width, height: height, cornerRadius: cornerRadius)
            }
        }
        .frame(width: width, height: height)
        .colorMultiply(playable ? .white : Color(white: 0.55))
        .allowsHitTesting(playable)
        .onAppear {
            guard skin?.isFoil == true && foilEffectsEnabled else { return }
            withAnimation(
                skin?.id == "shiny_black"
                    ? .linear(duration: 2).repeatForever(autoreverses: false)
                    : .easeInOut(duration: 1.4).repeatForever(autoreverses: true)
            ) {
                shimmerPhase = skin?.id == "shiny_black" ? 2 : 1
            }
        }
    }

    // MARK: - Foil

    @ViewBuilder
    private var foilOverlay: some View {
        if let motion, motion.isActive {
            motionFoilOverlay(motion: motion)
        } else {
            animatedFoilOverlay
        }
    }

    @ViewBuilder
    private func motionFoilOverlay(motion: MotionManager) -> some View {
        // gravity.z = -sin(θ) where θ is tilt from vertical. Adding sin(55.5°) ≈ 0.824
        // shifts the shimmer center to the typical ~55.5° hold angle rather than true upright.
        let pitchOffset = CGFloat(sin(55.5 * .pi / 180))
        let x = CGFloat(min(max(motion.roll * 1.5, -1), 1)) * 0.5 + 0.5
        let y = CGFloat(min(max((motion.pitch + pitchOffset) * 1.5, -1), 1)) * 0.5 + 0.5

        if skin?.id == "shiny_black" {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color(hex: "#FF6B6B").opacity(0.25), location: 0.0),
                            .init(color: Color(hex: "#FFD700").opacity(0.25), location: 0.2),
                            .init(color: Color(hex: "#7FFF00").opacity(0.25), location: 0.4),
                            .init(color: Color(hex: "#00BFFF").opacity(0.25), location: 0.6),
                            .init(color: Color(hex: "#8A2BE2").opacity(0.25), location: 0.8),
                            .init(color: Color(hex: "#FF6B6B").opacity(0.25), location: 1.0),
                        ],
                        startPoint: UnitPoint(x: x - 1, y: 0),
                        endPoint: UnitPoint(x: x, y: 1)
                    )
                )
        } else if let foilColor = skin?.foilColor {
            let diagPos = 0.5 + CGFloat(min(max(motion.roll * 1.5, -1), 1)) * 0.35
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: foilColor.opacity(0),    location: 0.0),
                            .init(color: foilColor.opacity(0),    location: max(0, diagPos - 0.25)),
                            .init(color: foilColor.opacity(0.55), location: diagPos),
                            .init(color: foilColor.opacity(0),    location: min(1, diagPos + 0.25)),
                            .init(color: foilColor.opacity(0),    location: 1.0),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        } else {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    RadialGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.38), location: 0),
                            .init(color: Color.white.opacity(0), location: 1),
                        ],
                        center: UnitPoint(x: x, y: y),
                        startRadius: 0,
                        endRadius: 55
                    )
                )
        }
    }

    @ViewBuilder
    private var animatedFoilOverlay: some View {
        if skin?.id == "shiny_black" {
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
        } else if let foilColor = skin?.foilColor {
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

    // MARK: - Helpers

    private func kanjiForCard(_ card: Card) -> String? {
        if card.isJoker { return "ジョーカー" }
        switch card.displayValue {
        case "A":  return "エース"
        case "2":  return "二"
        case "3":  return "三"
        case "4":  return "四"
        case "5":  return "五"
        case "6":  return "六"
        case "7":  return "七"
        case "8":  return "八"
        case "9":  return "九"
        case "10": return "十"
        case "J":  return "ジャック"
        case "Q":  return "クイーン"
        case "K":  return "キング"
        default:   return nil
        }
    }

    @ViewBuilder
    private var jokerCenterImage: some View {
        let imageName = skin?.jokerImageName ?? "JokerCard"
        if imageName == "JokerCard" {
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(inkColor)
                .aspectRatio(268.0 / 360.0, contentMode: .fit)
                .padding(2)
        } else if skin?.jokerImageUseTemplate == true {
            Image(imageName)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(inkColor)
                .scaledToFit()
                .padding(skin?.jokerImagePadding ?? 2)
        } else {
            Image(imageName)
                .resizable()
                .renderingMode(.original)
                .scaledToFit()
                .padding(skin?.jokerImagePadding ?? 2)
        }
    }

    @ViewBuilder
    private func kanjiSideLabel(_ kanji: String) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(kanji.enumerated()), id: \.offset) { _, char in
                Text(String(char))
                    .font(numberFont(size: kanjiCornerFontSize))
                    .foregroundStyle(inkColor)
                    .textDropShadow(skin?.showTextShadow == true, strong: strongShadow, color: shadowColor, opacityOverride: shadowOpacity)
            }
        }
    }

    private var kanjiCornerFontSize: CGFloat { style == .hand ? 11 : 14 }
    private var shadowColor: Color { skin?.textShadowColor ?? .black }
    private var shadowOpacity: Double? { skin?.textShadowOpacity }
    private var darkOutlined: Bool { (skin?.isDark == true && isSelected) || skin?.showTextOutline == true }
    private var strongShadow: Bool { skin?.strongTextShadow == true }

    private var cornerLabel: some View {
        VStack(spacing: skin?.cornerLabelSpacing ?? 1) {
            Text(card.displayValue)
                .font(numberFont(size: cornerFontSize))
                .foregroundStyle(inkColor)
                .darkOutline(darkOutlined)
            Text(card.displaySuit)
                .font(.system(size: cornerSuitFontSize))
                .foregroundStyle(inkColor)
                .darkOutline(darkOutlined)
        }
    }

    private func numberFont(size: CGFloat) -> Font {
        Font.custom(skin?.numberFontName ?? "Fraunces-9ptBlackItalic", size: size)
    }

    private var width: CGFloat { style == .hand ? 68 : 96 }
    private var height: CGFloat { style == .hand ? 100 : 136 }
    private var cornerRadius: CGFloat { style == .hand ? 10 : 14 }
    private var cornerFontSize: CGFloat { style == .hand ? 13 : 17 }
    private var cornerSuitFontSize: CGFloat { style == .hand ? 11 : 14 }
    private var centerSuitFontSize: CGFloat { style == .hand ? 34 : 52 }
    private var cornerPadding: CGFloat {
        if let override = skin?.cornerPaddingOverride {
            return style == .hand ? override : override * (10.0 / 6.0)
        }
        return style == .hand ? 6 : 10
    }
    private var jokerCornerFontSize: CGFloat { style == .hand ? 11 : 15 }
    private var jokerColor: Color {
        if case .joker(let index) = card {
            return index == 0 ? Color.cardSuitBlack : Color.cardSuitRed
        }
        return Color.cardSuitRed
    }
    private var inkColor: Color {
        guard playable else {
            if let override = skin?.inkColorOverride { return override.opacity(0.4) }
            return skin?.isDark == true ? .white.opacity(0.4) : .black
        }
        if let override = skin?.inkColorOverride { return override }
        if skin?.isDark == true { return .white }
        return card.isJoker ? jokerColor : card.suitColor
    }
    private var selectionDotSize: CGFloat { style == .hand ? 5 : 6 }
    private var selectionDotOffset: CGFloat { style == .hand ? -9 : -11 }

    private var fillColor: Color {
        let base: Color = skin?.color ?? .cardCream
        switch style {
        case .hand:
            if isSelected {
                if let skin, skin.isDark { return skin.color }
                return skin?.selectionColor ?? .cardSelectFill
            }
            return base
        case .pile:
            return base
        }
    }

    private var borderColor: Color {
        guard skin?.showBorder != false else { return .clear }
        let isRoyalRed = skin?.id == "royal_red"
        switch style {
        case .hand:
            if isSelected {
                return skin?.isDark == true ? Color.white.opacity(0.4) : (skin?.selectionColor ?? Color.cardSelectAccent).opacity(0.7)
            }
            return isRoyalRed ? Color.black.opacity(0.55) : Color.black.opacity(0.08)
        case .pile:
            return isRoyalRed ? Color.black.opacity(0.55) : Color.black.opacity(0.08)
        }
    }
}

private extension View {
    func darkOutline(_ active: Bool) -> some View {
        let c: Color = active ? .black : .clear
        return self
            .shadow(color: c, radius: 0, x:  0.5, y:    0)
            .shadow(color: c, radius: 0, x: -0.5, y:    0)
            .shadow(color: c, radius: 0, x:    0, y:  0.5)
            .shadow(color: c, radius: 0, x:    0, y: -0.5)
    }

    func textDropShadow(_ active: Bool, strong: Bool = false, color: Color = .black, opacityOverride: Double? = nil) -> some View {
        let opacity = opacityOverride ?? (strong ? 0.95 : 0.22)
        let useStrong = strong && opacityOverride == nil
        return self
            .shadow(color: active ? color.opacity(opacity) : .clear, radius: useStrong ? 4 : 2, x: 0, y: useStrong ? 2 : 1)
            .shadow(color: (active && useStrong) ? color.opacity(0.80) : .clear, radius: 2, x: 0, y: 1)
            .shadow(color: (active && useStrong) ? color.opacity(0.60) : .clear, radius: 6, x: 0, y: 3)
    }
}

#Preview {
    HStack(spacing: 20) {
        PlayingCardView(card: .regular(.ace, .hearts), style: .hand)
        PlayingCardView(card: .regular(.seven, .spades), style: .hand, isSelected: true)
        PlayingCardView(card: .joker(index: 0), style: .hand)
        PlayingCardView(card: .regular(.king, .diamonds), style: .pile)
    }
    .padding(24)
    .background(Color.tycoonBlack)
}
