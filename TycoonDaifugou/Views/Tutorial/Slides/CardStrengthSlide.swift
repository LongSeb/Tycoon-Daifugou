import SwiftUI

struct CardStrengthSlide: View {
    private let ranks = ["3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A", "2", "🃏"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Text("Weakest")
                        .font(.tycoonBody)
                        .foregroundStyle(Color.textTertiary)
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.textTertiary.opacity(0.5), Color.textTertiary.opacity(0)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 2)
                        .clipShape(Capsule())
                }

                HStack(spacing: 6) {
                    ForEach(Array(ranks.prefix(7)), id: \.self) { label in
                        rankChip(label: label)
                    }
                }

                HStack(spacing: 6) {
                    ForEach(Array(ranks.suffix(7)), id: \.self) { label in
                        rankChip(label: label)
                    }
                }

                HStack(spacing: 8) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.tycoonMint.opacity(0), Color.tycoonMint.opacity(0.5)],
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

            Spacer()
        }
        .frame(maxHeight: .infinity)
    }

    private func rankChip(label: String) -> some View {
        Text(label)
            .font(.custom("Fraunces-9ptBlackItalic", size: 18))
            .foregroundStyle(Color.textPrimary)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.tycoonCard)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.tycoonBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
