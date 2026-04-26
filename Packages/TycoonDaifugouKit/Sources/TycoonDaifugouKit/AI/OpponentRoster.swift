import Foundation

// MARK: - OpponentRoster

/// Factory for `PolicyOpponent` instances. Centralizes seed management and
/// random personality assignment so callers don't have to know about Xoshiro
/// or the `Policy.allV1` lineup.
public enum OpponentRoster {

    /// Builds a single `PolicyOpponent` for the given personality + difficulty.
    /// `seed` controls the bot's softmax sampling sequence.
    public static func opponent(
        policy: Policy,
        difficulty: Difficulty,
        seed: UInt64
    ) -> any Opponent {
        PolicyOpponent(policy: policy, temperature: difficulty.temperature, seed: seed)
    }

    /// Assigns a random `Policy` from `Policy.allV1` to each `PlayerID` and
    /// returns the resulting opponent dictionary, ready to hand to a
    /// `GameController`.
    /// Determinism: given the same `seed` and `playerIDs` order, returns the
    /// same personality assignment and the same per-bot seeds.
    public static func randomAssignments(
        playerIDs: [PlayerID],
        difficulty: Difficulty,
        seed: UInt64
    ) -> [PlayerID: any Opponent] {
        var rng = Xoshiro256StarStar(seed: seed)
        let pool = Policy.allV1
        var assignments: [PlayerID: any Opponent] = [:]
        for id in playerIDs {
            let pick = Int(rng.next() % UInt64(pool.count))
            let opponentSeed = rng.next()
            assignments[id] = PolicyOpponent(
                policy: pool[pick],
                temperature: difficulty.temperature,
                seed: opponentSeed
            )
        }
        return assignments
    }
}
