import Foundation

// MARK: - Scoring

public enum Scoring {

    /// Title awarded for finishing in the given 0-indexed position in a game with `playerCount` players.
    ///
    /// Table:
    ///   3-player : Millionaire · Commoner · Beggar
    ///   4-player : Millionaire · Rich · Poor · Beggar
    ///   5-player : Millionaire · Rich · Commoner · Poor · Beggar
    ///   6+-player: Millionaire · Rich · Commoner… · Poor · Beggar
    public static func title(forFinishPosition position: Int, playerCount: Int) -> Title {
        let lastPosition = playerCount - 1
        switch position {
        case 0:
            return .millionaire
        case lastPosition:
            return .beggar
        case 1 where playerCount >= 4:
            return .rich
        case lastPosition - 1 where playerCount >= 4:
            return .poor
        default:
            return .commoner
        }
    }

    /// XP awarded for holding a given title at round end.
    public static func xp(for title: Title) -> Int {
        switch title {
        case .millionaire: return 4
        case .rich:        return 3
        case .commoner:    return 2
        case .poor:        return 1
        case .beggar:      return 0
        }
    }

    /// Sum of XP awarded across all titles for the given player count.
    public static func totalXP(playerCount: Int) -> Int {
        (0..<playerCount)
            .map { xp(for: title(forFinishPosition: $0, playerCount: playerCount)) }
            .reduce(0, +)
    }
}
