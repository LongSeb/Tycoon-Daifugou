import Foundation

// MARK: - Policy

/// A named personality bundle: identity + weight vector. The weight vector is
/// the only knob that varies how this personality plays; the identity is for
/// roster display, persistence, and tests.
public struct Policy: Sendable, Equatable, Hashable {

    public enum Identifier: String, Sendable, CaseIterable, Hashable, Codable {
        case greedy
        case aggressive
        case comboKeeper
        case balanced
    }

    public let id: Identifier
    public let weights: FeatureWeights

    public init(id: Identifier, weights: FeatureWeights) {
        self.id = id
        self.weights = weights
    }
}

// MARK: - Built-in policies

extension Policy {
    public static let greedy = Policy(id: .greedy, weights: .greedy)
    public static let aggressive = Policy(id: .aggressive, weights: .aggressive)
    public static let comboKeeper = Policy(id: .comboKeeper, weights: .comboKeeper)
    public static let balanced = Policy(id: .balanced, weights: .balanced)

    /// All four v1 personalities, in declaration order. Used by the roster
    /// when assigning random personalities to CPU seats.
    public static let allV1: [Policy] = [.greedy, .aggressive, .comboKeeper, .balanced]
}

// MARK: - Scoring

extension Policy {

    /// Dot product of the weight vector with the move's feature vector,
    /// plus `passBias` if the move is `.pass`.
    public func score(_ move: Move, in state: GameState, hand: [Card]) -> Double {
        let features = MoveFeatures.extract(for: move, in: state, hand: hand)
        return weights.cardsCleared * features.cardsCleared
            + weights.winLikelihood * features.winLikelihood
            + weights.comboIntegrity * features.comboIntegrity
            + weights.cardValueSpent * features.cardValueSpent
            + (features.isPass ? weights.passBias : 0.0)
    }
}
