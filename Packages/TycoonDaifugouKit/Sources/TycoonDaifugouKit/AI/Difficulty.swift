import Foundation

// MARK: - Difficulty

/// CPU skill level. Maps to a softmax sampling temperature τ used by
/// `PolicyOpponent`. Lower τ → bot picks the top-scored move more often.
public enum Difficulty: String, Sendable, CaseIterable, Hashable, Codable {
    case easy
    case medium
    case hard
    /// Locked tier reserved for v2's 1-ply lookahead bot. Currently unselectable
    /// in the UI; the case exists so call sites can pattern-match exhaustively.
    case expert

    /// Softmax temperature. Tuned via the AITournament harness against the
    /// `~25 / ~40 / ~60` Millionaire-rate calibration targets. v1 heuristics
    /// cap Hard around ~50% — Expert (locked) is reserved for v2 (card
    /// counting, 1-ply lookahead).
    public var temperature: Double {
        switch self {
        case .easy:   return 1.0
        case .medium: return 0.3
        case .hard:   return 0.05
        case .expert: return 0.0
        }
    }

    /// Human-readable label for UI surfaces.
    public var displayName: String {
        switch self {
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        case .expert: return "Expert"
        }
    }

    /// True for difficulty tiers that are not yet user-selectable. The UI
    /// renders these as greyed-out rows with a lock affordance.
    public var isLocked: Bool {
        switch self {
        case .easy, .medium, .hard: return false
        case .expert:               return true
        }
    }
}
