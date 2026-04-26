import SwiftUI
import TycoonDaifugouKit

// MARK: - Sample states

private extension CardExchangeState {
    /// Human is Millionaire — selects 2 cards to give to Beggar.
    static let millionaire = CardExchangeState(
        humanLastRank: .millionaire,
        opponentName: "Hana",
        opponentTitle: "Beggar",
        cardsToGive: [],
        cardsReceived: [.regular(.ace, .spades), .regular(.two, .hearts)],
        requiredGiveCount: 2,
        engineAllowsSelection: true
    )

    /// Human is Beggar — informational, 2 strongest auto-given to Millionaire.
    static let beggar = CardExchangeState(
        humanLastRank: .beggar,
        opponentName: "Ryo",
        opponentTitle: "Millionaire",
        cardsToGive: [.regular(.ace, .clubs), .regular(.two, .diamonds)],
        cardsReceived: [.regular(.three, .hearts), .regular(.four, .spades)],
        requiredGiveCount: 2,
        engineAllowsSelection: false
    )

    /// Human is Rich — selects 1 card to give to Poor.
    static let rich = CardExchangeState(
        humanLastRank: .rich,
        opponentName: "Kai",
        opponentTitle: "Poor",
        cardsToGive: [],
        cardsReceived: [.regular(.king, .diamonds)],
        requiredGiveCount: 1,
        engineAllowsSelection: true
    )
}

private let millionaireHand: [Card] = [
    .regular(.three, .clubs), .regular(.four, .diamonds), .regular(.five, .hearts),
    .regular(.seven, .spades), .regular(.eight, .clubs), .regular(.nine, .diamonds),
    .regular(.ten, .hearts), .regular(.jack, .spades), .regular(.queen, .clubs),
    .regular(.king, .hearts), .regular(.ace, .diamonds), .regular(.two, .clubs),
]

private let richHand: [Card] = [
    .regular(.three, .spades), .regular(.five, .clubs), .regular(.eight, .diamonds),
    .regular(.jack, .hearts), .regular(.queen, .spades), .regular(.king, .clubs),
    .regular(.ace, .hearts),
]

// MARK: - Previews

#Preview("Millionaire — choose 2 to give") {
    CardExchangeView(
        exchange: .millionaire,
        humanHand: millionaireHand,
        onConfirm: { _ in }
    )
}

#Preview("Beggar — informational") {
    CardExchangeView(
        exchange: .beggar,
        humanHand: [],
        onConfirm: { _ in }
    )
}

#Preview("Rich — choose 1 to give") {
    CardExchangeView(
        exchange: .rich,
        humanHand: richHand,
        onConfirm: { _ in }
    )
}
