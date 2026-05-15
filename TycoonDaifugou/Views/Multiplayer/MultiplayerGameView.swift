import SwiftUI
import TycoonDaifugouKit

struct MultiplayerGameView: View {
    @Bindable var controller: MultiplayerGameController
    let onLeave: () -> Void

    @State private var motionManager = MotionManager()
    @State private var showLeaveConfirmation = false
    @State private var showAbandonedOverlay = false
    @State private var abandonCountdown = 5
    @State private var showRevolutionBanner = false
    @State private var revolutionBannerIsCounter = false
    @State private var showEightStopBanner = false
    @State private var lastKnownEightStopCount: Int = 0
    @State private var showThreeSpadeBanner = false
    @State private var showTrickWinnerOverlay = false
    @State private var trickWinnerText = ""
    @State private var pileExitCards: [[String]] = []
    @State private var pileExitAnimating = false
    @State private var prevTrick: [[String]] = []
    @State private var prevCurrentPlayerUID = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.tycoonBlack.ignoresSafeArea()

            if let state = controller.state {
                VStack(alignment: .leading, spacing: 0) {
                    topBar(state: state)
                    opponentZone(state: state)
                    playPile(state: state)
                    Spacer(minLength: 0)
                    actionArea(state: state)
                    fanHand
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .allowsHitTesting(!state.isFinished)

                revolutionOverlay
                eventPills
            } else {
                connectingView
            }

            if controller.state?.isFinished == true {
                gameOverOverlay
            }

            if showAbandonedOverlay {
                abandonedOverlay
            }
        }
        .environment(\.motionManager, motionManager)
        .onAppear {
            motionManager.start()
            controller.startListening()
        }
        .onDisappear {
            motionManager.stop()
            controller.stopListening()
        }
        .onChange(of: controller.state?.currentTrick) { old, new in
            onTrickChange(old: old ?? [], new: new ?? [])
        }
        .onChange(of: controller.state?.revolutionEventCount) { old, new in
            guard let old, let new, new > old else { return }
            // isRevolutionActive already reflects the new value in the same atomic update
            revolutionBannerIsCounter = !(controller.state?.isRevolutionActive ?? true)
            showRevolutionBanner = true
            HapticManager.revolution()
            Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                showRevolutionBanner = false
            }
        }
        .onChange(of: controller.state?.eightStopEventCount) { old, new in
            guard let old, let new, new > old else { return }
            lastKnownEightStopCount = new
            showEightStopBanner = true
            HapticManager.eightStop()
            Task {
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                showEightStopBanner = false
            }
        }
        .onChange(of: controller.state?.threeSpadeEventCount) { old, new in
            guard let old, let new, new > old else { return }
            showThreeSpadeBanner = true
            Task {
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                showThreeSpadeBanner = false
            }
        }
        .onChange(of: controller.isMyTurn) { _, isMyTurn in
            guard isMyTurn else { return }
            HapticManager.cardTap()
        }
        .onChange(of: controller.isAbandoned) { _, abandoned in
            guard abandoned else { return }
            showAbandonedOverlay = true
            abandonCountdown = 5
            Task {
                for i in stride(from: 4, through: 0, by: -1) {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    abandonCountdown = i
                }
                onLeave()
            }
        }
        .alert("Leave Game?", isPresented: $showLeaveConfirmation) {
            Button("Leave", role: .destructive) {
                Task { await controller.abandon() }
                onLeave()
            }
            Button("Stay", role: .cancel) {}
        } message: {
            Text("Leaving will end the game for all players.")
        }
        .alert("Error", isPresented: Binding(
            get: { controller.error != nil },
            set: { if !$0 { controller.clearError() } }
        )) {
            Button("OK", role: .cancel) { controller.clearError() }
        } message: {
            Text(controller.error ?? "")
        }
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
    }

    // MARK: - Top bar

    private func topBar(state: RTDBGameState) -> some View {
        HStack {
            Button { showLeaveConfirmation = true } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }
            Text("Tycoon Daifugō")
                .font(.custom("Fraunces-9ptBlackItalic", size: 17))
                .foregroundStyle(Color.white.opacity(0.6))
                .tracking(-0.2)
            Spacer()
            Text("ONLINE · ROUND \(state.round)")
                .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.35))
                .tracking(2)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Opponent zone

    private func opponentZone(state: RTDBGameState) -> some View {
        let opponents = state.playerOrder.filter { $0 != controller.myUID }
        let tints: [Color] = [
            Color(red: 0.078, green: 0.078, blue: 0.125),
            Color(red: 0.102, green: 0.063, blue: 0.094),
            Color(red: 0.055, green: 0.094, blue: 0.078),
        ]
        return HStack(spacing: 0) {
            ForEach(Array(opponents.enumerated()), id: \.element) { index, uid in
                mpOpponentPanel(uid: uid, state: state, tint: tints[index % tints.count],
                                isFirst: index == 0, isLast: index == opponents.count - 1)
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

    private func mpOpponentPanel(uid: String, state: RTDBGameState, tint: Color, isFirst: Bool, isLast: Bool) -> some View {
        let player = state.players[uid]
        let isActive = state.currentPlayerUid == uid
        let cardCount = player?.handSafe.count ?? 0
        let rankLabel = player?.finishRank.map { finishRankLabel($0, total: state.playerOrder.count).uppercased() } ?? "COMMONER"

        return ZStack(alignment: .top) {
            tint

            // Tag
            VStack(alignment: .leading, spacing: 1) {
                Text("CARDS LEFT")
                    .font(.custom("InstrumentSans-Regular", size: 7).weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.28))
                    .tracking(0.8)
                Text("\(cardCount)")
                    .font(.custom("Fraunces-9ptBlackItalic", size: 20))
                    .foregroundStyle(Color.textPrimary)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: cardCount)
                Text(rankLabel)
                    .font(.custom("InstrumentSans-Regular", size: 7).weight(.semibold))
                    .foregroundStyle(isActive ? Color.cardBlush : Color.white.opacity(0.3))
                    .tracking(0.4)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isActive ? Color(red: 0.098, green: 0.055, blue: 0.071) : Color.tycoonBlack)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isActive ? Color.cardBlush.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .padding(.top, 8)
            .padding(.horizontal, 5)

            // Avatar + card backs + name
            VStack(spacing: 3) {
                Circle()
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        Circle().strokeBorder(
                            isActive ? Color.cardBlush.opacity(0.4) : Color.white.opacity(0.08),
                            lineWidth: 1.5
                        )
                    )
                    .frame(width: 42, height: 42)
                    .overlay(Text("👤").font(.system(size: 18)))

                HStack(spacing: 2) {
                    ForEach(0..<min(cardCount, 5), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 2, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                            )
                            .frame(width: 10, height: 14)
                    }
                }

                Text((player?.displayName ?? uid).uppercased())
                    .font(.custom("InstrumentSans-Regular", size: 8).weight(.semibold))
                    .foregroundStyle(isActive ? Color.cardBlush.opacity(0.45) : Color.white.opacity(0.25))
                    .tracking(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(.bottom, 10)
        }
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: isFirst ? 16 : 0,
                bottomLeadingRadius: isFirst ? 16 : 0,
                bottomTrailingRadius: isLast ? 16 : 0,
                topTrailingRadius: isLast ? 16 : 0,
                style: .continuous
            )
            .strokeBorder(isActive ? Color.cardBlush.opacity(0.25) : Color.clear, lineWidth: 1.5)
        )
    }

    // MARK: - Play pile

    private func playPile(state: RTDBGameState) -> some View {
        let trick = state.currentTrickSafe
        let topPlay: [String]? = trick.last
        let priors = trick.count > 1 ? Array(trick.dropLast().suffix(2)) : []

        return VStack(spacing: 8) {
            Text("CURRENT PLAY")
                .font(.custom("InstrumentSans-Regular", size: 10).weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.25))
                .tracking(2.5)

            ZStack {
                Color.clear.frame(width: 140, height: 165)

                // Prior peek cards
                ForEach(Array(priors.enumerated()), id: \.offset) { idx, play in
                    if let cardStr = play.first, let card = Card(serverString: cardStr) {
                        let stepsBack = priors.count - idx
                        let s = CGFloat(stepsBack)
                        PlayingCardView(card: card, style: .pile)
                            .opacity(1.0)
                            .offset(x: -s * 14, y: -s * 5)
                            .rotationEffect(.degrees(-Double(stepsBack) * 6))
                            .zIndex(Double(-stepsBack))
                            .allowsHitTesting(false)
                    }
                }

                // Top play
                if let top = topPlay {
                    ForEach(Array(top.enumerated()), id: \.element) { index, cardStr in
                        if let card = Card(serverString: cardStr) {
                            let slot = pileSlot(index: index, cards: top)
                            PlayingCardView(card: card, style: .pile)
                                .offset(x: slot.x, y: slot.y)
                                .rotationEffect(.degrees(slot.rotation))
                                .zIndex(slot.z)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                }

                // Exit animation snapshot
                if !pileExitCards.isEmpty && trick.isEmpty {
                    pileExitSnapshot
                        .scaleEffect(pileExitAnimating ? 0.8 : 1.0)
                        .opacity(pileExitAnimating ? 0 : 1.0)
                        .animation(.easeOut(duration: 0.25), value: pileExitAnimating)
                        .allowsHitTesting(false)
                        .zIndex(100)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: trick.count)

            // Hint text
            Group {
                if let top = topPlay {
                    let jokerCount = top.filter { $0.hasPrefix("JKR") }.count
                    if jokerCount == top.count {
                        Text("\(top.count == 2 ? "Double Joker" : "Joker") · Unbeatable")
                    } else {
                        let rank = top.first(where: { !$0.hasPrefix("JKR") }).map { rankDisplay($0) } ?? "?"
                        Text("\(handTypeName(count: top.count)) · Beat with \(rank)+")
                    }
                } else {
                    Text(state.currentPlayerUid == controller.myUID ? "Lead any hand" : "Waiting for \(state.players[state.currentPlayerUid]?.displayName ?? "opponent")…")
                }
            }
            .font(.custom("InstrumentSans-Regular", size: 15).weight(.medium))
            .foregroundStyle(Color.white.opacity(0.45))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }

    @ViewBuilder
    private var pileExitSnapshot: some View {
        if let top = pileExitCards.last {
            ForEach(Array(top.enumerated()), id: \.element) { index, cardStr in
                if let card = Card(serverString: cardStr) {
                    let slot = pileSlot(index: index, cards: top)
                    PlayingCardView(card: card, style: .pile)
                        .offset(x: slot.x, y: slot.y)
                        .rotationEffect(.degrees(slot.rotation))
                        .zIndex(slot.z)
                }
            }
        }
    }

    // MARK: - Action area

    private func actionArea(state: RTDBGameState) -> some View {
        let myPlayer = state.players[controller.myUID]
        let myCardCount = myPlayer?.handSafe.count ?? 0
        let myRankLabel = myPlayer?.finishRank.map { finishRankLabel($0, total: state.playerOrder.count) } ?? "Commoner"
        let isMyTurn = controller.isMyTurn

        return HStack(alignment: .top, spacing: 16) {
            // LEFT: YOUR TURN + status + PASS
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(isMyTurn ? Color.cardBlush : Color.white.opacity(0.2))
                        .frame(width: 8, height: 8)
                    Text(isMyTurn ? "YOUR TURN" : "WAITING…")
                        .font(.custom("InstrumentSans-Regular", size: 13).weight(.semibold))
                        .foregroundStyle(isMyTurn ? Color.cardBlush : Color.white.opacity(0.35))
                        .tracking(1.5)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("RANK")
                            .font(.custom("InstrumentSans-Regular", size: 9).weight(.semibold))
                            .foregroundStyle(Color.cardBlush.opacity(0.6))
                            .tracking(1)
                        Text(myRankLabel)
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
                        Text("\(myCardCount)")
                            .font(.custom("Fraunces-9ptBlackItalic", size: 19))
                            .foregroundStyle(Color.textPrimary)
                            .contentTransition(.numericText())
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: myCardCount)
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

                if state.isRevolutionActive {
                    HStack(spacing: 6) {
                        Circle().fill(Color.cardLavender).frame(width: 6, height: 6)
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
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }

                Button("PASS") { Task { await controller.submitPass() } }
                    .font(.custom("InstrumentSans-Regular", size: 13).weight(.semibold))
                    .foregroundStyle(isMyTurn ? Color.textPrimary : Color.textTertiary)
                    .tracking(1)
                    .frame(height: 46)
                    .padding(.horizontal, 22)
                    .background(Color.white.opacity(0.05))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.09), lineWidth: 1))
                    .clipShape(Capsule())
                    .disabled(!isMyTurn || controller.isSubmitting)
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: state.isRevolutionActive)

            // RIGHT: card count + play button
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    Text("\(myCardCount) cards")
                        .font(.custom("InstrumentSans-Regular", size: 13).weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.35))
                }

                HStack {
                    Spacer(minLength: 0)
                    if controller.isSubmitting {
                        ProgressView()
                            .tint(Color.tycoonBlack)
                            .frame(width: 54, height: 54)
                            .background(Color.cardBlush.opacity(0.25))
                            .clipShape(Circle())
                    } else {
                        Button(action: { Task { await controller.submitPlay() } }) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Color.tycoonBlack)
                        }
                        .frame(width: 54, height: 54)
                        .background(playButtonEnabled ? Color.cardBlush : Color.cardBlush.opacity(0.25))
                        .clipShape(Circle())
                        .disabled(!playButtonEnabled)
                        .opacity(controller.selectedCards.isEmpty ? 0 : 1)
                        .animation(.easeInOut(duration: 0.15), value: controller.selectedCards.isEmpty)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    private var playButtonEnabled: Bool {
        controller.isMyTurn && !controller.selectedCards.isEmpty && !controller.isSubmitting
    }

    // MARK: - Fan hand

    private var fanHand: some View {
        let hand = sortedHand
        let n = hand.count

        return GeometryReader { geo in
            let cardW: CGFloat = 68
            let cardH: CGFloat = 100
            let lift: CGFloat = 115
            let marginH: CGFloat = 12
            let maxHand: CGFloat = 14
            let fullFanAngleDeg: CGFloat = 5
            let angleStepDeg: CGFloat = fullFanAngleDeg * 2 / (maxHand - 1)
            let maxAngleDeg: CGFloat = n > 1 ? angleStepDeg * CGFloat(n - 1) / 2 : 0
            let angleStepRad = angleStepDeg * .pi / 180

            let availableWidth = max(geo.size.width - 2 * marginH - cardW, 0)
            let spacing = availableWidth / (maxHand - 1)
            let pivotDistance = angleStepRad > 0 ? spacing / sin(angleStepRad) : 0

            let centerX = geo.size.width / 2
            let pivotY = cardH + pivotDistance + lift

            ZStack {
                ForEach(Array(hand.enumerated()), id: \.element) { i, cardStr in
                    let pct = n > 1 ? Double(i) / Double(n - 1) : 0.5
                    let angle = -maxAngleDeg + CGFloat(pct) * maxAngleDeg * 2
                    let rad = angle * .pi / 180
                    let x = centerX + pivotDistance * sin(rad) - cardW / 2
                    let y = pivotY - pivotDistance * cos(rad) - cardH
                    let isSelected = controller.selectedCards.contains(cardStr)
                    let liftOffset: CGFloat = isSelected ? -lift : 0

                    if let card = Card(serverString: cardStr) {
                        PlayingCardView(card: card, style: .hand, isSelected: isSelected)
                            .position(x: x + cardW / 2, y: y + liftOffset + cardH / 2)
                            .rotationEffect(.degrees(Double(angle)))
                            .zIndex(isSelected ? 20 : Double(i))
                            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: isSelected)
                            .onTapGesture {
                                guard controller.isMyTurn else { return }
                                HapticManager.cardTap()
                                controller.toggleCard(cardStr)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 12).onEnded { value in
                                    guard controller.isMyTurn else { return }
                                    let dy = value.translation.height
                                    if dy < -30 && !isSelected { controller.toggleCard(cardStr) }
                                    else if dy > 30 && isSelected { controller.toggleCard(cardStr) }
                                }
                            )
                    }
                }
            }
            .frame(width: geo.size.width, height: cardH + lift + 16)
            .animation(.spring(response: 0.3, dampingFraction: 0.75), value: n)
        }
        .frame(height: 235)
        .padding(.top, 6)
        .padding(.horizontal, 4)
    }

    // MARK: - Revolution overlay

    private var revolutionOverlay: some View {
        ZStack {
            Color.black.opacity(showRevolutionBanner ? 0.88 : 0).ignoresSafeArea()
            Color.cardRed.opacity(showRevolutionBanner ? 0.10 : 0).ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(Color.cardRed).frame(height: 1.5)
                    .scaleEffect(x: showRevolutionBanner ? 1 : 0, anchor: .center)
                    .animation(.easeOut(duration: 0.4), value: showRevolutionBanner)
                VStack(spacing: 10) {
                    Text(revolutionBannerIsCounter ? "COUNTER" : "REVOLUTION")
                        .font(.custom("Fraunces-9ptBlackItalic", size: 68))
                        .foregroundStyle(Color.white)
                        .shadow(color: Color.cardRed, radius: 40)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    if revolutionBannerIsCounter {
                        Text("REVOLUTION")
                            .font(.custom("Fraunces-9ptBlackItalic", size: 42))
                            .foregroundStyle(Color.white)
                            .shadow(color: Color.cardRed, radius: 24)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }
                    Text(revolutionBannerIsCounter ? "RANK ORDER RESTORED" : "RANK ORDER INVERTED")
                        .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                        .foregroundStyle(Color.cardRed.opacity(0.85))
                        .tracking(4)
                }
                .padding(.vertical, 22)
                .scaleEffect(showRevolutionBanner ? 1 : 0.75)
                .opacity(showRevolutionBanner ? 1 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showRevolutionBanner)
                Rectangle().fill(Color.cardRed).frame(height: 1.5)
                    .scaleEffect(x: showRevolutionBanner ? 1 : 0, anchor: .center)
                    .animation(.easeOut(duration: 0.4), value: showRevolutionBanner)
                Spacer()
            }
            .frame(maxWidth: .infinity).padding(.horizontal, 24)
        }
        .allowsHitTesting(false).zIndex(22)
    }

    // MARK: - Event pills

    private var eventPills: some View {
        ZStack {
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
                .padding(.horizontal, 34).padding(.vertical, 17)
                .background(Color.tycoonSurface)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.cardMint.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.85), radius: 22, x: 0, y: 12)
                .opacity(showEightStopBanner ? 1 : 0)
                .scaleEffect(showEightStopBanner ? 1 : 0.88)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showEightStopBanner)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).zIndex(20)

            // 3-Spade Reversal
            ZStack {
                VStack(spacing: 5) {
                    Text("3♠")
                        .font(.custom("Fraunces-9ptBlackItalic", size: 44))
                        .foregroundStyle(Color.white)
                    Text("BEATS THE JOKER")
                        .font(.custom("InstrumentSans-Regular", size: 12).weight(.semibold))
                        .foregroundStyle(Color.cardBlush.opacity(0.7))
                        .tracking(2.5)
                }
                .padding(.horizontal, 34).padding(.vertical, 17)
                .background(Color.tycoonSurface)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.cardBlush.opacity(0.25), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.85), radius: 22, x: 0, y: 12)
                .opacity(showThreeSpadeBanner ? 1 : 0)
                .scaleEffect(showThreeSpadeBanner ? 1 : 0.88)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showThreeSpadeBanner)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).zIndex(21)

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
                .padding(.horizontal, 34).padding(.vertical, 17)
                .background(Color.tycoonSurface)
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.85), radius: 22, x: 0, y: 12)
                .opacity(showTrickWinnerOverlay ? 1 : 0)
                .scaleEffect(showTrickWinnerOverlay ? 1 : 0.88)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showTrickWinnerOverlay)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity).zIndex(19)
        }
        .allowsHitTesting(false)
    }

    // MARK: - Game over

    private var gameOverOverlay: some View {
        ZStack {
            Color.tycoonBlack.opacity(0.92).ignoresSafeArea()
            VStack(spacing: 28) {
                Text("Game Over")
                    .font(.custom("Fraunces-9ptBlackItalic", size: 52))
                    .foregroundStyle(Color.textPrimary)

                if let state = controller.state {
                    let myRank = state.players[controller.myUID]?.finishRank
                    let total = state.playerOrder.count
                    VStack(spacing: 6) {
                        Text(myRank.map { finishRankLabel($0, total: total) } ?? "—")
                            .font(.custom("Fraunces-9ptBlackItalic", size: 58))
                            .foregroundStyle(Color.cardBlush)
                        Text("YOUR FINAL RANK")
                            .font(.custom("InstrumentSans-Regular", size: 11).weight(.semibold))
                            .foregroundStyle(Color.textTertiary)
                            .tracking(3)
                    }

                    VStack(spacing: 10) {
                        ForEach(state.playerOrder, id: \.self) { uid in
                            let p = state.players[uid]
                            HStack {
                                Text(p?.displayName ?? uid)
                                    .font(.custom("InstrumentSans-Regular", size: 15).weight(.semibold))
                                    .foregroundStyle(uid == controller.myUID ? Color.cardBlush : Color.textPrimary)
                                Spacer()
                                Text(p?.finishRank.map { finishRankLabel($0, total: total) } ?? "—")
                                    .font(.custom("InstrumentSans-Regular", size: 13))
                                    .foregroundStyle(Color.textSecondary)
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                }

                Button(action: onLeave) {
                    Text("Return Home")
                        .font(.custom("InstrumentSans-Regular", size: 15).weight(.semibold))
                        .foregroundStyle(Color.tycoonBlack)
                        .padding(.horizontal, 48).padding(.vertical, 16)
                        .background(Color.cardBlush)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .zIndex(30)
    }

    // MARK: - Abandoned overlay

    private var abandonedOverlay: some View {
        ZStack {
            Color.tycoonBlack.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 24) {
                Text("Game Ended")
                    .font(.custom("Fraunces-9ptBlackItalic", size: 52))
                    .foregroundStyle(Color.textPrimary)

                VStack(spacing: 8) {
                    if let name = controller.abandonedByName {
                        Text("\(name) left the game.")
                            .font(.custom("InstrumentSans-Regular", size: 17).weight(.medium))
                            .foregroundStyle(Color.textSecondary)
                    }
                    Text("Returning in \(abandonCountdown)…")
                        .font(.custom("InstrumentSans-Regular", size: 15))
                        .foregroundStyle(Color.textTertiary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3), value: abandonCountdown)
                }
            }
        }
        .zIndex(35)
    }

    // MARK: - Connecting

    private var connectingView: some View {
        VStack(spacing: 16) {
            ProgressView().tint(Color.cardBlush).scaleEffect(1.4)
            Text("Connecting to game…")
                .font(.tycoonCaption)
                .foregroundStyle(Color.textSecondary)
        }
    }

    // MARK: - Trick change handler

    private func onTrickChange(old: [[String]], new: [[String]]) {
        // Trick cleared — show winner banner and exit animation
        guard !old.isEmpty && new.isEmpty else { return }

        pileExitCards = old
        pileExitAnimating = false

        // When 8-Stop fires, eightStopEventCount is already incremented in the same
        // atomic RTDB update that clears the trick. Skip the winner banner in that case —
        // the eightStop onChange will show its own banner instead.
        let isEightStop = (controller.state?.eightStopEventCount ?? 0) > lastKnownEightStopCount

        if !isEightStop, let state = controller.state {
            let winnerUID = state.currentPlayerUid
            trickWinnerText = winnerUID == controller.myUID
                ? "Your lead"
                : "\(state.players[winnerUID]?.displayName ?? "Opponent") leads"
        }

        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeOut(duration: 0.25)) { pileExitAnimating = true }
            if !isEightStop {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { showTrickWinnerOverlay = true }
                try? await Task.sleep(nanoseconds: 1_300_000_000)
                withAnimation(.easeOut(duration: 0.3)) { showTrickWinnerOverlay = false }
            } else {
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            try? await Task.sleep(nanoseconds: 350_000_000)
            pileExitCards = []
            pileExitAnimating = false
        }
    }

    // MARK: - Pile slot layout

    private struct CardSlot { var x: CGFloat; var y: CGFloat; var rotation: Double; var z: Double }

    private func pileSlot(index: Int, cards: [String]) -> CardSlot {
        let count = cards.count
        guard count > 1 else { return CardSlot(x: 0, y: 0, rotation: 0, z: 0) }

        let jokerIndices = cards.indices.filter { cards[$0].hasPrefix("JKR") }
        let regularIndices = cards.indices.filter { !cards[$0].hasPrefix("JKR") }
        let isMixed = !jokerIndices.isEmpty && !regularIndices.isEmpty

        if !isMixed {
            let center = CGFloat(index) - CGFloat(count - 1) / 2
            return CardSlot(x: center * 7, y: center * 3, rotation: Double(center) * 2.5, z: Double(index))
        }

        // Mixed: regulars centered, jokers poke right behind
        if regularIndices.contains(index) {
            let orderIndex = regularIndices.firstIndex(of: index) ?? 0
            let center = CGFloat(orderIndex) - CGFloat(regularIndices.count - 1) / 2
            return CardSlot(x: center * 5, y: center * 2, rotation: Double(center) * 2, z: 10 + Double(orderIndex))
        } else {
            let orderIndex = jokerIndices.firstIndex(of: index) ?? 0
            return CardSlot(x: 22 + CGFloat(orderIndex) * 8, y: -3 - CGFloat(orderIndex), rotation: 9 + Double(orderIndex) * 3, z: -1 - Double(orderIndex))
        }
    }

    // MARK: - Hand sorting

    private let rankOrder: [String: Int] = {
        let ranks = ["3","4","5","6","7","8","9","10","J","Q","K","A","2"]
        return Dictionary(uniqueKeysWithValues: ranks.enumerated().map { ($1, $0) })
    }()

    private var sortedHand: [String] {
        controller.myHand.sorted { a, b in
            let aJoker = a.hasPrefix("JKR"), bJoker = b.hasPrefix("JKR")
            if aJoker != bJoker { return bJoker }
            let aRank = rankOrder[rankString(a)] ?? 99
            let bRank = rankOrder[rankString(b)] ?? 99
            if aRank != bRank { return aRank < bRank }
            return suitOrder(a) < suitOrder(b)
        }
    }

    private func rankString(_ card: String) -> String {
        card.hasPrefix("JKR") ? "JKR" : String(card.dropLast())
    }

    private func suitOrder(_ card: String) -> Int {
        guard !card.hasPrefix("JKR") else { return 99 }
        switch card.last {
        case "S": return 0
        case "H": return 1
        case "D": return 2
        case "C": return 3
        default:  return 99
        }
    }

    // MARK: - Display helpers

    private func rankDisplay(_ cardStr: String) -> String { rankString(cardStr) }

    private func handTypeName(count: Int) -> String {
        switch count {
        case 1: return "Single"
        case 2: return "Pair"
        case 3: return "Triple"
        case 4: return "Quad"
        default: return "\(count)-card"
        }
    }

    private func finishRankLabel(_ rank: Int, total: Int) -> String {
        switch rank {
        case 1: return "Tycoon"
        case 2 where total >= 4: return "Rich"
        case total - 1 where total >= 4: return "Poor"
        case total: return "Beggar"
        default: return "Commoner"
        }
    }
}
