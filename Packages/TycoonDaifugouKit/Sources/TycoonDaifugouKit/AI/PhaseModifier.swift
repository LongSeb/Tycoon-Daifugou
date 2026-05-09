import Foundation

// MARK: - GamePhasePosition

/// Coarse hand-size buckets used by `PhaseModifier`. Computed from the active
/// player's hand size at score time:
///
/// - `early`: hand size > 8
/// - `mid`:   hand size 4–8
/// - `endgame`: hand size ≤ 3
public enum GamePhasePosition: Sendable, Equatable, Hashable {
    case early
    case mid
    case endgame

    public static func from(handSize: Int) -> GamePhasePosition {
        switch handSize {
        case ...3:  return .endgame
        case 4...8: return .mid
        default:    return .early
        }
    }
}

// MARK: - PhaseModifier

/// Per-phase weight multipliers applied on top of a `Policy`'s base
/// `FeatureWeights`. A multiplier of 1.0 leaves the weight unchanged; values
/// below 1.0 dampen the feature's influence; values above 1.0 amplify it.
///
/// The default `.identity` modifier multiplies every weight by 1.0, so a
/// policy without a phase modifier behaves exactly like its base weights.
public struct PhaseModifier: Sendable, Equatable, Hashable {

    public let earlyGameMultipliers: FeatureWeights
    public let midGameMultipliers: FeatureWeights
    public let endgameMultipliers: FeatureWeights

    public init(
        earlyGameMultipliers: FeatureWeights,
        midGameMultipliers: FeatureWeights,
        endgameMultipliers: FeatureWeights
    ) {
        self.earlyGameMultipliers = earlyGameMultipliers
        self.midGameMultipliers = midGameMultipliers
        self.endgameMultipliers = endgameMultipliers
    }

    /// Returns the multiplier vector for `phase`.
    public func multipliers(for phase: GamePhasePosition) -> FeatureWeights {
        switch phase {
        case .early:   return earlyGameMultipliers
        case .mid:     return midGameMultipliers
        case .endgame: return endgameMultipliers
        }
    }
}

// MARK: - Built-in modifiers

extension PhaseModifier {

    /// All multipliers = 1.0; a policy with this modifier behaves exactly like
    /// its base weight vector across all hand sizes.
    public static let identity = PhaseModifier(
        earlyGameMultipliers: .ones,
        midGameMultipliers: .ones,
        endgameMultipliers: .ones
    )

    /// Pre-rolled modifier for `.endgameRusher`: defensive in early game
    /// (dampened cardsCleared, mild bonus on combo retention), neutral in mid,
    /// frantic in endgame (amplified cardsCleared and inverted passBias).
    public static let endgameRusher = PhaseModifier(
        earlyGameMultipliers: FeatureWeights(
            cardsCleared:  0.6,
            winLikelihood: 0.8,
            comboIntegrity: 1.4,
            cardValueSpent: 1.2,
            passBias: 1.4,
            effectiveRank: 1.0,
            eightStopValue: 0.7,
            jokerHoarding: 1.0
        ),
        midGameMultipliers: .ones,
        endgameMultipliers: FeatureWeights(
            cardsCleared:  3.0,
            winLikelihood: 1.3,
            comboIntegrity: 0.7,
            cardValueSpent: 0.4,
            passBias: 0.0,
            effectiveRank: 1.2,
            eightStopValue: 1.5,
            jokerHoarding: 0.4
        )
    )
}

// MARK: - FeatureWeights helper

extension FeatureWeights {

    /// All weight components set to 1.0. Convenience for `PhaseModifier.identity`
    /// and for hand-rolled modifiers that want to start from a neutral baseline.
    public static let ones = FeatureWeights(
        cardsCleared: 1.0,
        winLikelihood: 1.0,
        comboIntegrity: 1.0,
        cardValueSpent: 1.0,
        passBias: 1.0,
        effectiveRank: 1.0,
        eightStopValue: 1.0,
        jokerHoarding: 1.0
    )

    /// Component-wise multiplication. Used by `Policy.score` to apply a
    /// `PhaseModifier`'s multipliers to the policy's base weights.
    public func multiplied(by other: FeatureWeights) -> FeatureWeights {
        FeatureWeights(
            cardsCleared:   cardsCleared   * other.cardsCleared,
            winLikelihood:  winLikelihood  * other.winLikelihood,
            comboIntegrity: comboIntegrity * other.comboIntegrity,
            cardValueSpent: cardValueSpent * other.cardValueSpent,
            passBias:       passBias       * other.passBias,
            effectiveRank:  effectiveRank  * other.effectiveRank,
            eightStopValue: eightStopValue * other.eightStopValue,
            jokerHoarding:  jokerHoarding  * other.jokerHoarding
        )
    }
}
