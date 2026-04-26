import SwiftUI
import TycoonDaifugouKit

struct GameView: View {
    @Bindable var controller: GameController
    var onExitRequest: (() -> Void)? = nil
    var onGameEnded: ((GameController) -> Void)? = nil

    @State private var showRules = false
    @State private var selected: Set<Card> = []
    @State private var invalidPlayShake: CGFloat = 0
    @State private var showReversalBanner = false
    @State private var showRevolutionBanner = false
    @State private var showCounterRevolutionBanner = false
    @State private var showEightStopBanner = false
    @State private var showTycoonBanner = false
    @Namespace private var cardNamespace
    @State private var pileExitAnimating = false
    @State private var showBankruptcyOverlay = false
    @State private var bankruptcyNameText = ""
    @State private var showTrickWinnerOverlay = false
    @State private var trickWinnerText = ""
    /// The lead card currently flying from hand to pile via matchedGeometryEffect.
    @State private var flyCard: Card? = nil
    /// True from the moment an event fires until the event banner fully hides,
    /// including the pre-banner delay while the card lands on the pile.
    @State private var pendingEventOverlay = false

    var body: some View {
        ZStack {
            ZStack(alignment: .bottom) {
                Color.tycoonBlack.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    opponentZone
                    playPile
                    Spacer(minLength: 0)
                    playerStatusTag
                    handHeader
                    fanHand
                    actionButtons
                }

                RulesDrawer(isPresented: $showRules)
                    .zIndex(10)

                revolutionOverlay
                counterRevolutionOverlay
                tycoonOverlay
                eventPills
            }
            .allowsHitTesting(
                controller.pendingRoundResult == nil
                    && controller.pendingExchange == nil
                    && !isAnyOverlayShowing
            )
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showRules)
            .preferredColorScheme(.dark)
            .task { await controller.resolveAITurnsIfNeeded() }

            if let result = controller.pendingRoundResult {
                InterRoundResultsView(result: result, isLastRound: controller.isLastRound) {
                    if controller.isLastRound {
                        onGameEnded?(controller)
                    } else {
                        controller.continueToNextRound()
                    }
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: controller.pendingRoundResult != nil)
            }

