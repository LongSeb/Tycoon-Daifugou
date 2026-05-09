import Foundation

// MARK: - OpponentRoster

/// Factory for `Opponent` instances. Centralizes seed management, random
/// personality assignment, and the `Difficulty` → opponent-type routing
/// (Expert routes to `LookaheadOpponent`; everything else routes to
/// `PolicyOpponent`).
public enum OpponentRoster {

    /// Builds a single opponent for the given personality + difficulty.
    /// `seed` controls the bot's softmax sampling sequence (unused by Expert,
    /// which is deterministic argmax).
    public static func opponent(
        policy: Policy,
        difficulty: Difficulty,
        seed: UInt64
    ) -> any Opponent {
        switch difficulty {
        case .expert:
            return LookaheadOpponent(policy: policy)
        case .easy, .medium, .hard:
            return PolicyOpponent(
                policy: policy,
                temperature: difficulty.temperature,
                seed: seed
            )
        }
    }

    /// Assigns a random `Policy` from `Policy.allV2` to each `PlayerID` and
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
        let pool = Policy.allV2
        var assignments: [PlayerID: any Opponent] = [:]
        for id in playerIDs {
            let pick = Int(rng.next() % UInt64(pool.count))
            let opponentSeed = rng.next()
            assignments[id] = opponent(
                policy: pool[pick],
                difficulty: difficulty,
                seed: opponentSeed
            )
        }
        return assignments
    }
}
