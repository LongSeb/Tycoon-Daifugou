import SwiftUI

struct RankBreakdownSection: View {
    let rankStats: [RankStat]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FINISH RANK BREAKDOWN")
                .font(.sectionLabel)
                .foregroundStyle(Color.white.opacity(0.2))
                .tracking(2)

            ForEach(rankStats) { stat in
                HStack(spacing: 8) {
                    Text(stat.rank)
                        .font(.ruleCaption)
                        .foregroundStyle(stat.color)
                        .frame(width: 80, alignment: .leading)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(stat.color)
                                .frame(width: geo.size.width * stat.fraction)
                        }
                    }
                    .frame(height: 3)

                    Text("\(stat.count)")
                        .font(.ruleCaption)
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 20, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1),
            alignment: .top
        )
    }
}
