import SwiftUI

struct RanksAndScoringSlide: View {
    var body: some View {
        VStack(spacing: 8) {
            rankScoreRow(emoji: "👑", name: "Tycoon", pts: "30 pts", color: Color.cardGold)
            rankScoreRow(emoji: "🤑", name: "Rich",        pts: "20 pts", color: Color.tycoonMint)
            rankScoreRow(emoji: "😟", name: "Poor",        pts: "10 pts", color: Color.textSecondary)
            rankScoreRow(emoji: "🥺", name: "Beggar",      pts: "0 pts",  color: Color.textTertiary)
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func rankScoreRow(emoji: String, name: String, pts: String, color: Color) -> some View {
        HStack {
            Text(emoji).font(.system(size: 20))
            Text(name)
                .font(.custom("Fraunces-9ptBlackItalic", size: 17))
                .foregroundStyle(color)
            Spacer()
            Text(pts)
                .font(.custom("Fraunces-9ptBlackItalic", size: 17))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.tycoonCard)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .frame(maxWidth: 300)
    }
}
