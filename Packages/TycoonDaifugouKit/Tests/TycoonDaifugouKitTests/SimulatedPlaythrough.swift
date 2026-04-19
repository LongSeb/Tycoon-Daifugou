import Testing
@testable import TycoonDaifugouKit

// MARK: - SimulatedPlaythrough

/// Drives a `GameState` forward deterministically by always picking the first
/// move returned by `validMoves(for:)`. Used by invariant tests that need a
/// sequence of states to assert properties on — not a substitute for real game
/// logic, just a reproducible exerciser.
struct SimulatedPlaythrough {

    /// Returns every state visited, starting with `initial`, up to `maxMoves`
    /// steps. Stops early when all player hands are empty (game over) or when
    /// `validMoves` returns nothing (stuck state).
    static func states(from initial: GameState, maxMoves: Int = 500) -> [GameState] {
        var result: [GameState] = [initial]
        var current = initial

        for _ in 0..<maxMoves {
            if current.players.allSatisfy({ $0.hand.isEmpty }) { break }

            let playerID = current.players[current.currentPlayerIndex].id
            let moves = current.validMoves(for: playerID)
            guard let move = moves.first else { break }
            guard let next = try? current.apply(move) else { break }

            result.append(next)
            current = next
        }

        return result
    }
}
