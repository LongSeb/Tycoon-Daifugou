import Observation
import TycoonDaifugouKit

/// Wraps GameState for SwiftUI consumption. Exactly one human player is supported per instance.
@Observable
@MainActor
final class GameController {
    private(set) var state: GameState
    let humanPlayerID: PlayerID
    private let opponents: [PlayerID: any Opponent]

    init(
        players: [Player],
        ruleSet: RuleSet,
        seed: UInt64,
        humanPlayerID: PlayerID,
        opponents: [PlayerID: any Opponent]
    ) {
        self.state = GameState.newGame(players: players, ruleSet: ruleSet, seed: seed)
        self.humanPlayerID = humanPlayerID
        self.opponents = opponents
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
        state = try state.apply(.play(cards: cards, by: humanPlayerID))
    }

    func pass() throws {
        state = try state.apply(.pass(by: humanPlayerID))
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
                guard let next = try? state.apply(move) else { return }
                state = next
                try? await Task.sleep(nanoseconds: 400_000_000)

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

    private let maxRounds = 3

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
