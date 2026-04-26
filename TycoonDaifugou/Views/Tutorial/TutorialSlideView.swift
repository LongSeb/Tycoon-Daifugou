import SwiftUI

// MARK: - Step content (view-layer only, no engine dependency)

extension TutorialStep {
    var title: String {
        switch self {
        case .welcome:         return "Welcome to Tycoon"
        case .cardStrength:    return "Card Strength"
        case .howATurnWorks:   return "Playing Cards"
        case .tricks:          return "Winning a Trick"
        case .ranksAndScoring: return "Ranks & Points"
        case .cardExchange:    return "The Card Exchange"
        case .revolution:      return "Revolution"
        case .specialCards:    return "Special Rules"
        case .strategyTip:     return "Quick Tips"
        case .youreReady:      return "You're Ready!"
        }
    }

    var body: String {
        switch self {
        case .welcome:
            return "Tycoon is a card shedding game for 2–8 players. Be the first to play all your cards and claim the top rank. The last player left holding cards becomes the Beggar."
        case .cardStrength:
            return "Cards rank from 3 (weakest) up through King, Ace, 2, and finally the Joker as the strongest card of all. Suits don't matter — only rank."
        case .howATurnWorks:
            return "On your turn, play the same number of cards as the previous player but at a higher rank. Singles beat singles, pairs beat pairs. Can't beat it? Tap Pass — but once you pass you're out until the next trick."
        case .tricks:
            return "When all other players pass, the last player who played cards wins the trick and leads the next one. The player with the 3 of Diamonds leads the very first trick of the game."
        case .ranksAndScoring:
            return "The order in which players empty their hands determines their rank for that round. Points accumulate across all 3 rounds — the highest total wins the game."
        case .cardExchange:
            return "At the start of rounds 2 and 3, ranks trade cards. The Beggar gives their 2 strongest to the Millionaire, who gives back any 2. The Poor gives their best card to the Rich, who gives back any 1."
        case .revolution:
            return "Play four cards of the same rank to trigger a Revolution — card strength flips completely. Now 3 is the strongest and 2 is the weakest. A second four-of-a-kind triggers a Counter-Revolution, restoring normal order."
        case .specialCards:
            return "These are house rules available in Custom Game mode. 8-Stop clears the table and gives you the lead. The Joker is the strongest card but can be countered by the 3 of Spades when played alone."
        case .strategyTip:
            return "Tycoon rewards patience. Don't burn your strongest cards too early. Track what's been played and time your big moves."
        case .youreReady:
            return "That's everything you need to know. Classic mode plays with base rules — try Custom Game once you're comfortable to unlock house rules and bigger tables."
        }
    }
}

// MARK: - Slide shell

struct TutorialSlideView: View {
    let step: TutorialStep
    /// Non-nil only for the last slide, where the CTA lives inside the slide content.
    var onComplete: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 0) {
            slideContent(for: step)
                .frame(maxWidth: .infinity)
                .frame(height: 280)
                .padding(.top, 80)  // clear the Skip button overlay

            Spacer().frame(height: 20)

            titleSection

            Spacer().frame(height: 12)

            Text(step.body)
                .font(.tycoonBody)
                .foregroundStyle(Color.textPrimary.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .fixedSize(horizontal: false, vertical: true)

            if let onComplete {
                Spacer().frame(height: 24)
                Button(action: onComplete) {
                    Text("Let's Play!")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color.tycoonBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.tycoonMint)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            Spacer(minLength: 56)  // room for page dots + Next button
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: 6) {
            Text(step.title)
                .font(.custom("Fraunces-9ptBlackItalic", size: 28))
                .foregroundStyle(Color.tycoonMint)
                .multilineTextAlignment(.center)

            if step.isHouseRule {
                Text("★ House Rule")
                    .font(.tycoonCaption)
                    .foregroundStyle(Color.tycoonLav)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.tycoonLav.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
    }

    @ViewBuilder
    private func slideContent(for step: TutorialStep) -> some View {
        switch step {
        case .welcome:         WelcomeSlide()
        case .cardStrength:    CardStrengthSlide()
        case .howATurnWorks:   HowATurnWorksSlide()
        case .tricks:          TricksSlide()
        case .ranksAndScoring: RanksAndScoringSlide()
        case .cardExchange:    CardExchangeSlide()
        case .revolution:      RevolutionSlide()
        case .specialCards:    SpecialCardsSlide()
        case .strategyTip:     StrategyTipSlide()
        case .youreReady:      YoureReadySlide()
        }
    }
}
