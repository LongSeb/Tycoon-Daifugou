import SwiftUI

struct WelcomeSlide: View {
    var body: some View {
        VStack(spacing: 10) {
            rankBadge(emoji: "👑", name: "Tycoon", color: Color.cardGold)
            rankBadge(emoji: "🤑", name: "Rich",        color: Color.tycoonMint)
            rankBadge(emoji: "😟", name: "Poor",        color: Color.textSecondary)
            rankBadge(emoji: "🥺", name: "Beggar",      color: Color.textTertiary)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func rankBadge(emoji: String, name: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Text(emoji).font(.system(size: 24))
            Text(name)
                .font(.custom("Fraunces-9ptBlackItalic", size: 19))
                .foregroundStyle(color)
        }
        .frame(width: 200, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.tycoonCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(color.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
