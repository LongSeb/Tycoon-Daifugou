import Foundation
import Observation
import SwiftUI
import TycoonDaifugouKit

/// Wraps GameState for SwiftUI consumption. Exactly one human player is supported per instance.
@Observable
@MainActor
final class GameController {
    private(set) var state: GameState
    let humanPlayerID: PlayerID
    private let opponents: [PlayerID: any Opponent]
    let maxRounds: Int

    /// Bumped each time a play causes a 3-Spade Reversal. Views observe this to
    /// trigger a brief on-screen highlight.
    private(set) var reversalEventCounter: Int = 0
    /// Bumped each time a play triggers a Revolution (rank order inverts).
    private(set) var revolutionEventCounter: Int = 0
    /// Bumped each time a Counter-Revolution fires (Revolution ends).
    private(set) var counterRevolutionEventCounter: Int = 0
    /// Bumped each time a play triggers an 8-Stop.
    private(set) var eightStopEventCounter: Int = 0
    /// Per-opponent play counter for the panel flash animation. Key is opponent PlayerID.
    private(set) var aiPlayCountByID: [PlayerID: Int] = [:]
    /// Bumped each time all players pass (or 8-stop/reversal fires) and the pile resets.
    private(set) var trickResetCounter: Int = 0
    /// The card that was on top when the pile last reset; used for the fade-out animation.
    private(set) var trickResetLastTopCard: Card? = nil
    /// The player who gets to lead after the last trick reset (the last unbeaten player).
    private(set) var trickWinnerID: PlayerID? = nil
    /// Bumped each time bankruptcy fires; views observe this to show the overlay.
    private(set) var bankruptcyEventCounter: Int = 0
    /// The player who just went bankrupt; set at the same time as bankruptcyEventCounter.
    private(set) var bankruptedPlayerID: PlayerID? = nil
    /// Set 0.4 s before the AI applies its play move so the opponent panel can reveal the card.
    private(set) var pendingAIPlay: (playerID: PlayerID, card: Card)? = nil
    /// Date until which the AI loop should wait before acting — extended by overlay durations.
    private var overlayBlockUntil: Date = .distantPast

    /// Extends the overlay block window. Views call this whenever a full-screen overlay appears.
    func extendOverlayBlock(for duration: TimeInterval) {
        let candidate = Date().addingTimeInterval(duration)
        if candidate > overlayBlockUntil { overlayBlockUntil = candidate }
    }

    // MARK: - Game Tracking (stats & XP inputs)

    private let startTime = Date()
    private(set) var cardsPlayed: Int = 0
    private(set) var roundsWon: Int = 0
    private(set) var revolutionCount: Int = 0
    private(set) var counterRevolutionCount: Int = 0
    private(set) var eightStopCount: Int = 0
    private(set) var jokerPlayCount: Int = 0
    private(set) var threeSpadeCount: Int = 0

    // XP event tracking
    private(set) var humanCumulativePoints: Int = 0
    private(set) var humanMillionaireRounds: Int = 0
    private(set) var wasShutOut: Bool = false
    private(set) var comebackRoundsCount: Int = 0

    private var countedRounds: Set<Int> = []
    // Title the human carried INTO the current round (nil = first round, no prior title).
    private var roundStartTitle: Title? = nil

    // MARK: - Inter-round Results

    /// Set when a round ends; nil'd when the user advances past the inter-round overlay.
    private(set) var pendingRoundResult: RoundResult? = nil

    /// Set when the trading phase begins and the human is involved in the exchange;
    /// nil'd when the user confirms the exchange dialog.
    private(set) var pendingExchange: CardExchangeState? = nil

    private var roundHistory: [RoundResult] = []
    private(set) var cumulativePoints: [PlayerID: Int] = [:]
    private let playerEmojis: [PlayerID: String]

    var gameDuration: TimeInterval { Date().timeIntervalSince(startTime) }

