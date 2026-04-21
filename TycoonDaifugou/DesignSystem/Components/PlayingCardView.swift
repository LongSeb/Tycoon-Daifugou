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
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(fillColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )

            if card.isJoker {
                Text("JKR")
                    .font(.custom("InstrumentSans-Regular", size: 8).weight(.semibold))
                    .foregroundStyle(Color.cardLavender)
                    .tracking(1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Text(card.displayValue)
                    .font(.custom("Fraunces-9ptBlackItalic", size: cornerFontSize))
                    .foregroundStyle(Color.white.opacity(style == .hand ? 0.5 : 0.6))
                    .padding(.leading, cornerPadding)
                    .padding(.top, cornerPadding)

                VStack(spacing: 1) {
                    Text(card.displayValue)
                        .font(.custom("Fraunces-9ptBlackItalic", size: centerFontSize))
                        .foregroundStyle(Color.textPrimary)
                    Text(card.displaySuit)
                        .font(.system(size: suitFontSize))
                        .foregroundStyle(card.suitColor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isSelected {
                Circle()
                    .fill(Color.cardBlush)
                    .frame(width: 4, height: 4)
                    .offset(y: -7)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(width: width, height: height)
    }

    private var width: CGFloat { style == .hand ? 52 : 68 }
    private var height: CGFloat { style == .hand ? 76 : 96 }
    private var cornerRadius: CGFloat { style == .hand ? 8 : 10 }
    private var cornerFontSize: CGFloat { style == .hand ? 9 : 11 }
    private var centerFontSize: CGFloat { style == .hand ? 20 : 32 }
    private var suitFontSize: CGFloat { style == .hand ? 11 : 15 }
    private var cornerPadding: CGFloat { style == .hand ? 4 : 8 }

    private var fillColor: Color {
        switch style {
        case .hand:
            return isSelected
                ? Color(red: 0.157, green: 0.118, blue: 0.133)
                : .tycoonCard
        case .pile:
            return Color(red: 0.133, green: 0.133, blue: 0.133)
        }
    }

    private var borderColor: Color {
        switch style {
        case .hand:
            return isSelected
                ? Color.cardBlush.opacity(0.55)
                : Color.white.opacity(0.11)
        case .pile:
            return Color.cardBlush.opacity(0.25)
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
