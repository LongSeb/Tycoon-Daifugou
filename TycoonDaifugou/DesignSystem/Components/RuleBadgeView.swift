import SwiftUI

struct RuleBadgeView: View {
    let badge: RuleBadge

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: 1)
                )
                .frame(width: 34, height: 34)

            badgeContent
        }
    }

    @ViewBuilder
    private var badgeContent: some View {
        switch badge {
        case .star:
            Image(systemName: "star.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.cardBlush)
        case .arrows:
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.cardLavender)
        case .joker:
            Text("J")
                .font(.badgeLabel)
                .foregroundStyle(Color.cardLavender)
        case .threeSpade:
            Text("3♠")
                .font(.badgeLabelSmall)
                .foregroundStyle(Color.cardCream)
        case .eight:
            Text("8")
                .font(.badgeLabel)
                .foregroundStyle(.white.opacity(0.5))
        case .clock:
            Image(systemName: "clock")
                .font(.system(size: 13, weight: .medium))
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
    HStack(spacing: 12) {
        RuleBadgeView(badge: .star)
        RuleBadgeView(badge: .arrows)
        RuleBadgeView(badge: .joker)
        RuleBadgeView(badge: .threeSpade)
        RuleBadgeView(badge: .eight)
        RuleBadgeView(badge: .clock)
    }
    .padding(24)
    .background(Color.tycoonBlack)
}
