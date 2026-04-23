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

    /// Drives the game forward until the human has something to do (or the final round ends).
    /// Runs AI plays, auto-advances `.roundEnded` into the next round, and auto-resolves
    /// the trading phase by giving strongest/weakest cards per the engine's required direction.
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
                guard state.round < maxRounds else { return }
                state = state.startNextRound(seed: UInt64.random(in: .min ... .max))

            case .trading:
                guard let next = applyNextAutoTrade(state) else { return }
                state = next

            case .dealing, .scoring:
                return
            }
        }
    }

    /// Applies a move and detects gameplay events worth surfacing to the UI.
    /// A 3-Spade Reversal is detected as: the move was the 3♠ played as a single,
    /// the prior trick top was a solo Joker, and the trick is empty afterward.
    private func applyMove(_ move: Move) throws {
        let priorTop = state.currentTrick.last
        state = try state.apply(move)
        if case .play(let cards, _) = move,
           cards == [.regular(.three, .spades)],
           priorTop?.isSoloJoker == true,
           state.currentTrick.isEmpty {
            reversalEventCounter &+= 1
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
}
