import Foundation

// MARK: - Difficulty

/// CPU skill level. Maps to a softmax sampling temperature τ used by
/// `PolicyOpponent`. Lower τ → bot picks the top-scored move more often.
public enum Difficulty: String, Sendable, CaseIterable, Hashable, Codable {
    case easy
    case medium
    case hard

    /// Softmax temperature. Tuned via the AITournament harness against the
    /// `~25 / ~40 / ~60` Millionaire-rate calibration targets. v1 heuristics
    /// cap Hard around ~50% — the rest is reserved for v2 (card counting,
    /// 1-ply lookahead).
    public var temperature: Double {
        switch self {
        case .easy:   return 1.0
        case .medium: return 0.3
        case .hard:   return 0.05
        }
    }

    /// Human-readable label for UI surfaces.
    public var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        }
    }
}
