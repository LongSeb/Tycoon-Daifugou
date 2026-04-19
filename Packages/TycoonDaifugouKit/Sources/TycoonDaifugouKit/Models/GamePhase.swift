import Foundation

public enum GamePhase: Sendable, Hashable, Codable {
    case dealing
    case trading
    case playing
    case scoring
    case roundEnded
}
