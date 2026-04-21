import SwiftUI

struct RuleBadgeView: View {
    let badge: RuleBadge
    var size: CGFloat = 34

    private var cornerRadius: CGFloat { size * 8 / 34 }
    private var iconSize: CGFloat { size * 14 / 34 }
    private var mediumIconSize: CGFloat { size * 13 / 34 }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .frame(width: size, height: size)

            badgeContent
        }
    }

    @ViewBuilder
    private var badgeContent: some View {
        switch badge {
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: iconSize))
                .foregroundStyle(Color.cardBlush)
        case .arrows:
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: mediumIconSize, weight: .medium))
                .foregroundStyle(Color.cardLavender)
        case .joker:
            Text("J")
                .font(.custom("Fraunces-9ptBlackItalic", size: size * 16 / 34))
                .foregroundStyle(Color.cardLavender)
        case .threeSpade:
            Text("3♠")
                .font(.custom("Fraunces-9ptBlackItalic", size: size * 13 / 34))
                .foregroundStyle(Color.cardCream)
        case .eight:
            Text("8")
                .font(.custom("Fraunces-9ptBlackItalic", size: size * 16 / 34))
                .foregroundStyle(.white.opacity(0.5))
        case .clock:
            Image(systemName: "clock")
                .font(.system(size: mediumIconSize, weight: .medium))
                .foregroundStyle(Color.cardBlush)
        }
    }

    private var backgroundColor: Color {
        switch badge {
        case .star, .clock:   return Color.cardBlush.opacity(0.1)
        case .arrows, .joker: return Color.cardLavender.opacity(0.1)
        case .threeSpade:     return Color.cardCream.opacity(0.08)
        case .eight:          return Color.white.opacity(0.05)
        }
    }

    private var borderColor: Color {
        switch badge {
        case .star, .clock:   return Color.cardBlush.opacity(0.15)
        case .arrows, .joker: return Color.cardLavender.opacity(0.15)
        case .threeSpade:     return Color.cardCream.opacity(0.12)
        case .eight:          return Color.white.opacity(0.08)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 12) {
            RuleBadgeView(badge: .star)
            RuleBadgeView(badge: .arrows)
            RuleBadgeView(badge: .joker)
            RuleBadgeView(badge: .threeSpade)
            RuleBadgeView(badge: .eight)
            RuleBadgeView(badge: .clock)
        }
        HStack(spacing: 12) {
            RuleBadgeView(badge: .star, size: 28)
            RuleBadgeView(badge: .arrows, size: 28)
            RuleBadgeView(badge: .joker, size: 28)
            RuleBadgeView(badge: .threeSpade, size: 28)
            RuleBadgeView(badge: .eight, size: 28)
            RuleBadgeView(badge: .clock, size: 28)
        }
    }
    .padding(24)
    .background(Color.tycoonBlack)
}
