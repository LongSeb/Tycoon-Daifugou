import SwiftUI

struct CardExchangeSlide: View {
    var body: some View {
        VStack(spacing: 20) {
            exchangeBlock(
                symbol: "👑",
                lines: [
                    ("→", "Beggar's 2 best cards to Millionaire", Color.cardGold),
                    ("←", "Millionaire gives any 2 back",         Color.tycoonLav)
                ]
            )
            Rectangle()
                .fill(Color.tycoonBorder)
                .frame(height: 1)
                .padding(.horizontal, 8)
            exchangeBlock(
                symbol: "🤑",
                lines: [
                    ("→", "Poor's best card to Rich", Color.tycoonMint),
                    ("←", "Rich gives any 1 back",    Color.tycoonLav)
                ]
            )
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func exchangeBlock(symbol: String, lines: [(String, String, Color)]) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Text(symbol).font(.system(size: 42))
            VStack(alignment: .leading, spacing: 10) {
                ForEach(lines.indices, id: \.self) { i in
                    HStack(spacing: 8) {
                        Text(lines[i].0)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(lines[i].2)
                            .frame(width: 16)
                        Text(lines[i].1)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 8)
    }
}
