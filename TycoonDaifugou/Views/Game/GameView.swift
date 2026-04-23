import SwiftUI
import TycoonDaifugouKit

struct GameView: View {
    @Bindable var controller: GameController
    var onExitRequest: (() -> Void)? = nil
    var onGameEnded: ((GameController) -> Void)? = nil

    @State private var showRules = false
    @State private var selected: Set<Card> = []
    @State private var invalidPlayShake: CGFloat = 0
    @State private var didNotifyGameEnd = false
    @State private var showReversalBanner = false
    @State private var showRevolutionBanner = false
    @State private var showEightStopBanner = false

    var body: some View {
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

            if showReversalBanner {
                reversalBanner
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(20)
            }

            if showRevolutionBanner {
                revolutionBanner
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(20)
            }

            if showEightStopBanner {
                eightStopBanner
                    .transition(.opacity.combined(with: .scale(scale: 0.92)))
                    .zIndex(20)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showRules)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showReversalBanner)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showRevolutionBanner)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showEightStopBanner)
        .preferredColorScheme(.dark)
        .task { await controller.resolveAITurnsIfNeeded() }
        .onChange(of: controller.isGameOver) { _, isOver in
            guard isOver, !didNotifyGameEnd else { return }
            didNotifyGameEnd = true
            onGameEnded?(controller)
        }
        .onChange(of: controller.reversalEventCounter) { _, _ in
            showReversalBanner = true
            Task {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                showReversalBanner = false
            }
        }
        .onChange(of: controller.revolutionEventCounter) { _, _ in
            showRevolutionBanner = true
            Task {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                showRevolutionBanner = false
            }
        }
        .onChange(of: controller.eightStopEventCounter) { _, _ in
            showEightStopBanner = true
            Task {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                showEightStopBanner = false
            }
        }
    }

    // MARK: 3-Spade Reversal Banner

    private var reversalBanner: some View {
        VStack(spacing: 6) {
            Text("3♠ REVERSAL")
                .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                .foregroundStyle(Color.tycoonBlack)
                .tracking(2.5)
            Text("Joker beaten")
                .font(.custom("Fraunces-9ptBlackItalic", size: 28))
                .foregroundStyle(Color.tycoonBlack)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Color.cardBlush)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.cardBlush.opacity(0.4), radius: 24, x: 0, y: 0)
    }

    // MARK: Revolution Banner

    private var revolutionBanner: some View {
        VStack(spacing: 6) {
            Text("REVOLUTION")
                .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                .foregroundStyle(Color.tycoonBlack)
                .tracking(2.5)
            Text(controller.state.isRevolutionActive ? "Strength flipped" : "Order restored")
                .font(.custom("Fraunces-9ptBlackItalic", size: 28))
                .foregroundStyle(Color.tycoonBlack)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Color.cardLavender)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.cardLavender.opacity(0.4), radius: 24, x: 0, y: 0)
        .rotation3DEffect(
            .degrees(showRevolutionBanner ? 0 : 180),
            axis: (x: 1, y: 0, z: 0)
        )
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: showRevolutionBanner)
    }

    // MARK: 8-Stop Banner

    private var eightStopBanner: some View {
        VStack(spacing: 6) {
            Text("8-STOP")
                .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                .foregroundStyle(Color.tycoonBlack)
                .tracking(2.5)
            Text("Trick reset")
                .font(.custom("Fraunces-9ptBlackItalic", size: 28))
                .foregroundStyle(Color.tycoonBlack)
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 16)
        .background(Color.cardMint)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.cardMint.opacity(0.4), radius: 24, x: 0, y: 0)
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
                    isActive: controller.activePlayer.id == opp.id
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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("RANK")
                    .font(.custom("InstrumentSans-Regular", size: 9).weight(.semibold))
                    .foregroundStyle(Color.cardBlush.opacity(0.6))
                    .tracking(1)
                Text(controller.humanPlayer?.displayTitle?.displayName ?? "—")
                    .font(.custom("InstrumentSans-Regular", size: 15).weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
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

                    PlayingCardView(card: card, style: .hand, isSelected: isSelected)
                        .position(x: x + cardW / 2, y: y + liftOffset + cardH / 2)
                        .rotationEffect(.degrees(Double(angle)))
                        .zIndex(isSelected ? 20 : Double(i))
                        .onTapGesture { toggle(card) }
                }
            }
            .frame(width: geo.size.width, height: cardH + lift + 16)
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
        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            if selected.contains(card) {
                selected.remove(card)
            } else {
                selected.insert(card)
            }
        }
    }

    private func play() {
        let cards = Array(selected)
        do {
            try controller.play(cards)
            selected.removeAll()
            Task { await controller.resolveAITurnsIfNeeded() }
        } catch {
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
