import Foundation
import Observation
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
    /// Bumped each time a play toggles the Revolution state (on or off).
    private(set) var revolutionEventCounter: Int = 0
    /// Bumped each time a play triggers an 8-Stop.
    private(set) var eightStopEventCounter: Int = 0

    // MARK: - Game Tracking

    private let startTime = Date()
    private(set) var cardsPlayed: Int = 0
    private(set) var roundsWon: Int = 0
    private(set) var revolutionCount: Int = 0
    private(set) var eightStopCount: Int = 0
    private(set) var jokerPlayCount: Int = 0
    private(set) var threeSpadeCount: Int = 0
    private var countedRounds: Set<Int> = []

    // MARK: - Inter-round Results

    /// Set when a round ends; nil'd when the user advances past the inter-round overlay.
    private(set) var pendingRoundResult: RoundResult? = nil

    private var roundHistory: [RoundResult] = []
    private var cumulativePoints: [PlayerID: Int] = [:]
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
                guard let opponent = opponents[activePlayer.id] else { return }
                let move = opponent.move(for: activePlayer.id, in: state)
                do { try applyMove(move) } catch { return }
                try? await Task.sleep(nanoseconds: 1_000_000_000)

            case .roundEnded:
                if !countedRounds.contains(state.round) {
                    countedRounds.insert(state.round)
                    let humanTitle = state.players.first(where: { $0.id == humanPlayerID })?.currentTitle
                    if humanTitle == .millionaire || humanTitle == .rich {
                        roundsWon += 1
                    }
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

    /// Starts the next round and resumes AI resolution.
    /// No-op if this is the last round (the CTA routes to final results instead).
    func continueToNextRound() {
        guard !isLastRound else { return }
        pendingRoundResult = nil
        state = state.startNextRound(seed: UInt64.random(in: .min ... .max))
        Task { await resolveAITurnsIfNeeded() }
    }

    /// Applies a move and detects gameplay events worth surfacing to the UI.
    /// UI event counters fire for any player (so banners appear regardless of who acted).
    /// Stat counters (for persistence) only increment for the human player.
    private func applyMove(_ move: Move) throws {
        let priorTop = state.currentTrick.last
        let priorRevolution = state.isRevolutionActive
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

            // Stats only track the human
            if isHumanMove {
                cardsPlayed += cards.count
                jokerPlayCount += cards.filter { $0.isJoker }.count
                if isReversal { threeSpadeCount += 1 }
                if isEightStop { eightStopCount += 1 }
            }
        }

        if state.isRevolutionActive != priorRevolution {
            revolutionEventCounter &+= 1
            // Only credit the revolution to the human if they triggered it
            if state.isRevolutionActive,
               case .play(_, let byPlayerID) = move,
               byPlayerID == humanPlayerID {
                revolutionCount += 1
            }
        }
    }

    var isGameOver: Bool {
        state.phase == .roundEnded && state.round >= maxRounds
    }

    /// Players sorted by total XP earned across the match, descending.
    var finalStandings: [(player: Player, xp: Int)] {
        state.players
            .map { ($0, state.scoresByPlayer[$0.id] ?? 0) }
            .sorted { $0.1 > $1.1 }
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
