import Foundation

// MARK: - Difficulty

/// CPU skill level. Maps to a softmax sampling temperature τ used by
/// `PolicyOpponent`. Lower τ → bot picks the top-scored move more often.
public enum Difficulty: String, Sendable, CaseIterable, Hashable, Codable {
    case easy
    case medium
    case hard

    /// Softmax temperature. Placeholder values; tuned via the tournament harness.
    public var temperature: Double {
        switch self {
        case .easy:   return 1.0
        case .medium: return 0.5
        case .hard:   return 0.15
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
