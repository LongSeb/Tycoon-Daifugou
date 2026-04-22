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

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tycoonBlack.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                    opponentZone
                    playPile
                    playerStatusTag
                    handHeader
                    fanHand
                    actionButtons
                }
                .padding(.bottom, 40)
            }

            if showRules {
                RulesDrawer(isPresented: $showRules)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(10)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: showRules)
        .preferredColorScheme(.dark)
        .task { await controller.resolveAITurnsIfNeeded() }
        .onChange(of: controller.isGameOver) { _, isOver in
            guard isOver, !didNotifyGameEnd else { return }
            didNotifyGameEnd = true
            onGameEnded?(controller)
        }
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
        if let top = pileTopHand {
            return "\(top.type.displayName) · Beat with \(top.rank.rawValue > 14 ? "2" : "\(top.rank.rawValue)")+"
        }
        return "Lead any hand"
    }

    // MARK: Top Bar

    private var topBar: some View {
        HStack {
            if let onExitRequest {
                Button(action: onExitRequest) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Circle())
                }
            }
            Text("Tycoon Daifugō")
                .font(.custom("Fraunces-9ptBlackItalic", size: 14))
                .foregroundStyle(Color.white.opacity(0.55))
                .tracking(-0.2)
            Spacer()
            Text("ROUND \(controller.state.round) / \(controller.maxRounds)")
                .font(.custom("InstrumentSans-Regular", size: 9).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.3))
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
        .frame(height: 200)
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
                .font(.custom("InstrumentSans-Regular", size: 8).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.2))
                .tracking(2.5)

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.094, green: 0.094, blue: 0.094))
                    .frame(width: 68, height: 96)
                    .rotationEffect(.degrees(-6))
                    .offset(x: -3, y: 3)

                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(red: 0.102, green: 0.102, blue: 0.102))
                    .frame(width: 68, height: 96)
                    .rotationEffect(.degrees(-2))
                    .offset(x: 1, y: 1)

                if let top = pileTopHand, let card = top.cards.first {
                    PlayingCardView(card: card, style: .pile)
                } else {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.133, green: 0.133, blue: 0.133))
                        .frame(width: 68, height: 96)
                        .overlay(
                            Text("—")
                                .font(.custom("Fraunces-9ptBlackItalic", size: 22))
                                .foregroundStyle(Color.white.opacity(0.2))
                        )
                }
            }

            Text(pileHint)
                .font(.custom("InstrumentSans-Regular", size: 11).weight(.medium))
                .foregroundStyle(Color.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    // MARK: Player Status Tag

    private var playerStatusTag: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                Text("RANK")
                    .font(.custom("InstrumentSans-Regular", size: 7).weight(.semibold))
                    .foregroundStyle(Color.cardBlush.opacity(0.5))
                    .tracking(1)
                Text(controller.humanPlayer?.currentTitle?.displayName ?? "—")
                    .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1, height: 28)

            VStack(alignment: .leading, spacing: 1) {
                Text("CARDS LEFT")
                    .font(.custom("InstrumentSans-Regular", size: 7).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .tracking(1)
                Text("\(controller.humanHand.count)")
                    .font(.custom("Fraunces-9ptBlackItalic", size: 15))
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.tycoonSurface)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.cardBlush.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .padding(.leading, 16)
        .padding(.bottom, 4)
    }

    // MARK: Hand Header

    private var handHeader: some View {
        HStack {
            HStack(spacing: 5) {
                Circle()
                    .fill(controller.isHumansTurn ? Color.cardBlush : Color.white.opacity(0.2))
                    .frame(width: 6, height: 6)
                Text(controller.isHumansTurn ? "YOUR TURN" : "WAITING…")
                    .font(.custom("InstrumentSans-Regular", size: 10).weight(.semibold))
                    .foregroundStyle(controller.isHumansTurn ? Color.cardBlush : Color.white.opacity(0.3))
                    .tracking(1.5)
            }
            Spacer()
            HStack(spacing: 6) {
                Button(action: { showRules = true }) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                            .frame(width: 22, height: 22)
                        Text("?")
                            .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
                Text("\(controller.humanHand.count) cards")
                    .font(.custom("InstrumentSans-Regular", size: 10).weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.28))
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
            let cardW: CGFloat = 52
            let cardH: CGFloat = 76
            let maxAngle: CGFloat = n <= 7 ? 22 : 30
            let pivotDistance: CGFloat = n <= 7 ? 200 : 130
            let centerX = geo.size.width / 2
            let pivotY = cardH + pivotDistance

            ZStack {
                ForEach(Array(hand.enumerated()), id: \.element) { i, card in
                    let pct = n > 1 ? Double(i) / Double(n - 1) : 0.5
                    let angle = -maxAngle + CGFloat(pct) * maxAngle * 2
                    let rad = angle * .pi / 180
                    let x = centerX + pivotDistance * sin(rad) - cardW / 2
                    let y = pivotY - pivotDistance * cos(rad) - cardH
                    let isSelected = selected.contains(card)
                    let liftY: CGFloat = isSelected ? -20 : 0

                    PlayingCardView(card: card, style: .hand, isSelected: isSelected)
                        .position(x: x + cardW / 2, y: y - liftY + cardH / 2)
                        .rotationEffect(.degrees(Double(angle)))
                        .zIndex(isSelected ? 20 : Double(i))
                        .onTapGesture { toggle(card) }
                }
            }
            .frame(width: geo.size.width, height: cardH + pivotDistance * 0.35)
            .offset(x: invalidPlayShake)
        }
        .frame(height: 130)
        .padding(.horizontal, 8)
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        HStack {
            Button("PASS") { pass() }
                .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                .foregroundStyle(controller.canPass ? Color.textPrimary : Color.textTertiary)
                .tracking(1)
                .frame(height: 40)
                .padding(.horizontal, 18)
                .background(Color.white.opacity(0.05))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.09), lineWidth: 1))
                .clipShape(Capsule())
                .disabled(!controller.canPass)

            Spacer()

            Button(action: play) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.tycoonBlack)
            }
            .frame(width: 48, height: 48)
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
