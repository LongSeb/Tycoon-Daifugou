import Foundation

// MARK: - Policy

/// A named personality bundle: identity + weight vector + optional phase
/// modifier. The weight vector and phase modifier together define how this
/// personality plays; the identity is for roster display, persistence, and
/// tests.
public struct Policy: Sendable, Equatable, Hashable {

    public enum Identifier: String, Sendable, CaseIterable, Hashable, Codable {
        case greedy
        case aggressive
        case comboKeeper
        case balanced
        case counter
        case endgameRusher
    }

    public let id: Identifier
    public let weights: FeatureWeights
    /// Per-phase multipliers applied on top of `weights`. Defaults to
    /// `.identity`, which leaves the base weights unchanged across all phases.
    public let phaseModifier: PhaseModifier

    public init(
        id: Identifier,
        weights: FeatureWeights,
        phaseModifier: PhaseModifier = .identity
    ) {
        self.id = id
        self.weights = weights
        self.phaseModifier = phaseModifier
    }
}

// MARK: - Built-in policies

extension Policy {
    public static let greedy = Policy(id: .greedy, weights: .greedy)
    public static let aggressive = Policy(id: .aggressive, weights: .aggressive)
    public static let comboKeeper = Policy(id: .comboKeeper, weights: .comboKeeper)
    public static let balanced = Policy(id: .balanced, weights: .balanced)
    public static let counter = Policy(id: .counter, weights: .counter)
    public static let endgameRusher = Policy(
        id: .endgameRusher,
        weights: .endgameRusher,
        phaseModifier: .endgameRusher
    )

    /// All four v1 personalities, in declaration order. Retained for the
    /// pre-v2 parity tests and tournament snapshots.
    public static let allV1: [Policy] = [.greedy, .aggressive, .comboKeeper, .balanced]

    /// All six v2 personalities, in declaration order. Used by the roster
    /// when assigning random personalities to CPU seats.
    public static let allV2: [Policy] = [
        .greedy, .aggressive, .comboKeeper, .balanced, .counter, .endgameRusher,
    ]
}

// MARK: - Scoring

extension Policy {

    /// Dot product of the (phase-adjusted) weight vector with the move's
    /// feature vector, plus `passBias` if the move is `.pass`.
    ///
    /// Phase is resolved from `hand.count` via `GamePhasePosition.from(handSize:)`.
    /// A policy without a phase modifier (i.e. `.identity`) scores identically
    /// across all hand sizes — preserves v1 behavior for the legacy presets.
    public func score(_ move: Move, in state: GameState, hand: [Card]) -> Double {
        let features = MoveFeatures.extract(for: move, in: state, hand: hand)
        let phase = GamePhasePosition.from(handSize: hand.count)
        let effective = weights.multiplied(by: phaseModifier.multipliers(for: phase))

        return effective.cardsCleared   * features.cardsCleared
            +  effective.winLikelihood  * features.winLikelihood
            +  effective.comboIntegrity * features.comboIntegrity
            +  effective.cardValueSpent * features.cardValueSpent
            +  effective.effectiveRank  * features.effectiveRank
            +  effective.eightStopValue * features.eightStopValue
            +  effective.jokerHoarding  * features.jokerHoarding
            +  (features.isPass ? effective.passBias : 0.0)
    }
}
