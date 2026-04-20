// MARK: - Opponent

public protocol Opponent: Sendable {
    func move(for playerID: PlayerID, in state: GameState) -> Move
}
