import Foundation

// MARK: - FeatureWeights

/// Linear weight vector applied to a `MoveFeatures` to produce a scalar score.
/// Each personality is one preset of these weights — see the static members.
public struct FeatureWeights: Sendable, Equatable, Hashable {

    /// Multiplier on `cardsCleared`. Positive = the bot likes shedding fast.
    public var cardsCleared: Double

    /// Multiplier on `winLikelihood`. Positive = the bot fights for the lead.
    public var winLikelihood: Double

    /// Multiplier on `comboIntegrity`. Positive = the bot avoids splitting
    /// held same-rank groups.
    public var comboIntegrity: Double

    /// Multiplier on `cardValueSpent`. Almost always negative — the bot
    /// dislikes spending strong cards.
    public var cardValueSpent: Double

    /// Flat additive offset applied only to the `.pass` move's score.
    /// Positive = lean toward passing on close calls; negative = fight to play.
    public var passBias: Double

    public init(
        cardsCleared: Double,
        winLikelihood: Double,
        comboIntegrity: Double,
        cardValueSpent: Double,
        passBias: Double
    ) {
        self.cardsCleared = cardsCleared
        self.winLikelihood = winLikelihood
        self.comboIntegrity = comboIntegrity
        self.cardValueSpent = cardValueSpent
        self.passBias = passBias
    }
}

// MARK: - Personality presets

extension FeatureWeights {

    /// Hoards strong cards, drips singles, rarely fights for the lead.
    /// Faithful to the legacy `GreedyOpponent` baseline. The cardsCleared
    /// magnitude is large enough to lexicographically dominate cardValueSpent
    /// on lead choices (smallest hand type first, weakest rank within type),
    /// while passBias is negative enough that any legal beater outranks pass.
    public static let greedy = FeatureWeights(
        cardsCleared: -2.5,
        winLikelihood: 0.0,
        comboIntegrity: 0.0,
        cardValueSpent: -0.5,
        passBias: -2.0
    )

    /// Dumps multi-card hands on lead, fights for tempo, willing to spend.
    public static let aggressive = FeatureWeights(
        cardsCleared: 1.2,
        winLikelihood: 0.8,
        comboIntegrity: 0.2,
        cardValueSpent: -0.5,
        passBias: -0.3
    )

    /// Combo-preservation focus, but still plays actively enough to win games.
    /// Earlier draft over-passed and got stuck on combos; this version keeps
    /// the dominant comboIntegrity signal but pairs it with enough fight to
    /// shed cards on schedule.
    public static let comboKeeper = FeatureWeights(
        cardsCleared: 0.7,
        winLikelihood: 0.6,
        comboIntegrity: 1.2,
        cardValueSpent: -0.6,
        passBias: -0.2
    )

    /// Default expert baseline. Tuned via the AITournament harness toward the
    /// strong end of policy space — fights for tempo, avoids reflexive passing,
    /// stays mindful of rank cost.
    public static let balanced = FeatureWeights(
        cardsCleared: 1.1,
        winLikelihood: 1.1,
        comboIntegrity: 0.5,
        cardValueSpent: -0.55,
        passBias: -0.5
    )
}
