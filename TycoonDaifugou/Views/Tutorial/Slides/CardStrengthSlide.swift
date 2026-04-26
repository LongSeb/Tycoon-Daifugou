import SwiftUI

struct CardStrengthSlide: View {
    private let ranks = ["3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2", "🃏"]

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 2) {
                ForEach(ranks, id: \.self) { label in
                    rankChip(label: label)
                }
            }
            .padding(.horizontal, -24)  // counteract parent's 24pt horizontal padding

            HStack(spacing: 8) {
                Text("Weakest")
                    .font(.tycoonBody)
                    .foregroundStyle(Color.textTertiary)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.textTertiary.opacity(0.5), Color.tycoonMint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .clipShape(Capsule())
                Text("Strongest")
                    .font(.tycoonBody)
                    .foregroundStyle(Color.tycoonMint)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
    }

    private func rankChip(label: String) -> some View {
        Text(label)
            .font(.custom("Fraunces-9ptBlackItalic", size: 12))
            .foregroundStyle(Color.textPrimary)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.tycoonCard)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.tycoonBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