            if let exchange = controller.pendingExchange {
                CardExchangeView(
                    exchange: exchange,
                    humanHand: controller.humanHand
                ) { cards in
                    controller.confirmExchange(selectedCards: cards)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.25), value: controller.pendingExchange != nil)
            }
        }
        .onChange(of: controller.reversalEventCounter) { _, _ in onReversalEvent() }
        .onChange(of: controller.revolutionEventCounter) { _, _ in onRevolutionEvent() }
        .onChange(of: controller.counterRevolutionEventCounter) { _, _ in onCounterRevolutionEvent() }
        .onChange(of: controller.eightStopEventCounter) { _, _ in onEightStopEvent() }
        .onChange(of: controller.humanTycoonEventCounter) { _, _ in onHumanTycoonEvent() }
        .onChange(of: controller.bankruptcyEventCounter) { _, _ in onBankruptcyEvent() }
        .onChange(of: controller.pendingRoundResult) { _, newValue in onRoundResultChange(newValue) }
        .onChange(of: controller.trickResetCounter) { _, _ in onTrickReset() }
    }

    // MARK: Event Handlers

    private func onReversalEvent() {
        pendingEventOverlay = true
        controller.extendOverlayBlock(for: 2.6)
        Task {
            try? await Task.sleep(nanoseconds: 650_000_000)
            showReversalBanner = true
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            showReversalBanner = false
            pendingEventOverlay = false
        }
    }

    private func onRevolutionEvent() {
        pendingEventOverlay = true
        controller.extendOverlayBlock(for: 3.0)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            HapticManager.revolution()
            SoundManager.shared.playRevolution()
            showRevolutionBanner = true
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showRevolutionBanner = false
            pendingEventOverlay = false
        }
    }

    private func onCounterRevolutionEvent() {
        pendingEventOverlay = true
        controller.extendOverlayBlock(for: 3.0)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            HapticManager.revolution()
            SoundManager.shared.playRevolution()
            showCounterRevolutionBanner = true
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showCounterRevolutionBanner = false
            pendingEventOverlay = false
        }
    }

    private func onHumanTycoonEvent() {
        pendingEventOverlay = true
        controller.extendOverlayBlock(for: 3.0)
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            HapticManager.revolution()
            showTycoonBanner = true
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            showTycoonBanner = false
            pendingEventOverlay = false
        }
    }

    private func onEightStopEvent() {
        pendingEventOverlay = true
        controller.extendOverlayBlock(for: 2.4)
        Task {
            try? await Task.sleep(nanoseconds: 450_000_000)
            showEightStopBanner = true
            HapticManager.eightStop()
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            showEightStopBanner = false
            pendingEventOverlay = false
        }
    }

    private func onBankruptcyEvent() {
        let name: String
        if let id = controller.bankruptedPlayerID,
           let player = controller.state.players.first(where: { $0.id == id }) {
            name = id == controller.humanPlayerID ? "You" : player.displayName
        } else {
            name = "Tycoon"
        }
        bankruptcyNameText = "\(name) bankrupt"
        controller.extendOverlayBlock(for: 1.8)
        showBankruptcyOverlay = true
        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            showBankruptcyOverlay = false
        }
    }

    private func onRoundResultChange(_ newValue: RoundResult?) {
        guard newValue != nil else { return }
        HapticManager.roundEnd()
        SoundManager.shared.playRoundEnd()
    }

    private func onTrickReset() {
        pileExitAnimating = false
        let winnerID = controller.trickWinnerID
        if winnerID == controller.humanPlayerID {
            trickWinnerText = "Your lead"
        } else if let id = winnerID,
                  let player = controller.state.players.first(where: { $0.id == id }) {
            trickWinnerText = "\(player.displayName) leads"
        }

        let hasEventBanner = pendingEventOverlay || showReversalBanner
            || showRevolutionBanner || showCounterRevolutionBanner || showEightStopBanner
        let preDelayNs: UInt64 = hasEventBanner ? 2_000_000_000 : 150_000_000
        controller.extendOverlayBlock(for: hasEventBanner ? 4.0 : 2.0)

        Task {
            try? await Task.sleep(nanoseconds: preDelayNs)
            withAnimation(.easeOut(duration: 0.25)) { pileExitAnimating = true }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showTrickWinnerOverlay = true }
            try? await Task.sleep(nanoseconds: 1_300_000_000)
            withAnimation(.easeOut(duration: 0.3)) { showTrickWinnerOverlay = false }
            try? await Task.sleep(nanoseconds: 350_000_000)
            controller.clearTrickResetExitHands()
            pileExitAnimating = false
        }
    }

    // MARK: Event Overlays

    private var revolutionOverlay: some View {
        ZStack {
            Color.black
                .opacity(showRevolutionBanner ? 0.88 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: showRevolutionBanner)
            Color.cardRed
                .opacity(showRevolutionBanner ? 0.10 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: showRevolutionBanner)
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color.cardRed)
                    .frame(height: 1.5)
                    .scaleEffect(x: showRevolutionBanner ? 1 : 0, anchor: .center)
                    .animation(.easeOut(duration: 0.4), value: showRevolutionBanner)
                VStack(spacing: 10) {
                    Text("REVOLUTION")
                        .font(.custom("Fraunces-9ptBlackItalic", size: 68))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.cardRed, radius: 40, x: 0, y: 0)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("RANK ORDER INVERTED")
                        .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                        .foregroundStyle(Color.cardRed.opacity(0.85))
                        .tracking(4)
                }
                .padding(.vertical, 22)
                .scaleEffect(showRevolutionBanner ? 1 : 0.75)
                .opacity(showRevolutionBanner ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showRevolutionBanner)
                Rectangle()
                    .fill(Color.cardRed)
                    .frame(height: 1.5)
                    .scaleEffect(x: showRevolutionBanner ? 1 : 0, anchor: .center)
                    .animation(.easeOut(duration: 0.4), value: showRevolutionBanner)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .allowsHitTesting(false)
        .zIndex(22)
    }

    private var tycoonOverlay: some View {
        ZStack {
            Color.black
                .opacity(showTycoonBanner ? 0.88 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: showTycoonBanner)
            Color.cardGold
                .opacity(showTycoonBanner ? 0.10 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: showTycoonBanner)
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color.cardGold)
                    .frame(height: 1.5)
                    .scaleEffect(x: showTycoonBanner ? 1 : 0, anchor: .center)
                    .animation(.easeOut(duration: 0.4), value: showTycoonBanner)
                VStack(spacing: 10) {
                    Text("TYCOON")
                        .font(.custom("Fraunces-9ptBlackItalic", size: 78))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.cardGold, radius: 40, x: 0, y: 0)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text("FIRST PLACE")
                        .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                        .foregroundStyle(Color.cardGold.opacity(0.85))
                        .tracking(4)
                }
                .padding(.vertical, 22)
                .scaleEffect(showTycoonBanner ? 1 : 0.75)
                .opacity(showTycoonBanner ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showTycoonBanner)
                Rectangle()
                    .fill(Color.cardGold)
                    .frame(height: 1.5)
                    .scaleEffect(x: showTycoonBanner ? 1 : 0, anchor: .center)
                    .animation(.easeOut(duration: 0.4), value: showTycoonBanner)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .allowsHitTesting(false)
        .zIndex(23)
    }

    private var counterRevolutionOverlay: some View {
        ZStack {
            Color.black
                .opacity(showCounterRevolutionBanner ? 0.88 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: showCounterRevolutionBanner)
            Color.cardLavender
                .opacity(showCounterRevolutionBanner ? 0.10 : 0)
                .ignoresSafeArea()
                .animation(.easeOut(duration: 0.25), value: showCounterRevolutionBanner)
            VStack(spacing: 0) {
                Spacer()
                Rectangle()
                    .fill(Color.cardLavender)
                    .frame(height: 1.5)
                    .scaleEffect(x: showCounterRevolutionBanner ? 1 : 0, anchor: .center)
                    .animation(.easeOut(duration: 0.4), value: showCounterRevolutionBanner)
                VStack(spacing: 10) {
                    Text("Counter\nRevolution")
                        .font(.custom("Fraunces-9ptBlackItalic", size: 58))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: Color.cardLavender, radius: 40, x: 0, y: 0)
                    Text("ORDER RESTORED")
                        .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                        .foregroundStyle(Color.cardLavender.opacity(0.85))
                        .tracking(4)
                }
                .padding(.vertical, 22)
                .scaleEffect(showCounterRevolutionBanner ? 1 : 0.75)
                .opacity(showCounterRevolutionBanner ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showCounterRevolutionBanner)
                Rectangle()
                    .fill(Color.cardLavender)
                    .frame(height: 1.5)
                    .scaleEffect(x: showCounterRevolutionBanner ? 1 : 0, anchor: .center)
                    .animation(.easeOut(duration: 0.4), value: showCounterRevolutionBanner)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
        }
        .allowsHitTesting(false)
        .zIndex(22)
    }

    private var eventPills: some View {
        ZStack {
            // 3♠ Reversal
            ZStack {
                VStack(spacing: 5) {
                    Text("Joker beaten")
                        .font(.custom("Fraunces-9ptBlackItalic", size: 38))
                        .foregroundStyle(Color.white)
                    Text("3♠ REVERSAL")
                        .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                        .foregroundStyle(Color.cardBlush.opacity(0.6))
                        .tracking(2.5)
                }
                .padding(.horizontal, 34)
                .padding(.vertical, 17)
                .background(Color.tycoonSurface)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.cardBlush.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.85), radius: 22, x: 0, y: 12)
                .opacity(showReversalBanner ? 1 : 0)
                .scaleEffect(showReversalBanner ? 1 : 0.88)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showReversalBanner)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(20)

            // 8-Stop
            ZStack {
                VStack(spacing: 5) {
                    Text("8-Stop")
                        .font(.custom("Fraunces-9ptBlackItalic", size: 38))
                        .foregroundStyle(Color.white)
                    Text("TURN OVER")
                        .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                        .foregroundStyle(Color.cardMint.opacity(0.7))
                        .tracking(2.5)
                }
                .padding(.horizontal, 34)
                .padding(.vertical, 17)
                .background(Color.tycoonSurface)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.cardMint.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.85), radius: 22, x: 0, y: 12)
                .opacity(showEightStopBanner ? 1 : 0)
                .scaleEffect(showEightStopBanner ? 1 : 0.88)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showEightStopBanner)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(20)

            // Bankruptcy
            ZStack {
                VStack(spacing: 5) {
                    Text(bankruptcyNameText)
                        .font(.custom("Fraunces-9ptBlackItalic", size: 34))
                        .foregroundStyle(Color.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("BANKRUPTCY")
                        .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                        .foregroundStyle(Color.cardCream.opacity(0.6))
                        .tracking(2.5)
                }
                .padding(.horizontal, 34)
                .padding(.vertical, 17)
                .background(Color.tycoonSurface)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.cardCream.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.85), radius: 22, x: 0, y: 12)
                .opacity(showBankruptcyOverlay ? 1 : 0)
                .scaleEffect(showBankruptcyOverlay ? 1 : 0.88)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showBankruptcyOverlay)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(20)

            // Trick winner
            ZStack {
                VStack(spacing: 5) {
                    Text("TRICK COMPLETE")
                        .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .tracking(2.5)
                    Text(trickWinnerText)
                        .font(.custom("Fraunces-9ptBlackItalic", size: 38))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 34)
                .padding(.vertical, 17)
                .background(Color.tycoonSurface)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.85), radius: 22, x: 0, y: 12)
                .opacity(showTrickWinnerOverlay ? 1 : 0)
                .scaleEffect(showTrickWinnerOverlay ? 1 : 0.88)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showTrickWinnerOverlay)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(19)
        }
        .allowsHitTesting(false)
    }

    // MARK: Revolution Active Pill

    private var revolutionActivePill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.cardLavender)
                .frame(width: 6, height: 6)
            Text("REVOLUTION")
                .font(.custom("InstrumentSans-Regular", size: 10).weight(.semibold))
                .foregroundStyle(Color.cardLavender)
                .tracking(1.5)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .strokeBorder(Color.cardLavender.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 999, style: .continuous))
    }

    // MARK: Derived data

    private var isAnyOverlayShowing: Bool {
        showReversalBanner || showRevolutionBanner || showCounterRevolutionBanner
            || showEightStopBanner || showBankruptcyOverlay || showTrickWinnerOverlay
            || showTycoonBanner
    }

    private var sortedHand: [Card] {
        controller.humanHand.sorted { lhs, rhs in
            switch (lhs.isJoker, rhs.isJoker) {
            case (true, true):  return false
            case (true, false): return false
            case (false, true): return true
            case (false, false):
                let lRank = lhs.rank!.rawValue
                let rRank = rhs.rank!.rawValue
                if lRank != rRank { return lRank < rRank }
                return suitOrder(lhs.suit!) < suitOrder(rhs.suit!)
            }
        }
    }

    private func suitOrder(_ suit: Suit) -> Int {
        switch suit {
        case .spades:   return 0
        case .hearts:   return 1
        case .diamonds: return 2
        case .clubs:    return 3
        }
    }

    private var pileTopHand: Hand? {
        controller.state.currentTrick.last
    }

    /// Subtle fan offsets so doubles/triples/quads visibly stack on the pile
    /// instead of collapsing to a single card. Singles render flat at center.
    private func stackOffset(index: Int, count: Int) -> (x: CGFloat, y: CGFloat, rotation: Double) {
        guard count > 1 else { return (0, 0, 0) }
        let center = CGFloat(index) - CGFloat(count - 1) / 2
        return (x: center * 7, y: center * 3, rotation: Double(center) * 2.5)
    }

    private struct PileCardSlot {
        var offsetX: CGFloat
        var offsetY: CGFloat
        var rotation: Double
        var zIndex: Double
    }

    /// Per-card layout for the current top hand. For "rank + wild" plays
    /// (mixed regulars + Jokers, or a double-Joker trump pair) the regular
    /// card(s) stack centrally on top and the Joker(s) poke out to the right
    /// behind them, so the rank being played stays visible. Pure regular and
    /// solo-Joker plays use the standard left-fan.
    private func pileLayout(for hand: Hand) -> [PileCardSlot] {
        let cards = hand.cards
        let count = cards.count
        guard count > 0 else { return [] }

        let jokerIndices = cards.indices.filter { cards[$0].isJoker }
        let regularIndices = cards.indices.filter { !cards[$0].isJoker }
        let isMixed = !jokerIndices.isEmpty && !regularIndices.isEmpty

        guard isMixed || hand.isDoubleJoker else {
            return cards.indices.map { index in
                let off = stackOffset(index: index, count: count)
                return PileCardSlot(offsetX: off.x, offsetY: off.y, rotation: off.rotation, zIndex: Double(index))
            }
        }

        // For double-Joker the first Joker is promoted to "primary" so the
        // right-poke style still reads as one-card-plus-wild visually.
        let primary: [Int] = isMixed ? regularIndices : [jokerIndices[0]]
        let satellite: [Int] = isMixed ? jokerIndices : Array(jokerIndices.dropFirst())

        var slots = Array(
            repeating: PileCardSlot(offsetX: 0, offsetY: 0, rotation: 0, zIndex: 0),
            count: count
        )

        // Tighter inner fan on the primary group so it doesn't crowd the Joker poke.
        let primaryCount = primary.count
        for (orderIndex, cardIndex) in primary.enumerated() {
            let center = CGFloat(orderIndex) - CGFloat(primaryCount - 1) / 2
            slots[cardIndex] = PileCardSlot(
                offsetX: center * 5,
                offsetY: center * 2,
                rotation: Double(center) * 2,
                zIndex: 10 + Double(orderIndex)
            )
        }

        // Satellite Jokers hang to the right, slightly tilted and behind the primary.
        for (orderIndex, cardIndex) in satellite.enumerated() {
            let step = CGFloat(orderIndex)
            slots[cardIndex] = PileCardSlot(
                offsetX: 22 + step * 8,
                offsetY: -3 - step,
                rotation: 9 + Double(orderIndex) * 3,
                zIndex: -1 - Double(orderIndex)
            )
        }

        return slots
    }

    /// Up to 2 most-recent prior plays in the current trick (excluding the top),
    /// ordered oldest → newest so SwiftUI z-orders them naturally behind the top.
    private var priorPeekHands: [Hand] {
        let trick = controller.state.currentTrick
        guard trick.count > 1 else { return [] }
        return Array(trick.dropLast().suffix(2))
    }

    /// Offset for a prior peek card. `stepsBack` is 1 for the most recent prior, 2 for the one before.
    private func priorPeekOffset(stepsBack: Int) -> (x: CGFloat, y: CGFloat, rotation: Double, opacity: Double) {
        let s = CGFloat(stepsBack)
        return (x: -s * 14, y: -s * 5, rotation: -Double(stepsBack) * 6, opacity: 1.0)
    }

    /// Static snapshot of the pile (priors + stacked top) used during the trick-reset
    /// fade-out so 8-stop / reversal plays still display their full multi-card stack.
    @ViewBuilder
    private func pileStack(hands: [Hand], applyMatchedGeometry: Bool) -> some View {
        let priors = hands.count > 1 ? Array(hands.dropLast().suffix(2)) : []
        ZStack {
            ForEach(Array(priors.enumerated()), id: \.element) { idx, hand in
                if let lead = hand.cards.first {
                    let stepsBack = priors.count - idx
                    let peek = priorPeekOffset(stepsBack: stepsBack)
                    PlayingCardView(card: lead, style: .pile)
                        .opacity(peek.opacity)
                        .offset(x: peek.x, y: peek.y)
                        .rotationEffect(.degrees(peek.rotation))
                        .zIndex(Double(-stepsBack))
                }
            }
            if let top = hands.last {
                let slots = pileLayout(for: top)
                ForEach(Array(top.cards.enumerated()), id: \.element) { index, card in
                    let slot = slots[index]
                    Group {
                        if index == 0 && applyMatchedGeometry {
                            PlayingCardView(card: card, style: .pile)
                                .matchedGeometryEffect(id: card, in: cardNamespace, isSource: false)
                                .id(card)
                        } else {
                            PlayingCardView(card: card, style: .pile)
                        }
                    }
                    .offset(x: slot.offsetX, y: slot.offsetY)
                    .rotationEffect(.degrees(slot.rotation))
                    .zIndex(slot.zIndex)
                }
            }
        }
    }

    private var pileHint: String {
        guard let top = pileTopHand else { return "Lead any hand" }
        if top.isDoubleJoker {
            return "\(top.type.displayName) · Unbeatable"
        }
        if top.isSoloJoker {
            let reversalRuleOn = controller.state.ruleSet.threeSpadeReversal
                && controller.state.ruleSet.jokers
            let humanHasThreeSpades = controller.humanHand.contains(.regular(.three, .spades))
            if reversalRuleOn && humanHasThreeSpades {
                return "\(top.type.displayName) · Beat with 3♠"
            }
            return "\(top.type.displayName) · Unbeatable"
        }
        let isRevolution = controller.state.isRevolutionActive
        let delta = isRevolution ? -1 : 1
        guard let nextRank = Rank(rawValue: top.rank.rawValue + delta) else {
            return "\(top.type.displayName) · Unbeatable"
        }
        let suffix = isRevolution ? "-" : "+"
        return "\(top.type.displayName) · Beat with \(nextRank.displayLabel)\(suffix)"
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            if let onExitRequest {
                Button(action: onExitRequest) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 32, height: 32)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            Text("Tycoon Daifugō")
                .font(.custom("Fraunces-9ptBlackItalic", size: 17))
                .foregroundStyle(Color.white.opacity(0.6))
                .tracking(-0.2)
            Spacer()
            Text("\(controller.difficulty.displayName.uppercased()) · ROUND \(controller.state.round) / \(controller.maxRounds)")
                .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.35))
                .tracking(2)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: Opponent Zone

    private var opponentZone: some View {
        let opponents = controller.opponentSeats
        let tints: [Color] = [
            Color(red: 0.078, green: 0.078, blue: 0.125),
            Color(red: 0.102, green: 0.063, blue: 0.094),
            Color(red: 0.055, green: 0.094, blue: 0.078),
        ]
        return HStack(spacing: 0) {
            ForEach(Array(opponents.enumerated()), id: \.element.id) { index, opp in
                OpponentPanel(
                    player: opp,
                    tint: tints[index % tints.count],
                    emoji: controller.emoji(for: opp.id),
                    isActive: controller.activePlayer.id == opp.id,
                    aiPlayCount: controller.aiPlayCountByID[opp.id] ?? 0,
                    pendingCard: controller.pendingAIPlay?.playerID == opp.id
                        ? controller.pendingAIPlay?.card : nil,
                    cardNamespace: cardNamespace,
                    isFirst: index == 0,
                    isLast: index == opponents.count - 1
                )
                if index < opponents.count - 1 {
                    Divider().background(Color.black.opacity(0.5))
                }
            }
        }
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.04), lineWidth: 1)
        )
        .padding(.horizontal, 12)
    }

    // MARK: Play Pile

    private var playPile: some View {
        VStack(spacing: 8) {
            Text("CURRENT PLAY")
                .font(.custom("InstrumentSans-Regular", size: 10).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.25))
                .tracking(2.5)

            ZStack {
                Color.clear
                    .frame(width: 140, height: 165)

                ForEach(Array(priorPeekHands.enumerated()), id: \.element) { idx, hand in
                    if let lead = hand.cards.first {
                        let stepsBack = priorPeekHands.count - idx
                        let peek = priorPeekOffset(stepsBack: stepsBack)
                        PlayingCardView(card: lead, style: .pile)
                            .opacity(peek.opacity)
                            .offset(x: peek.x, y: peek.y)
                            .rotationEffect(.degrees(peek.rotation))
                            .zIndex(Double(-stepsBack))
                            .transition(.opacity)
                            .allowsHitTesting(false)
                    }
                }

                if let top = pileTopHand {
                    let slots = pileLayout(for: top)
                    ForEach(Array(top.cards.enumerated()), id: \.element) { index, card in
                        let slot = slots[index]
                        Group {
                            if index == 0 {
                                PlayingCardView(card: card, style: .pile)
                                    .matchedGeometryEffect(id: card, in: cardNamespace, isSource: false)
                                    .id(card)
                            } else {
                                PlayingCardView(card: card, style: .pile)
                                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                            }
                        }
                        .offset(x: slot.offsetX, y: slot.offsetY)
                        .rotationEffect(.degrees(slot.rotation))
                        .zIndex(slot.zIndex)
                    }
                }

                if !controller.trickResetExitHands.isEmpty && controller.state.currentTrick.isEmpty {
                    pileStack(hands: controller.trickResetExitHands, applyMatchedGeometry: true)
                        .scaleEffect(pileExitAnimating ? 0.8 : 1.0)
                        .opacity(pileExitAnimating ? 0 : 1.0)
                        .animation(.easeOut(duration: 0.25), value: pileExitAnimating)
                        .allowsHitTesting(false)
                        .zIndex(100)
                }
            }

            Text(pileHint)
                .font(.custom("InstrumentSans-Regular", size: 15).weight(.medium))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    // MARK: Player Status Tag

    private var playerStatusTag: some View {
        HStack(spacing: 12) {
            statusBox
            Spacer(minLength: 8)
            if controller.state.isRevolutionActive {
                revolutionActivePill
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: controller.state.isRevolutionActive)
    }

    private var statusBox: some View {
        let isBankrupt = controller.humanPlayer?.isBankrupt == true
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("RANK")
                    .font(.custom("InstrumentSans-Regular", size: 9).weight(.semibold))
                    .foregroundStyle(Color.cardBlush.opacity(0.6))
                    .tracking(1)
                Text(isBankrupt ? "Bankrupt" : (controller.humanPlayer?.displayTitle?.displayName ?? "Commoner"))
                    .font(.custom("InstrumentSans-Regular", size: 15).weight(.semibold))
                    .foregroundStyle(isBankrupt ? Color.cardCream.opacity(0.8) : Color.textPrimary)
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("CARDS LEFT")
                    .font(.custom("InstrumentSans-Regular", size: 9).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.35))
                    .tracking(1)
                Text("\(controller.humanHand.count)")
                    .font(.custom("Fraunces-9ptBlackItalic", size: 19))
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.cardBlush.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: Hand Header

    private var handHeader: some View {
        HStack {
            HStack(spacing: 6) {
                Circle()
                    .fill(controller.isHumansTurn ? Color.cardBlush : Color.white.opacity(0.2))
                    .frame(width: 8, height: 8)
                Text(controller.isHumansTurn ? "YOUR TURN" : "WAITING…")
                    .font(.custom("InstrumentSans-Regular", size: 13).weight(.semibold))
                    .foregroundStyle(controller.isHumansTurn ? Color.cardBlush : Color.white.opacity(0.35))
                    .tracking(1.5)
            }
            Spacer()
            HStack(spacing: 8) {
                Button(action: { showRules = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                            .frame(width: 26, height: 26)
                        Text("?")
                            .font(.custom("InstrumentSans-Regular", size: 14).weight(.semibold))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                Text("\(controller.humanHand.count) cards")
                    .font(.custom("InstrumentSans-Regular", size: 13).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.35))
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: Fan Hand

    private var fanHand: some View {
        let hand = sortedHand
        let n = hand.count
        let isBankrupt = controller.humanPlayer?.isBankrupt == true

        return GeometryReader { geo in
            // Size must match PlayingCardView .hand intrinsic size (68×100).
            let cardW: CGFloat = 68
            let cardH: CGFloat = 100
            // Lift fully clears the hand so neighbors stay visible when a card is
            // selected — one card height plus a small air gap.
            let lift: CGFloat = 115
            let marginH: CGFloat = 12
            // Fan opens to ±5° at a full 14-card hand — angular step is shared
            // across hand sizes so a 14-card fan spans full width, and smaller
            // hands cluster proportionally tighter.
            let maxHand: CGFloat = 14
            let fullFanAngleDeg: CGFloat = 5
            let angleStepDeg: CGFloat = fullFanAngleDeg * 2 / (maxHand - 1)
            let maxAngleDeg: CGFloat = n > 1 ? angleStepDeg * CGFloat(n - 1) / 2 : 0
            let angleStepRad = angleStepDeg * .pi / 180

            // Pivot distance derived from available width so the full 14-card
            // hand fills the screen edge-to-edge minus marginH.
            let availableWidth = max(geo.size.width - 2 * marginH - cardW, 0)
            let spacing = availableWidth / (maxHand - 1)
            let pivotDistance = angleStepRad > 0 ? spacing / sin(angleStepRad) : 0

            let centerX = geo.size.width / 2
            // Anchor center card top at y = lift so selection has room to rise.
            let pivotY = cardH + pivotDistance + lift

            ZStack {
                ForEach(Array(hand.enumerated()), id: \.element) { i, card in
                    let pct = n > 1 ? Double(i) / Double(n - 1) : 0.5
                    let angle = -maxAngleDeg + CGFloat(pct) * maxAngleDeg * 2
                    let rad = angle * .pi / 180
                    let x = centerX + pivotDistance * sin(rad) - cardW / 2
                    let y = pivotY - pivotDistance * cos(rad) - cardH
                    let isSelected = selected.contains(card)
                    let liftOffset: CGFloat = isSelected ? -lift : 0

                    Group {
                        if card == flyCard {
                            PlayingCardView(card: card, style: .hand, isSelected: isSelected)
                                .matchedGeometryEffect(id: card, in: cardNamespace)
                        } else {
                            PlayingCardView(card: card, style: .hand, isSelected: isSelected)
                        }
                    }
                    .saturation(isBankrupt ? 0 : 1)
                    .opacity(isBankrupt ? 0.45 : 1)
                    .animation(.easeOut(duration: 0.5), value: isBankrupt)
                    .position(x: x + cardW / 2, y: y + liftOffset + cardH / 2)
                    .rotationEffect(.degrees(Double(angle)))
                    .zIndex(isSelected ? 20 : Double(i))
                    .onTapGesture { toggle(card) }
                }
            }
            .frame(width: geo.size.width, height: cardH + lift + 16)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: n)
            .offset(x: invalidPlayShake)
        }
        .frame(height: 235)
        .padding(.top, 8)
        .padding(.horizontal, 4)
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        HStack {
            Button("PASS") { pass() }
                .font(.custom("InstrumentSans-Regular", size: 13).weight(.semibold))
                .foregroundStyle(controller.canPass ? Color.textPrimary : Color.textTertiary)
                .tracking(1)
                .frame(height: 46)
                .padding(.horizontal, 22)
                .background(Color.white.opacity(0.05))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.09), lineWidth: 1))
                .clipShape(Capsule())
                .disabled(!controller.canPass)

            Spacer()

            Button(action: play) {
                Image(systemName: "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.tycoonBlack)
            }
            .frame(width: 54, height: 54)
            .background(playButtonEnabled ? Color.cardBlush : Color.cardBlush.opacity(0.25))
            .clipShape(Circle())
            .disabled(!playButtonEnabled)
            .opacity(selected.isEmpty ? 0 : 1)
            .animation(.easeInOut(duration: 0.15), value: selected.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var playButtonEnabled: Bool {
        controller.isHumansTurn && !selected.isEmpty && controller.canPlay(cards: Array(selected))
    }

    // MARK: Actions

    private func toggle(_ card: Card) {
        guard controller.isHumansTurn else { return }
        HapticManager.cardTap()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            if selected.contains(card) {
                selected.remove(card)
            } else {
                selected.insert(card)
            }
        }
    }

    private func play() {
        let cards = sortedHand.filter { selected.contains($0) }
        flyCard = cards.first
        do {
            try withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                try controller.play(cards)
                selected.removeAll()
            }
            HapticManager.cardPlay()
            SoundManager.shared.playCardPlay()
            Task { await controller.resolveAITurnsIfNeeded() }
        } catch {
            flyCard = nil
            HapticManager.cardPlayError()
            triggerInvalidShake()
        }
    }

    private func pass() {
        guard controller.canPass else { return }
        do {
            try controller.pass()
            selected.removeAll()
            HapticManager.pass()
            Task { await controller.resolveAITurnsIfNeeded() }
        } catch {
            triggerInvalidShake()
        }
    }

    private func triggerInvalidShake() {
        withAnimation(.default) { invalidPlayShake = -10 }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.25).delay(0.05)) {
            invalidPlayShake = 0
        }
    }
}
