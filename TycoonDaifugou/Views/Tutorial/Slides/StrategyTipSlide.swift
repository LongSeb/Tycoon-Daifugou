import SwiftUI

struct StrategyTipSlide: View {
    var body: some View {
        VStack(spacing: 20) {
            tipRow(icon: "🃏", text: "Hold Jokers and 2s for when you need to break through")
            tipRow(icon: "🔗", text: "Play combos early — pairs and triples are harder to beat")
            tipRow(icon: "👀", text: "Watch the Beggar — they start rounds 2 and 3 weaker")
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text(icon)
                .font(.system(size: 28))
                .frame(width: 40, alignment: .center)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
        }
    }
}
