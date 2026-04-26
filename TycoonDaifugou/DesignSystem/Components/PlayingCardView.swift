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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )

            if card.isJoker {
                Text("JKR")
                    .font(.custom("Fraunces-9ptBlackItalic", size: jokerCornerFontSize))
                    .foregroundStyle(inkColor)
                    .padding(.leading, cornerPadding)
                    .padding(.top, cornerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                Text("JKR")
                    .font(.custom("Fraunces-9ptBlackItalic", size: jokerCornerFontSize))
                    .foregroundStyle(inkColor)
                    .rotationEffect(.degrees(180))
                    .padding(.trailing, cornerPadding)
                    .padding(.bottom, cornerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                Image("JokerCard")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(inkColor)
                    .aspectRatio(268.0 / 360.0, contentMode: .fit)
                    .padding(2)
            } else {
                cornerLabel
                    .padding(.leading, cornerPadding)
                    .padding(.top, cornerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                cornerLabel
                    .rotationEffect(.degrees(180))
                    .padding(.trailing, cornerPadding)
                    .padding(.bottom, cornerPadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)

                Text(card.displaySuit)
                    .font(.system(size: centerSuitFontSize))
                    .foregroundStyle(inkColor)
            }

            if isSelected {
                Circle()
                    .fill(Color.cardSelectAccent)
                    .frame(width: selectionDotSize, height: selectionDotSize)
                    .offset(y: selectionDotOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(width: width, height: height)
        .colorMultiply(playable ? .white : Color(white: 0.55))
        .allowsHitTesting(playable)
    }

    private var cornerLabel: some View {
        VStack(spacing: 1) {
            Text(card.displayValue)
                .font(.custom("Fraunces-9ptBlackItalic", size: cornerFontSize))
                .foregroundStyle(card.suitColor)
            Text(card.displaySuit)
                .font(.system(size: cornerSuitFontSize))
                .foregroundStyle(card.suitColor)
        }
    }

    private var width: CGFloat { style == .hand ? 68 : 96 }
    private var height: CGFloat { style == .hand ? 100 : 136 }
    private var cornerRadius: CGFloat { style == .hand ? 10 : 14 }
    private var cornerFontSize: CGFloat { style == .hand ? 13 : 17 }
    private var cornerSuitFontSize: CGFloat { style == .hand ? 11 : 14 }
    private var centerSuitFontSize: CGFloat { style == .hand ? 34 : 52 }
    private var cornerPadding: CGFloat { style == .hand ? 6 : 10 }
    private var jokerCornerFontSize: CGFloat { style == .hand ? 11 : 15 }
    private var jokerColor: Color {
        if case .joker(let index) = card {
            return index == 0 ? Color.cardSuitBlack : Color.cardSuitRed
        }
        return Color.cardSuitRed
    }
    private var inkColor: Color {
        guard playable else { return .black }
        return card.isJoker ? jokerColor : card.suitColor
    }
    private var selectionDotSize: CGFloat { style == .hand ? 5 : 6 }
    private var selectionDotOffset: CGFloat { style == .hand ? -9 : -11 }

    private var fillColor: Color {
        switch style {
        case .hand:
            return isSelected ? .cardSelectFill : .cardCream
        case .pile:
            return .cardCream
        }
    }

    private var borderColor: Color {
        switch style {
        case .hand:
            return isSelected
                ? Color.cardSelectAccent.opacity(0.7)
                : Color.black.opacity(0.08)
        case .pile:
            return Color.black.opacity(0.08)
        }
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
