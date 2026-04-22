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
                    .font(.custom("InstrumentSans-Regular", size: jokerFontSize).weight(.semibold))
                    .foregroundStyle(Color.cardSuitRed)
                    .tracking(1)
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
                    .foregroundStyle(card.suitColor)
            }

            if isSelected {
                Circle()
                    .fill(Color.cardSuitRed)
                    .frame(width: selectionDotSize, height: selectionDotSize)
                    .offset(y: selectionDotOffset)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(width: width, height: height)
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
    private var jokerFontSize: CGFloat { style == .hand ? 10 : 14 }
    private var selectionDotSize: CGFloat { style == .hand ? 5 : 6 }
    private var selectionDotOffset: CGFloat { style == .hand ? -9 : -11 }

    private var fillColor: Color {
        switch style {
        case .hand:
            return isSelected ? .cardBlush : .cardCream
        case .pile:
            return .cardCream
        }
    }

    private var borderColor: Color {
        switch style {
        case .hand:
            return isSelected
                ? Color.cardSuitRed.opacity(0.55)
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
