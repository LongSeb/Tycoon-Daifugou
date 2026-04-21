import SwiftUI

struct SpecialPlaysSection: View {
    let plays: [SpecialPlayStat]
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isExpanded.toggle() } }) {
                HStack {
                    Text("SPECIAL PLAYS")
                        .font(.sectionLabel)
                        .foregroundStyle(Color.white.opacity(0.25))
                        .tracking(2)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }
            .buttonStyle(.plain)
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.05))
                    .frame(height: 1),
                alignment: .top
            )

            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(Array(plays.enumerated()), id: \.element.id) { index, play in
                        row(for: play)

                        if index < plays.count - 1 {
                            Rectangle()
                                .fill(Color.white.opacity(0.04))
                                .frame(height: 1)
                                .padding(.leading, 52)
                        }
                    }
                }
            }
        }
    }

    private func row(for play: SpecialPlayStat) -> some View {
        HStack(spacing: 10) {
            RuleBadgeView(badge: play.badge, size: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text(play.name)
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.textSecondary)

                Text(play.subtitle)
                    .font(.ruleCaption)
                    .foregroundStyle(Color.textTertiary)
            }

            Spacer()

            Text("\(play.count)")
                .font(.badgeLabel)
                .foregroundStyle(Color.textPrimary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
    }
}
