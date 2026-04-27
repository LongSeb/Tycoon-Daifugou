import SwiftUI

// MARK: - Mock Data Helpers

private func makeTycoonStats() -> ExtendedStatsData {
    ExtendedStatsData(
        totalGamesPlayed: 32,
        passRate: 0.18,
        earlyFinisherRate: 0.72,
        comebackRate: 0.35,
        sweepRate: 0.22,
        cardHoardingIndex: 0.20,
        trickWinRate: 0.74,
        jokerEfficiency: 0.62,
        avgRevolutionsPerGame: 0.9,
        aggressionAxis: 0.82,
        earlyAxis: 0.72,
        riskAxis: 0.18,
        consistencyAxis: 0.85,
        archetype: .tycoon,
        archetypeEmoji: "👑",
        archetypeDescription: "Methodical and consistent. You play efficiently, shed cards early, and rarely take unnecessary risks."
    )
}

private func makeGamblerStats() -> ExtendedStatsData {
    ExtendedStatsData(
        totalGamesPlayed: 18,
        passRate: 0.14,
        earlyFinisherRate: 0.61,
        comebackRate: 0.28,
        sweepRate: 0.12,
        cardHoardingIndex: 0.31,
        trickWinRate: 0.59,
        jokerEfficiency: 0.78,
        avgRevolutionsPerGame: 3.2,
        aggressionAxis: 0.86,
        earlyAxis: 0.61,
        riskAxis: 0.74,
        consistencyAxis: 0.28,
        archetype: .gambler,
        archetypeEmoji: "🎭",
        archetypeDescription: "High energy and unpredictable. You play aggressively and love a revolution, but results can vary wildly."
    )
}

private func makeInsufficientStats() -> ExtendedStatsData {
    ExtendedStatsData(
        totalGamesPlayed: 1,
        passRate: 0, earlyFinisherRate: 0, comebackRate: 0,
        sweepRate: 0, cardHoardingIndex: 0, trickWinRate: 0,
        jokerEfficiency: 0, avgRevolutionsPerGame: 0,
        aggressionAxis: 0, earlyAxis: 0, riskAxis: 0, consistencyAxis: 0.5,
        archetype: .hoarder, archetypeEmoji: "🐢",
        archetypeDescription: ""
    )
}

// MARK: - Previews

#Preview("The Tycoon — Rich data") {
    ScrollView {
        ExtendedStatsView(stats: makeTycoonStats())
    }
    .background(Color.tycoonSurface)
    .preferredColorScheme(.dark)
}

#Preview("The Gambler — Rich data") {
    ScrollView {
        ExtendedStatsView(stats: makeGamblerStats())
    }
    .background(Color.tycoonSurface)
    .preferredColorScheme(.dark)
}

#Preview("Insufficient data (1 game)") {
    ScrollView {
        ExtendedStatsView(stats: makeInsufficientStats())
    }
    .background(Color.tycoonSurface)
    .preferredColorScheme(.dark)
}
