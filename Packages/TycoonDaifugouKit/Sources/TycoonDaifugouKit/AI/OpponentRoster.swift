// MARK: - OpponentKind

public enum OpponentKind: Sendable, CaseIterable {
    case greedy
}

// MARK: - OpponentRoster

public enum OpponentRoster {
    public static func opponent(_ kind: OpponentKind) -> any Opponent {
        switch kind {
        case .greedy:
            return GreedyOpponent()
        }
    }
}
