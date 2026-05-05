import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let tooltip: String
    let segmentLabels: [String]   // exactly 5
    let activeSegment: Int        // 0–4
    let accentColor: Color
    var rawFraction: CGFloat? = nil   // pass the real 0–1 value for percentage stats
    @Binding var expandedTitle: String?

    private var isExpanded: Bool { expandedTitle == title }
    private var fillFraction: CGFloat { rawFraction ?? CGFloat(activeSegment + 1) / 5.0 }

    var body: some View {
        VStack(spacing: 0) {
            // 1 px accent stripe across the very top of the card
            accentColor
                .frame(maxWidth: .infinity, minHeight: 1, maxHeight: 1)

            // Card body
            VStack(alignment: .leading, spacing: 0) {
                titleRow
                    .padding(.bottom, 10)
                valueDisplay
                    .padding(.bottom, 4)
                floatingBar

                if isExpanded {
                    Rectangle()
                        .fill(Color(hex: "1c1c1c"))
                        .frame(height: 0.5)
                        .padding(.top, 10)
                    Text(tooltip)
                        .font(.tycoonCaption)
                        .foregroundStyle(Color(hex: "7a7a7a"))
                        .lineSpacing(6)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
            }
            .padding(EdgeInsets(top: 13, leading: 13, bottom: 12, trailing: 13))
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(Color(hex: "131313"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    isExpanded ? Color(hex: "333333") : Color(hex: "222222"),
                    lineWidth: 0.5
                )
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                expandedTitle = isExpanded ? nil : title
            }
        }
    }

    // MARK: - Title Row

    private var titleRow: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.tycoonCaption)
                .foregroundStyle(Color(hex: "4a4a4a"))
                .tracking(0.7)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()

            Text("?")
                .font(.ruleCaption)
                .foregroundStyle(Color(hex: "3a3a3a"))
                .frame(width: 15, height: 15)
                .overlay(
                    Circle().strokeBorder(Color(hex: "2a2a2a"), lineWidth: 0.5)
                )
                .allowsHitTesting(false)
        }
    }

    // MARK: - Value Display

    @ViewBuilder
    private var valueDisplay: some View {
        let hasPercent = value.hasSuffix("%")
        let numeral = hasPercent ? String(value.dropLast()) : value

        HStack(alignment: .top, spacing: 4) {
            Text(numeral)
                .font(.custom("Fraunces-9ptBlackItalic", size: 28, relativeTo: .title))
                .foregroundStyle(Color(hex: "efefef"))

            if hasPercent {
                Text("%")
                    .font(.custom("InstrumentSans-Regular", size: 12, relativeTo: .caption))
                    .foregroundStyle(Color(hex: "888888"))
                    .baselineOffset(14)
            }
        }
    }

    // MARK: - Floating Bar

    private var floatingBar: some View {
        GeometryReader { geo in
            let barW = geo.size.width
            let labelW: CGFloat = 52
            // Label position is clamped so it doesn't overflow the card edges
            let labelX = max(labelW / 2, min(barW - labelW / 2, barW * fillFraction))
            // Fill width reflects the true fraction — unclamped by label padding
            let fillW = min(barW, barW * fillFraction)

            // Floating label + tick
            VStack(spacing: 1) {
                Text(segmentLabels[max(0, min(activeSegment, segmentLabels.count - 1))])
                    .font(.ruleCaption)
                    .foregroundStyle(accentColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(width: labelW)
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 1, height: 5)
            }
            .position(x: labelX, y: geo.size.height - 11)

            // Track (full width)
            RoundedRectangle(cornerRadius: 1)
                .fill(Color(hex: "1e1e1e"))
                .frame(width: barW, height: 2)
                .position(x: barW / 2, y: geo.size.height - 1)

            // Fill — true fraction, independent of label clamping
            RoundedRectangle(cornerRadius: 1)
                .fill(accentColor)
                .frame(width: fillW, height: 2)
                .position(x: fillW / 2, y: geo.size.height - 1)
        }
        .frame(height: 24)
    }
}

#Preview {
    @Previewable @State var expanded: String? = "Pass Rate"

    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        StatCardView(
            title: "Pass Rate",
            value: "34%",
            tooltip: "How often you pass instead of playing on your turn. High pass rate means you're selective or waiting for the right moment.",
            segmentLabels: ["Active", "Balanced", "Moderate", "Passive", "Hoarder"],
            activeSegment: 1,
            accentColor: Color(hex: "c8a84b"),
            expandedTitle: $expanded
        )
        StatCardView(
            title: "Joker Efficiency",
            value: "72%",
            tooltip: "How often your Joker plays actually win the trick. A low score means Jokers are being used defensively or wasted.",
            segmentLabels: ["Wasted", "Poor", "Decent", "Sharp", "Deadly"],
            activeSegment: 3,
            accentColor: Color(hex: "d4765a"),
            expandedTitle: $expanded
        )
        StatCardView(
            title: "Early Finisher",
            value: "61%",
            tooltip: "How often you finish in 1st or 2nd place in a round. The most direct measure of overall performance.",
            segmentLabels: ["Beggar", "Struggling", "Balanced", "Contender", "Tycoon"],
            activeSegment: 3,
            accentColor: Color(hex: "7ab87a"),
            expandedTitle: $expanded
        )
        StatCardView(
            title: "Revolution Rate",
            value: "1.1",
            tooltip: "How often you trigger a revolution per game.",
            segmentLabels: ["Never", "Rare", "Balanced", "Often", "Revolutionary"],
            activeSegment: 1,
            accentColor: Color(hex: "5a8fd4"),
            expandedTitle: $expanded
        )
    }
    .padding(16)
    .background(Color.tycoonSurface)
}
