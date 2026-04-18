/// The distinct phases of a Tycoon round. The engine enforces legal moves
/// per phase so impossible states like "trading during a trick" can't occur.
public enum GamePhase: Sendable, Hashable, Equatable, Codable {
    /// Cards are being distributed to players.
    case dealing
    /// High-ranking players trade cards with low-ranking players (rounds 2+).
    case trading
    /// Players are taking turns playing tricks.
    case playing
    /// Finishing order is being recorded and titles assigned.
    case scoring
    /// The round has fully resolved; ready to start the next round or end the game.
    case roundEnded
}
