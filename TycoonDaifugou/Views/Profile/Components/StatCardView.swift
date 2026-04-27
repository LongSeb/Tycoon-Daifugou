import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let tooltip: String
    let segmentLabels: [String]  // exactly 5
    let activeSegment: Int       // 0–4

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 6) {
                Text(title)
                    .font(.ruleTitle)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer()

                // Decorative indicator — tap the card body instead
                Image(systemName: "questionmark")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 14, height: 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
                    .allowsHitTesting(false)
            }

            Text(value)
                .font(.profileStatFigure)
                .foregroundStyle(Color.textPrimary)

            if isExpanded {
                labeledSpectrumBar

                Text(tooltip)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            } else {
                spectrumBar

                if activeSegment >= 0 && activeSegment < segmentLabels.count {
                    Text(segmentLabels[activeSegment])
                        .font(.ruleCaption)
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color.tycoonCard)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isExpanded ? Color.tycoonMint.opacity(0.35) : Color.clear,
                    lineWidth: 1
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }
    }

    private var spectrumBar: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(i == activeSegment ? Color.tycoonMint : Color.white.opacity(0.15))
            }
        }
        .frame(height: 4)
        .clipShape(Capsule())
    }

    private var labeledSpectrumBar: some View {
        VStack(spacing: 4) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { i in
                    Rectangle()
                        .fill(i == activeSegment ? Color.tycoonMint : Color.white.opacity(0.15))
                }
            }
            .frame(height: 4)
            .clipShape(Capsule())

            HStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { i in
                    Text(segmentLabels[i])
                        .font(.system(size: 7, weight: i == activeSegment ? .semibold : .regular))
                        .foregroundStyle(i == activeSegment ? Color.tycoonMint : Color.textTertiary.opacity(0.6))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
            }
        }
    }
}

#Preview {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        StatCardView(
            title: "Pass Rate",
            value: "34%",
            tooltip: "How often you pass instead of playing on your turn. High pass rate means you're selective or waiting for the right moment.",
            segmentLabels: ["Active", "Balanced", "Moderate", "Passive", "Hoarder"],
            activeSegment: 1
        )
        StatCardView(
            title: "Joker Efficiency",
            value: "72%",
            tooltip: "How often your Joker plays actually win the trick. A low score means Jokers are being used defensively or wasted.",
            segmentLabels: ["Wasted", "Poor", "Decent", "Sharp", "Deadly"],
            activeSegment: 3
        )
        StatCardView(
            title: "Early Finisher",
            value: "61%",
            tooltip: "How often you finish in 1st or 2nd place in a round. The most direct measure of overall performance.",
            segmentLabels: ["Beggar", "Struggling", "Balanced", "Contender", "Tycoon"],
            activeSegment: 3
        )
        StatCardView(
            title: "Sweep Rate",
            value: "18%",
            tooltip: "How often you win all 3 rounds in a single game. Rare even for strong players.",
            segmentLabels: ["Never", "Rare", "Occasional", "Frequent", "Dominant"],
            activeSegment: 2
        )
    }
    .padding(16)
    .background(Color.tycoonSurface)
}
