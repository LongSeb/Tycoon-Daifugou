import Foundation

// MARK: - Difficulty

/// CPU skill level. Maps to a softmax sampling temperature τ used by
/// `PolicyOpponent`. Lower τ → bot picks the top-scored move more often.
public enum Difficulty: String, Sendable, CaseIterable, Hashable, Codable {
    case easy
    case medium
    case hard
    /// Expert tier — backed by `LookaheadOpponent`'s 1-ply forward simulation
    /// instead of a softmax over `policy.score`. The `temperature` value is
    /// retained for symmetry but unused by the lookahead bot (Expert is
    /// deterministic argmax). Player-level gated: feature flag
    /// `expertDifficulty` unlocks at level 20.
    case expert

    /// Softmax temperature. Tuned via the AITournament harness against the
    /// 25 / 50 / 70 / 80 Millionaire-rate calibration targets. Expert ignores
    /// this value — see `LookaheadOpponent`.
    public var temperature: Double {
        switch self {
        case .easy:   return 2.0
        case .medium: return 0.25
        case .hard:   return 0.10
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

    /// UI lock affordance flag — `true` means render with a greyed-out row
    /// and a lock icon. Independent of whether the AI is implemented; Expert
    /// has a working AI but remains UI-locked for unlock-flow callers.
    /// Surfaces gating Expert by player level (e.g. `DifficultyPickerSheet`)
    /// override this with their own `isExpertUnlocked` state.
    public var isLocked: Bool {
        switch self {
        case .easy, .medium, .hard: return false
        case .expert:               return true
        }
    }
}
