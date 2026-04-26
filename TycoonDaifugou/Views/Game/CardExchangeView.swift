// Engine model: two trade types exist in the trading phase.
// mustGiveStrongest=true (beggar→millionaire, poor→rich): engine forces the N strongest cards
//   to be given — no human input possible. This dialog is informational only.
// mustGiveStrongest=false (millionaire→beggar, rich→poor): giver may choose any N cards.
//   When the human is the giver, this dialog is interactive: the player selects exactly N cards.

import SwiftUI
import TycoonDaifugouKit

struct CardExchangeView: View {
    let exchange: CardExchangeState
    let humanHand: [Card]
    let onConfirm: ([Card]) -> Void

    @State private var selectedCards: Set<Card> = []
    @State private var appeared = false

    private var sortedHand: [Card] {
        humanHand.sorted { tradingStrength($0) < tradingStrength($1) }
    }

    private func tradingStrength(_ card: Card) -> Int {
        switch card {
        case .joker: return Int.max
        case .regular(let rank, _): return rank.rawValue
        }
    }

    private var confirmEnabled: Bool {
        !exchange.engineAllowsSelection || selectedCards.count == exchange.requiredGiveCount
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer(minLength: 0)

                Text("CARD EXCHANGE")
                    .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.28))
                    .tracking(3)
                    .padding(.bottom, 20)

                giveSection
                    .padding(.bottom, 14)

                if exchange.humanLastRank == .millionaire || exchange.humanLastRank == .rich {
                    Text("Tip: Consider keeping your combos intact.")
                        .font(.custom("InstrumentSans-Regular", size: 13).italic())
                        .foregroundStyle(Color.textTertiary)
                        .padding(.bottom, 28)
                } else {
                    Spacer(minLength: 28)
                }

                receiveSection
                    .padding(.bottom, 40)

                Spacer(minLength: 0)

                ctaButton
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(.easeOut(duration: 0.35), value: appeared)
        }
        .onAppear {
            appeared = true
        }
    }

    // MARK: Give Section

    private var giveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Give \(exchange.requiredGiveCount) card\(exchange.requiredGiveCount == 1 ? "" : "s") to \(exchange.opponentName) (\(exchange.opponentTitle))")
                    .font(.custom("Fraunces-9ptBlackItalic", size: 28))
                    .foregroundStyle(Color.tycoonMint)

                if exchange.engineAllowsSelection {
                    Text("\(selectedCards.count) of \(exchange.requiredGiveCount) selected")
                        .font(.custom("InstrumentSans-Regular", size: 13).weight(.medium))
                        .foregroundStyle(
                            selectedCards.count == exchange.requiredGiveCount
                                ? Color.tycoonMint.opacity(0.8)
                                : Color.textTertiary
                        )
                        .animation(.easeOut(duration: 0.15), value: selectedCards.count)
                }
            }

            if exchange.engineAllowsSelection {
                // Interactive: full hand as selectable cards, hand-sized (68×100)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(sortedHand, id: \.self) { card in
                            let isSelected = selectedCards.contains(card)
                            let isFull = !isSelected && selectedCards.count >= exchange.requiredGiveCount
                            PlayingCardView(card: card, style: .hand, isSelected: isSelected)
                                .opacity(isFull ? 0.3 : 1.0)
                                .animation(.easeOut(duration: 0.12), value: isFull)
                                .onTapGesture {
                                    guard !isFull else { return }
                                    withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                                        if isSelected { selectedCards.remove(card) }
                                        else { selectedCards.insert(card) }
                                    }
                                }
                        }
                    }
                    .padding(.vertical, 2)
                    .padding(.horizontal, 1)
                }
            } else {
                // Informational: pre-selected cards, slightly larger (82×120)
                VStack(alignment: .leading, spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(exchange.cardsToGive, id: \.self) { card in
                                PlayingCardView(card: card, style: .hand)
                                    .scaleEffect(1.2)
                                    .frame(width: 82, height: 120)
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 1)
                    }
                    Text("Auto-selected (strongest cards)")
                        .font(.custom("InstrumentSans-Regular", size: 12))
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
    }

    // MARK: Receive Section

    private var receiveSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You received \(exchange.cardsReceived.count) card\(exchange.cardsReceived.count == 1 ? "" : "s") from \(exchange.opponentName)")
                .font(.custom("Fraunces-9ptBlackItalic", size: 28))
                .foregroundStyle(Color.textPrimary)

            // Received cards are always displayed at the larger size (82×120)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(exchange.cardsReceived, id: \.self) { card in
                        PlayingCardView(card: card, style: .hand)
                            .scaleEffect(1.2)
                            .frame(width: 82, height: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color.tycoonLav.opacity(0.65), lineWidth: 2)
                            )
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 1)
            }
        }
    }

    // MARK: CTA Button

    private var ctaButton: some View {
        Button {
            onConfirm(Array(selectedCards))
        } label: {
            Text("Confirm Exchange")
                .font(.custom("InstrumentSans-Regular", size: 15).weight(.semibold))
                .foregroundStyle(confirmEnabled ? Color.tycoonBlack : Color.tycoonBlack.opacity(0.4))
                .tracking(0.3)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(confirmEnabled ? Color.tycoonMint : Color.tycoonMint.opacity(0.3))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!confirmEnabled)
        .animation(.easeOut(duration: 0.15), value: confirmEnabled)
    }
}
