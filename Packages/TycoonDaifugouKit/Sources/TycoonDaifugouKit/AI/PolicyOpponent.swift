import Foundation

// MARK: - PolicyOpponent

/// An opponent that scores every legal move via its `policy` and softmax-samples
/// over the resulting scores at temperature τ. Lower τ → near-deterministic
/// argmax. Higher τ → more variance, but never uniform — clearly bad moves
/// stay improbable because their score is dominated by a worse-fit weight.
///
/// The class holds a mutable `Xoshiro256StarStar` so successive `move(...)`
/// calls produce a deterministic sequence given the construction seed.
/// Single-threaded use only — `@unchecked Sendable` is justified by the
/// game loop calling AI moves serially on the main actor.
public final class PolicyOpponent: Opponent, @unchecked Sendable {

    public let policy: Policy
    public let temperature: Double
    private var rng: Xoshiro256StarStar

    public init(policy: Policy, temperature: Double, seed: UInt64) {
        self.policy = policy
        self.temperature = temperature
        self.rng = Xoshiro256StarStar(seed: seed)
    }

    public func move(for playerID: PlayerID, in state: GameState) -> Move {
        // `state.validMoves(...)` orders candidates via dictionary iteration,
        // which is not stable across instances. Sorting by a string description
        // makes the bot's choice depend only on (state, seed) — required for
        // the parity test, the tournament harness, and reproducible debugging.
        let candidates = state.validMoves(for: playerID).sorted { lhs, rhs in
            String(describing: lhs) < String(describing: rhs)
        }
        if candidates.isEmpty { return .pass(by: playerID) }
        if candidates.count == 1 { return candidates[0] }

        let hand = state.players.first(where: { $0.id == playerID })?.hand ?? []
        let scores = candidates.map { policy.score($0, in: state, hand: hand) }

        if temperature <= 0 {
            return candidates[indexOfMax(scores)]
        }
        return softmaxSample(candidates, scores: scores)
    }

    // MARK: - Sampling

    private func softmaxSample(_ moves: [Move], scores: [Double]) -> Move {
        // Numerically stable softmax: subtract max before exponentiating.
        let maxScore = scores.max() ?? 0
        let exps = scores.map { Foundation.exp(($0 - maxScore) / temperature) }
        let total = exps.reduce(0, +)
        guard total.isFinite, total > 0 else {
            return moves[indexOfMax(scores)]
        }

        // Uniform draw in [0, total).
        let uniform = Double(rng.next() >> 11) / Double(1 << 53)  // [0, 1)
        var threshold = uniform * total

        for (index, weight) in exps.enumerated() {
            threshold -= weight
            if threshold <= 0 { return moves[index] }
        }
        return moves[moves.count - 1]
    }

    private func indexOfMax(_ values: [Double]) -> Int {
        var bestIndex = 0
        for index in 1..<values.count where values[index] > values[bestIndex] {
            bestIndex = index
        }
        return bestIndex
    }
}
