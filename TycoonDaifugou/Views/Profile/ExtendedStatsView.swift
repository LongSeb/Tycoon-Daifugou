import SwiftUI

struct ExtendedStatsView: View {
    let stats: ExtendedStatsData

    @State private var showArchetypeGuide = false
    @State private var expandedCardTitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if stats.totalGamesPlayed < 3 {
                insufficientDataView
            } else {
                playingStyleSection
                statCardsSection
            }
        }
    }

    // MARK: - Insufficient Data

    private var insufficientDataView: some View {
        VStack(spacing: 10) {
            Text("🃏")
                .font(.system(size: 36))
            Text("Play a few more games to reveal your playing style.")
                .font(.ruleTitle)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .overlay(
            Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Playing Style Section

    private var playingStyleSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("PLAYING STYLE")

            PlayStyleRadarChart(stats: stats)
                .padding(.horizontal, 14)
                .padding(.top, -8)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(stats.archetypeEmoji)
                        .font(.system(size: 20))
                    Text(stats.archetype.rawValue)
                        .font(.custom("Fraunces-9ptBlackItalic", size: 20))
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    Button { showArchetypeGuide = true } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16, weight: .regular))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                Text(stats.archetypeDescription)
                    .font(.ruleTitle)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            .sheet(isPresented: $showArchetypeGuide) {
                ArchetypeGuideSheet(currentArchetype: stats.archetype)
            }
        }
    }

    // MARK: - Stat Cards Section

    private var statCardsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header — updated design language
            Text("STAT CARDS")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(Color(hex: "444444"))
                .tracking(1.2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.top, 11)
                .padding(.bottom, 12)
                .overlay(
                    Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1),
                    alignment: .top
                )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatCardView(
                    title: "Pass Rate",
                    value: "\(Int(stats.passRate * 100))%",
                    tooltip: "How often you pass instead of playing on your turn. High pass rate means you're selective or waiting for the right moment.",
                    segmentLabels: ["Active", "Balanced", "Moderate", "Passive", "Hoarder"],
                    activeSegment: passRateSegment(stats.passRate),
                    accentColor: Color(hex: "c8a84b"),
                    rawFraction: CGFloat(stats.passRate),
                    expandedTitle: $expandedCardTitle
                )
                StatCardView(
                    title: "Revolution Rate",
                    value: String(format: "%.1f", stats.avgRevolutionsPerGame),
                    tooltip: "How often you trigger a revolution per game. Higher means you play four-of-a-kinds frequently and embrace chaos.",
                    segmentLabels: ["Never", "Rare", "Balanced", "Often", "Revolutionary"],
                    activeSegment: revRateSegment(stats.avgRevolutionsPerGame),
                    accentColor: Color(hex: "5a8fd4"),
                    expandedTitle: $expandedCardTitle
                )
                StatCardView(
                    title: "Early Finisher",
                    value: "\(Int(stats.earlyFinisherRate * 100))%",
                    tooltip: "How often you finish in 1st or 2nd place in a round. The most direct measure of overall performance.",
                    segmentLabels: ["Beggar", "Struggling", "Balanced", "Contender", "Tycoon"],
                    activeSegment: earlyFinisherSegment(stats.earlyFinisherRate),
                    accentColor: Color(hex: "7ab87a"),
                    rawFraction: CGFloat(stats.earlyFinisherRate),
                    expandedTitle: $expandedCardTitle
                )
                StatCardView(
                    title: "Comeback Rate",
                    value: "\(Int(stats.comebackRate * 100))%",
                    tooltip: "How often you recover from starting a round as Poor or Beggar to finish as Rich or Millionaire.",
                    segmentLabels: ["Rare", "Occasional", "Balanced", "Frequent", "Legend"],
                    activeSegment: comebackSegment(stats.comebackRate),
                    accentColor: Color(hex: "c47ab8"),
                    rawFraction: CGFloat(stats.comebackRate),
                    expandedTitle: $expandedCardTitle
                )
                StatCardView(
                    title: "Joker Efficiency",
                    value: "\(Int(stats.jokerEfficiency * 100))%",
                    tooltip: "How often your Joker plays actually win the trick. A low score means Jokers are being used defensively or wasted.",
                    segmentLabels: ["Wasted", "Poor", "Decent", "Sharp", "Deadly"],
                    activeSegment: rateSegment(stats.jokerEfficiency),
                    accentColor: Color(hex: "d4765a"),
                    rawFraction: CGFloat(stats.jokerEfficiency),
                    expandedTitle: $expandedCardTitle
                )
                StatCardView(
                    title: "Sweep Rate",
                    value: "\(Int(stats.sweepRate * 100))%",
                    tooltip: "How often you win all 3 rounds in a single game. Rare even for strong players.",
                    segmentLabels: ["Never", "Rare", "Occasional", "Frequent", "Dominant"],
                    activeSegment: sweepSegment(stats.sweepRate),
                    accentColor: Color(hex: "7ab8b8"),
                    rawFraction: CGFloat(stats.sweepRate),
                    expandedTitle: $expandedCardTitle
                )
                StatCardView(
                    title: "Card Hoarding",
                    value: "\(Int(stats.cardHoardingIndex * 100))%",
                    tooltip: "How long you hold onto cards relative to your results. High means you play slowly and wait for perfect moments.",
                    segmentLabels: ["Shedder", "Balanced", "Patient", "Hoarder", "Vault"],
                    activeSegment: rateSegment(stats.cardHoardingIndex),
                    accentColor: Color(hex: "a08fd4"),
                    rawFraction: CGFloat(stats.cardHoardingIndex),
                    expandedTitle: $expandedCardTitle
                )
                StatCardView(
                    title: "Trick Win Rate",
                    value: "\(Int(stats.trickWinRate * 100))%",
                    tooltip: "When you lead a trick, how often do you win it? High means you time your leads well.",
                    segmentLabels: ["Leaky", "Below Avg", "Balanced", "Sharp", "Dominant"],
                    activeSegment: trickWinSegment(stats.trickWinRate),
                    accentColor: Color(hex: "d4a85a"),
                    rawFraction: CGFloat(stats.trickWinRate),
                    expandedTitle: $expandedCardTitle
                )
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.sectionLabel)
            .foregroundStyle(Color.white.opacity(0.25))
            .tracking(2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .overlay(
                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1),
                alignment: .top
            )
    }

    // MARK: - Segment Index Helpers

    private func passRateSegment(_ v: Double) -> Int {
        switch v {
        case ..<0.21: return 0
        case ..<0.36: return 1
        case ..<0.51: return 2
        case ..<0.66: return 3
        default:      return 4
        }
    }

    private func revRateSegment(_ avg: Double) -> Int {
        switch avg {
        case ..<1.0: return 0
        case ..<3.0: return 1
        case ..<5.0: return 2
        case ..<8.0: return 3
        default:     return 4
        }
    }

    private func earlyFinisherSegment(_ v: Double) -> Int {
        switch v {
        case ..<0.21: return 0
        case ..<0.41: return 1
        case ..<0.61: return 2
        case ..<0.81: return 3
        default:      return 4
        }
    }

    private func comebackSegment(_ v: Double) -> Int {
        switch v {
        case ..<0.11: return 0
        case ..<0.26: return 1
        case ..<0.46: return 2
        case ..<0.66: return 3
        default:      return 4
        }
    }

    private func sweepSegment(_ v: Double) -> Int {
        switch v {
        case ..<0.06: return 0
        case ..<0.16: return 1
        case ..<0.31: return 2
        case ..<0.51: return 3
        default:      return 4
        }
    }

    private func trickWinSegment(_ v: Double) -> Int {
        switch v {
        case ..<0.31: return 0
        case ..<0.46: return 1
        case ..<0.61: return 2
        case ..<0.76: return 3
        default:      return 4
        }
    }

    // Generic 5-bucket helper for 0–1 rates mapped evenly
    private func rateSegment(_ v: Double) -> Int {
        switch v {
        case ..<0.21: return 0
        case ..<0.41: return 1
        case ..<0.61: return 2
        case ..<0.81: return 3
        default:      return 4
        }
    }
}