    var gameHighlight: String {
        if threeSpadeCount > 0 {
            return threeSpadeCount == 1 ? "3♠ Reversal" : "\(threeSpadeCount)× 3♠ Reversals"
        }
        if revolutionCount > 0 {
            return revolutionCount == 1 ? "Revolution!" : "\(revolutionCount) Revolutions"
        }
        if eightStopCount > 0 {
            return eightStopCount == 1 ? "8-Stop" : "\(eightStopCount) 8-Stops"
        }
        if jokerPlayCount > 0 {
            return jokerPlayCount == 1 ? "Joker played" : "\(jokerPlayCount) Jokers played"
        }
        return ""
    }

    init(
        players: [Player],
        ruleSet: RuleSet,
        seed: UInt64,
        humanPlayerID: PlayerID,
        opponents: [PlayerID: any Opponent],
        maxRounds: Int = 3
    ) {
        self.state = GameState.newGame(players: players, ruleSet: ruleSet, seed: seed)
        self.humanPlayerID = humanPlayerID
        self.opponents = opponents
        self.maxRounds = maxRounds

        let aiEmojis = ["🎩", "😏", "😤", "🦊", "🐻", "🦁", "🐼"]
        var emojiIdx = 0
        var emojiMap: [PlayerID: String] = [:]
        for player in players {
            if player.id == humanPlayerID {
                emojiMap[player.id] = "😎"
            } else {
                emojiMap[player.id] = aiEmojis[emojiIdx % aiEmojis.count]
                emojiIdx += 1
            }
        }
        self.playerEmojis = emojiMap
    }

    var humanHand: [Card] {
        state.players.first { $0.id == humanPlayerID }?.hand ?? []
    }

    var humanPlayer: Player? {
        state.players.first { $0.id == humanPlayerID }
    }

    /// Opponents in seat order starting from the seat immediately after the human.
    var opponentSeats: [Player] {
        guard let humanIndex = state.players.firstIndex(where: { $0.id == humanPlayerID }) else {
            return []
        }
        let players = state.players
        return (1..<players.count).map { players[(humanIndex + $0) % players.count] }
    }

    var isHumansTurn: Bool {
        state.phase == .playing && activePlayer.id == humanPlayerID
    }

    var currentTrick: [Hand] {
        state.currentTrick
    }

    var activePlayer: Player {
        state.players[state.currentPlayerIndex]
    }

    func canPlay(cards: [Card]) -> Bool {
        state.validMoves(for: humanPlayerID).contains {
            guard case .play(let moveCards, _) = $0 else { return false }
            return Set(moveCards) == Set(cards)
        }
    }

    var canPass: Bool {
        state.validMoves(for: humanPlayerID).contains {
            if case .pass = $0 { return true }
            return false
        }
    }

    func play(_ cards: [Card]) throws {
        try applyMove(.play(cards: cards, by: humanPlayerID))
    }

    func pass() throws {
        try applyMove(.pass(by: humanPlayerID))
    }

    /// Drives the game forward until the human has something to do (or a round ends).
    /// Runs AI plays, auto-resolves the trading phase, and records inter-round results
    /// when a round ends. The loop always pauses at `.roundEnded` — the user must
    /// advance via the inter-round screen CTA.
    func resolveAITurnsIfNeeded() async {
        while true {
            switch state.phase {
            case .playing:
                if activePlayer.id == humanPlayerID { return }
                // Pause while any full-screen overlay is visible (+ its buffer).
                let waitNs = overlayBlockUntil.timeIntervalSinceNow
                if waitNs > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(waitNs * 1_000_000_000))
                }
                guard let opponent = opponents[activePlayer.id] else { return }
                let move = opponent.move(for: activePlayer.id, in: state)
                // Pre-announce play so the opponent panel can reveal the card before state updates.
                if case .play(let cards, let byID) = move, let first = cards.first {
                    pendingAIPlay = (playerID: byID, card: first)
                    try? await Task.sleep(nanoseconds: 400_000_000)
                }
                // Wrap in withAnimation so pendingAIPlay → nil triggers the matchedGeometryEffect
                // that flies the card from the opponent panel to the pile.
                var moveSucceeded = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    do {
                        try applyMove(move)
                        moveSucceeded = true
                    } catch {}
                    pendingAIPlay = nil
                }
                guard moveSucceeded else { return }
                try? await Task.sleep(nanoseconds: 600_000_000)

