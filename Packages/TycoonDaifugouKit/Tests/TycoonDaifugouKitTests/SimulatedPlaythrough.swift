import Testing
@testable import TycoonDaifugouKit

// MARK: - SimulatedPlaythrough

/// Drives a `GameState` forward deterministically by always picking the first
/// move returned by `validMoves(for:)`. Used by invariant tests that need a
/// sequence of states to assert properties on — not a substitute for real game
/// logic, just a reproducible exerciser.
struct SimulatedPlaythrough {

    /// Returns every state visited, starting with `initial`, up to `maxMoves`
    /// steps across up to `maxRounds` complete rounds. Handles `.trading` phases
    /// greedily (strongest cards given first, weakest returned). Stops early if
    /// the engine gets stuck.
    static func states(from initial: GameState, maxMoves: Int = 500, maxRounds: Int = 1) -> [GameState] {
        var result: [GameState] = [initial]
        var current = initial
        var roundsCompleted = 0

        for _ in 0..<maxMoves {
            switch current.phase {
            case .roundEnded:
                guard roundsCompleted + 1 < maxRounds else { return result }
                roundsCompleted += 1
                let seed = UInt64(roundsCompleted) &* 31_337 &+ 7
                current = current.startNextRound(seed: seed)
                result.append(current)

            case .trading:
                guard let next = applyNextTrade(state: current) else { return result }
                result.append(next)
                current = next

            case .playing:
                if current.players.allSatisfy({ $0.hand.isEmpty }) { return result }
                let playerID = current.players[current.currentPlayerIndex].id
                let moves = current.validMoves(for: playerID)
                guard let move = moves.first else { return result }
                guard let next = try? current.apply(move) else { return result }
                result.append(next)
                current = next

            default:
                return result
            }
        }

        return result
    }

    // MARK: - Private

    /// Applies the first pending trade greedily: strongest cards given first
    /// (for mustGiveStrongest), weakest returned (for optional gives).
    private static func applyNextTrade(state: GameState) -> GameState? {
        guard let trade = state.pendingTrades.first else { return nil }
        guard let giver = state.players.first(where: { $0.id == trade.from }) else { return nil }
        let sorted = giver.hand.sorted { $0.tradingStrength > $1.tradingStrength }
        guard sorted.count >= trade.cardCount else { return nil }
        let cards = trade.mustGiveStrongest
            ? Array(sorted.prefix(trade.cardCount))
            : Array(sorted.suffix(trade.cardCount))
        return try? state.apply(.trade(cards: cards, from: trade.from, to: trade.to))
    }
}
