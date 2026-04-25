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
    @Namespace private var cardNamespace
    @State private var pileExitCard: Card? = nil
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

                if showRules {
                    RulesDrawer(isPresented: $showRules)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .zIndex(10)
                }

                // Revolution full-screen overlay
                ZStack {
                    Color.black
                        .opacity(showRevolutionBanner ? 0.88 : 0)
                        .ignoresSafeArea()
                        .animation(.easeOut(duration: 0.25), value: showRevolutionBanner)
                    Color.tycoonPink
                        .opacity(showRevolutionBanner ? 0.10 : 0)
                        .ignoresSafeArea()
                        .animation(.easeOut(duration: 0.25), value: showRevolutionBanner)
                    VStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.tycoonPink)
                            .frame(height: 1.5)
                            .scaleEffect(x: showRevolutionBanner ? 1 : 0, anchor: .center)
                            .animation(.easeOut(duration: 0.4), value: showRevolutionBanner)
                        VStack(spacing: 10) {
                            Text("REVOLUTION")
                                .font(.custom("Fraunces-9ptBlackItalic", size: 68))
                                .foregroundStyle(Color.white)
                                .shadow(color: Color.tycoonPink, radius: 40, x: 0, y: 0)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text("RANK ORDER INVERTED")
                                .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                                .foregroundStyle(Color.tycoonPink.opacity(0.85))
                                .tracking(4)
                        }
                        .padding(.vertical, 22)
                        .scaleEffect(showRevolutionBanner ? 1 : 0.75)
                        .opacity(showRevolutionBanner ? 1 : 0)
                        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showRevolutionBanner)
                        Rectangle()
                            .fill(Color.tycoonPink)
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

                // Counter-Revolution full-screen overlay
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

                // 3♠ Reversal compact pill
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.cardBlush.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .opacity(showReversalBanner ? 1 : 0)
                    .scaleEffect(showReversalBanner ? 1 : 0.88)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showReversalBanner)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .zIndex(20)

                // 8-Stop compact pill
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.cardMint.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .opacity(showEightStopBanner ? 1 : 0)
                    .scaleEffect(showEightStopBanner ? 1 : 0.88)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showEightStopBanner)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .zIndex(20)

                // Bankruptcy compact pill
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.cardCream.opacity(0.25), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .opacity(showBankruptcyOverlay ? 1 : 0)
                    .scaleEffect(showBankruptcyOverlay ? 1 : 0.88)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showBankruptcyOverlay)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .zIndex(20)

                // Trick-winner compact pill
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .opacity(showTrickWinnerOverlay ? 1 : 0)
                    .scaleEffect(showTrickWinnerOverlay ? 1 : 0.88)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showTrickWinnerOverlay)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(false)
                .zIndex(19)
            }
            .allowsHitTesting(controller.pendingRoundResult == nil && !isAnyOverlayShowing)
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
        }
        .onChange(of: controller.reversalEventCounter) { _, _ in
            // Block AI immediately; delay the banner so the 3♠ can land on the pile first.
            pendingEventOverlay = true
            controller.extendOverlayBlock(for: 2.2)
            Task {
                try? await Task.sleep(nanoseconds: 650_000_000)
                showReversalBanner = true
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                showReversalBanner = false
                pendingEventOverlay = false
            }
        }
        .onChange(of: controller.revolutionEventCounter) { _, _ in
            pendingEventOverlay = true
            controller.extendOverlayBlock(for: 3.0)
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                showRevolutionBanner = true
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showRevolutionBanner = false
                pendingEventOverlay = false
            }
        }
        .onChange(of: controller.counterRevolutionEventCounter) { _, _ in
            pendingEventOverlay = true
            controller.extendOverlayBlock(for: 3.0)
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                showCounterRevolutionBanner = true
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showCounterRevolutionBanner = false
                pendingEventOverlay = false
            }
        }
        .onChange(of: controller.eightStopEventCounter) { _, _ in
            // Short delay so the 8 lands and the trick-reset fade plays before the pill appears.
            pendingEventOverlay = true
            controller.extendOverlayBlock(for: 2.0)
            Task {
                try? await Task.sleep(nanoseconds: 450_000_000)
                showEightStopBanner = true
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                showEightStopBanner = false
                pendingEventOverlay = false
            }
        }
        .onChange(of: controller.bankruptcyEventCounter) { _, _ in
            let name: String
            if let id = controller.bankruptedPlayerID,
               let player = controller.state.players.first(where: { $0.id == id }) {
                name = id == controller.humanPlayerID ? "You" : player.displayName
            } else {
                name = "Millionaire"
            }
            bankruptcyNameText = "\(name) bankrupt"
            controller.extendOverlayBlock(for: 1.8)
            showBankruptcyOverlay = true
            Task {
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                showBankruptcyOverlay = false
            }
        }
        .onChange(of: controller.trickResetCounter) { _, _ in
            // Show the trigger card (or last trick card) in the pile immediately — no fade yet.
            if let card = controller.trickResetLastTopCard {
                pileExitCard = card
                pileExitAnimating = false
            }
            // Trick winner label
            let winnerID = controller.trickWinnerID
            let isHuman = winnerID == controller.humanPlayerID
            if isHuman {
                trickWinnerText = "Your lead"
            } else if let id = winnerID,
                      let player = controller.state.players.first(where: { $0.id == id }) {
                trickWinnerText = "\(player.displayName) leads"
            }
            controller.extendOverlayBlock(for: 2.0)
            Task {
                try? await Task.sleep(nanoseconds: 150_000_000)
                // If an event banner is pending (8-stop, reversal) hold the pile card
                // visible for the full notification window, then fade it out quietly.
                guard !pendingEventOverlay && !showReversalBanner && !showRevolutionBanner && !showEightStopBanner else {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    withAnimation(.easeOut(duration: 0.3)) { pileExitAnimating = true }
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    pileExitCard = nil
                    pileExitAnimating = false
                    return
                }
                // Normal trick reset: fade the last card while showing the trick-winner pill.
                withAnimation(.easeOut(duration: 0.25)) { pileExitAnimating = true }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showTrickWinnerOverlay = true
                }
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    showTrickWinnerOverlay = false
                }
                try? await Task.sleep(nanoseconds: 350_000_000)
                pileExitCard = nil
                pileExitAnimating = false
            }
        }
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

    private var pileHint: String {
        guard let top = pileTopHand else { return "Lead any hand" }
        if top.isSoloJoker || top.isDoubleJoker {
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
            Text("ROUND \(controller.state.round) / \(controller.maxRounds)")
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
        let emojis = ["🎩", "😏", "😤", "🤖", "🦊"]
        return HStack(spacing: 0) {
            ForEach(Array(opponents.enumerated()), id: \.element.id) { index, opp in
                OpponentPanel(
                    player: opp,
                    tint: tints[index % tints.count],
                    emoji: emojis[index % emojis.count],
                    isActive: controller.activePlayer.id == opp.id,
                    aiPlayCount: controller.aiPlayCountByID[opp.id] ?? 0,
                    pendingCard: controller.pendingAIPlay?.playerID == opp.id
                        ? controller.pendingAIPlay?.card : nil,
                    cardNamespace: cardNamespace
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
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.094, green: 0.094, blue: 0.094))
                    .frame(width: 96, height: 136)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -4, y: 4)

                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.102, green: 0.102, blue: 0.102))
                    .frame(width: 96, height: 136)
                    .rotationEffect(.degrees(-2))
                    .offset(x: 2, y: 1)

                if let top = pileTopHand, let card = top.cards.first {
                    PlayingCardView(card: card, style: .pile)
                        .matchedGeometryEffect(id: card, in: cardNamespace, isSource: false)
                        .id(card)
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.cardCream)
                        .frame(width: 96, height: 136)
                        .overlay(
                            Text("—")
                                .font(.custom("Fraunces-9ptBlackItalic", size: 34))
                                .foregroundStyle(Color.cardSuitBlack.opacity(0.3))
                        )
                }

                if let card = pileExitCard {
                    PlayingCardView(card: card, style: .pile)
                        .scaleEffect(pileExitAnimating ? 0.8 : 1.0)
                        .opacity(pileExitAnimating ? 0 : 1.0)
                        .animation(.easeOut(duration: 0.25), value: pileExitAnimating)
                        .transition(.scale(scale: 0.82).combined(with: .opacity))
                        .allowsHitTesting(false)
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
                Text(isBankrupt ? "Bankrupt" : (controller.humanPlayer?.displayTitle?.displayName ?? "—"))
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
        // Tag the first card as the geometry source BEFORE the state update so
        // matchedGeometryEffect can fly it from the hand to the pile.
        flyCard = cards.first
        do {
            try withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                try controller.play(cards)
                selected.removeAll()
            }
            Task { await controller.resolveAITurnsIfNeeded() }
        } catch {
            flyCard = nil
            triggerInvalidShake()
        }
    }

    private func pass() {
        guard controller.canPass else { return }
        do {
            try controller.pass()
            selected.removeAll()
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