            case .roundEnded:
                if !countedRounds.contains(state.round) {
                    countedRounds.insert(state.round)
                    let humanTitle = state.players.first(where: { $0.id == humanPlayerID })?.currentTitle

                    // Accumulate round points for XP bracket calculation.
                    humanCumulativePoints += roundPoints(for: humanTitle)

                    if humanTitle == .millionaire {
                        humanMillionaireRounds += 1
                    }

                    // Comeback: started the round as Beggar, finished Millionaire or Rich.
                    if roundStartTitle == .beggar && (humanTitle == .millionaire || humanTitle == .rich) {
                        comebackRoundsCount += 1
                    }

                    if humanTitle == .millionaire || humanTitle == .rich {
                        roundsWon += 1
                    }

                    // The title earned this round becomes the start title for the next.
                    roundStartTitle = humanTitle
                    recordRoundResult()
                }
                return  // Always pause; user advances via inter-round CTA

            case .trading:
                guard let next = applyNextAutoTrade(state) else { return }
                state = next

            case .dealing, .scoring:
                return
            }
        }
    }

    var isGameOver: Bool {
        state.phase == .roundEnded && state.round >= maxRounds
    }

    /// Players sorted by total engine score earned across the match, descending.
    var finalStandings: [(player: Player, xp: Int)] {
        state.players
            .map { ($0, state.scoresByPlayer[$0.id] ?? 0) }
            .sorted { $0.1 > $1.1 }
    }

    // MARK: - Private helpers

    /// Maps a round-end title to the inter-round point value used for XP bracket lookup.
    private func roundPoints(for title: Title?) -> Int {
        switch title {
        case .millionaire: return 30
        case .rich:        return 20
        case .poor, .commoner: return 10
        case .beggar, nil: return 0
        }
    }

    /// True when the round that just ended is the final round of the game.
    var isLastRound: Bool {
        state.phase == .roundEnded && state.round >= maxRounds
    }

    /// Running total of round-scoring points earned by the human player.
    var humanRoundPointsTotal: Int {
        cumulativePoints[humanPlayerID] ?? 0
    }

    /// Highest round-scoring points earned by any single opponent across all rounds played.
    var opponentBestPoints: Int {
        state.players
            .filter { $0.id != humanPlayerID }
            .compactMap { cumulativePoints[$0.id] }
            .max() ?? 0
    }

    /// Clears the inter-round overlay. Call before navigating to final results or starting the next round.
    func clearRoundResult() {
        pendingRoundResult = nil
    }

    /// Starts the next round. If the human is involved in the trading phase, sets
    /// `pendingExchange` and waits for `confirmExchange` before resuming AI resolution.
    func continueToNextRound() {
        guard !isLastRound else { return }
        pendingRoundResult = nil
        state = state.startNextRound(seed: UInt64.random(in: .min ... .max))
        if let exchange = buildExchangeState() {
            pendingExchange = exchange
        } else {
            Task { await resolveAITurnsIfNeeded() }
        }
    }

    /// Applies all pending trades in order, using `selectedCards` for the human's
    /// optional-choice trade (Millionaire/Rich). For forced trades (Beggar/Poor)
    /// `selectedCards` is ignored and the engine auto-selects strongest cards.
    func confirmExchange(selectedCards: [Card]) {
        var currentState = state
        while !currentState.pendingTrades.isEmpty {
            guard let trade = currentState.pendingTrades.first,
                  let giver = currentState.players.first(where: { $0.id == trade.from })
            else { break }

            let cards: [Card]
            if trade.from == humanPlayerID && !trade.mustGiveStrongest {
                cards = selectedCards
            } else {
                let sorted = giver.hand.sorted { tradingStrength($0) > tradingStrength($1) }
                cards = trade.mustGiveStrongest
                    ? Array(sorted.prefix(trade.cardCount))
                    : Array(sorted.suffix(trade.cardCount))
            }

            guard let next = try? currentState.apply(.trade(cards: cards, from: trade.from, to: trade.to)) else { break }
            currentState = next
        }

        state = currentState
        pendingExchange = nil
        Task { await resolveAITurnsIfNeeded() }
    }

    /// Applies a move and detects gameplay events worth surfacing to the UI.
    /// UI event counters fire for any player (so banners appear regardless of who acted).
    /// Stat counters (for persistence) only increment for the human player.
    private func applyMove(_ move: Move) throws {
        let priorHumanHandCount = humanHand.count
        let priorTop = state.currentTrick.last
        let priorRevolution = state.isRevolutionActive
        let priorBankruptIDs = Set(state.players.filter { $0.isBankrupt }.map { $0.id })
        state = try state.apply(move)

        if case .play(let cards, let byPlayerID) = move {
            let isHumanMove = byPlayerID == humanPlayerID

            let isReversal = cards == [.regular(.three, .spades)]
                && priorTop?.isSoloJoker == true
                && state.currentTrick.isEmpty

            let isEightStop = state.ruleSet.eightStop
                && (try? Hand(cards: cards))?.rank == .eight

            // UI banners fire for all players
            if isReversal { reversalEventCounter &+= 1 }
            if isEightStop { eightStopEventCounter &+= 1 }

            if isHumanMove {
                cardsPlayed += cards.count
                jokerPlayCount += cards.filter { $0.isJoker }.count
                if isReversal { threeSpadeCount += 1 }
                if isEightStop { eightStopCount += 1 }

                // Shutout: human just emptied their hand while others have 3+ cards remaining.
                if priorHumanHandCount > 0 && humanHand.isEmpty && !wasShutOut {
                    let otherMin = state.players
                        .filter { $0.id != humanPlayerID && $0.currentTitle == nil }
                        .map { $0.hand.count }
                        .min() ?? 0
                    if otherMin >= 3 {
                        wasShutOut = true
                    }
                }
            }
        }

        if state.isRevolutionActive != priorRevolution {
            if state.isRevolutionActive {
                revolutionEventCounter &+= 1
                if case .play(_, let byPlayerID) = move, byPlayerID == humanPlayerID {
                    revolutionCount += 1
                }
            } else {
                counterRevolutionEventCounter &+= 1
                if case .play(_, let byPlayerID) = move, byPlayerID == humanPlayerID {
                    counterRevolutionCount += 1
                }
            }
        }

        if let topCard = priorTop?.cards.first, state.currentTrick.isEmpty {
            trickResetCounter &+= 1
            // For 8-stop and reversal the trick resets immediately after the trigger card
            // is played, so the engine never holds the trigger card in currentTrick.
            // Store the played card so the pile can display it before the event banner fires.
            if case .play(let cards, _) = move,
               let playedCard = cards.first,
               let playedHand = try? Hand(cards: cards) {
                let isEventTrigger = (state.ruleSet.eightStop && playedHand.rank == .eight)
                    || (cards == [.regular(.three, .spades)] && priorTop?.isSoloJoker == true)
                trickResetLastTopCard = isEventTrigger ? playedCard : topCard
            } else {
                trickResetLastTopCard = topCard
            }
            let idx = state.currentPlayerIndex
            trickWinnerID = idx < state.players.count ? state.players[idx].id : nil
        }

        if case .play(_, let byPlayerID) = move, byPlayerID != humanPlayerID {
            aiPlayCountByID[byPlayerID, default: 0] &+= 1
        }

        let nowBankruptIDs = Set(state.players.filter { $0.isBankrupt }.map { $0.id })
        if let newlyBankruptID = nowBankruptIDs.subtracting(priorBankruptIDs).first {
            bankruptcyEventCounter &+= 1
            bankruptedPlayerID = newlyBankruptID
        }
    }

    /// Builds a CardExchangeState from the current trading phase if the human is
    /// a participant. Returns nil when the human is a commoner (no trades) or when
    /// the phase is not .trading.
    private func buildExchangeState() -> CardExchangeState? {
        guard state.phase == .trading,
              let giveTrade = state.pendingTrades.first(where: { $0.from == humanPlayerID }),
              let humanPlayer = state.players.first(where: { $0.id == humanPlayerID }),
              let humanLastRank = humanPlayer.currentTitle
        else { return nil }

        let opponentID = giveTrade.to
        guard let opponent = state.players.first(where: { $0.id == opponentID }),
              let opponentTitle = opponent.currentTitle,
              let receiveTrade = state.pendingTrades.first(where: {
                  $0.from == opponentID && $0.to == humanPlayerID
              })
        else { return nil }

        let engineAllowsSelection = !giveTrade.mustGiveStrongest

        let cardsToGive: [Card]
        if engineAllowsSelection {
            cardsToGive = []
        } else {
            let sorted = humanPlayer.hand.sorted { tradingStrength($0) > tradingStrength($1) }
            cardsToGive = Array(sorted.prefix(giveTrade.cardCount))
        }

        let opponentSorted = opponent.hand.sorted { tradingStrength($0) > tradingStrength($1) }
        let cardsReceived = receiveTrade.mustGiveStrongest
            ? Array(opponentSorted.prefix(receiveTrade.cardCount))
            : Array(opponentSorted.suffix(receiveTrade.cardCount))

        return CardExchangeState(
            humanLastRank: humanLastRank,
            opponentName: opponent.displayName,
            cardsToGive: cardsToGive,
            cardsReceived: cardsReceived,
            requiredGiveCount: giveTrade.cardCount,
            engineAllowsSelection: engineAllowsSelection
        )
    }

    private func applyNextAutoTrade(_ state: GameState) -> GameState? {
        guard let trade = state.pendingTrades.first,
              let giver = state.players.first(where: { $0.id == trade.from }) else { return nil }
        let sorted = giver.hand.sorted { tradingStrength($0) > tradingStrength($1) }
        guard sorted.count >= trade.cardCount else { return nil }
        let cards = trade.mustGiveStrongest
            ? Array(sorted.prefix(trade.cardCount))
            : Array(sorted.suffix(trade.cardCount))
        return try? state.apply(.trade(cards: cards, from: trade.from, to: trade.to))
    }

    private func tradingStrength(_ card: Card) -> Int {
        switch card {
        case .joker:             return .max
        case .regular(let r, _): return r.rawValue
        }
    }

    private func recordRoundResult() {
        var playerResults: [PlayerRoundResult] = []
        for player in state.players {
            guard let title = player.currentTitle else { continue }
            let points = roundPoints(for: title)
            cumulativePoints[player.id, default: 0] += points
            playerResults.append(PlayerRoundResult(
                playerID: player.id,
                name: player.id == humanPlayerID ? "You" : player.displayName,
                emoji: playerEmojis[player.id] ?? "🃏",
                isHuman: player.id == humanPlayerID,
                title: title,
                pointsEarned: points,
                cumulativePoints: cumulativePoints[player.id] ?? 0
            ))
        }
        playerResults.sort { $0.cumulativePoints > $1.cumulativePoints }
        let result = RoundResult(roundNumber: state.round, playerResults: playerResults)
        roundHistory.append(result)
        pendingRoundResult = result
    }
}
