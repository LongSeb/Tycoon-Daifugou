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

    /// Multiplier on `effectiveRank`. Card-counting personalities turn this
    /// up to confidently spend cards whose absolute rank is high but whose
    /// effective rank is low because nothing stronger remains alive.
    public var effectiveRank: Double

    /// Multiplier on `eightStopValue`. Positive personalities opportunistically
    /// lock tricks with an 8 when seizing the lead is high-value.
    public var eightStopValue: Double

    /// Multiplier on `jokerHoarding`. Almost always negative — even more so
    /// than `cardValueSpent` — so personalities can dampen Joker spend
    /// independently of regular high-rank spend.
    public var jokerHoarding: Double

    public init(
        cardsCleared: Double,
        winLikelihood: Double,
        comboIntegrity: Double,
        cardValueSpent: Double,
        passBias: Double,
        effectiveRank: Double = 0.0,
        eightStopValue: Double = 0.0,
        jokerHoarding: Double = 0.0
    ) {
        self.cardsCleared = cardsCleared
        self.winLikelihood = winLikelihood
        self.comboIntegrity = comboIntegrity
        self.cardValueSpent = cardValueSpent
        self.passBias = passBias
        self.effectiveRank = effectiveRank
        self.eightStopValue = eightStopValue
        self.jokerHoarding = jokerHoarding
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

    /// Default expert baseline. Tuned around the **endgame-stashing** strategy
    /// human players use to win 4-player Tycoon: drop low-rank cards early,
    /// pass on tricks that would cost a strong card, save 2s/Aces/Jokers for
    /// the endgame where turn order can't be denied. Concretely that means:
    ///
    /// - large negative `cardValueSpent` (don't burn strong cards mid-trick)
    /// - very large negative `jokerHoarding` (Jokers are sacred until late)
    /// - moderate positive `cardsCleared` (still want to shed when cheap)
    /// - reduced `winLikelihood` so winning tricks isn't the goal in itself
    /// - softened `passBias` so passing is genuinely on the table
    ///
    /// Weight magnitudes are kept moderate so the softmax distribution still
    /// has meaningful variance at τ=1.0 (Easy); over-large weights make Easy
    /// refs converge to argmax and erase the difficulty curve.
    public static let balanced = FeatureWeights(
        cardsCleared: 1.4,
        winLikelihood: 0.9,
        comboIntegrity: 0.7,
        cardValueSpent: -1.6,
        passBias: -0.3,
        effectiveRank: 0.6,
        eightStopValue: 0.4,
        jokerHoarding: -1.8
    )

    /// Card counter. On contested tricks, leans on the effective-rank signal
    /// to confidently spend cards that still dominate the unseen deck — and
    /// shies away from Joker spend more aggressively than `cardValueSpent`
    /// alone. (effectiveRank is gated on a contested trick, so on lead the
    /// bot reverts to the base spend-cheap behavior.) Reads as
    /// "this bot is thinking."
    public static let counter = FeatureWeights(
        cardsCleared: 1.2,
        winLikelihood: 1.0,
        comboIntegrity: 0.5,
        cardValueSpent: -0.7,
        passBias: -0.5,
        effectiveRank: 1.2,
        eightStopValue: 0.5,
        jokerHoarding: -1.2
    )

    /// Defensive early, frantic late. Most of the personality lives in the
    /// `.endgameRusher` `PhaseModifier`; the base weights are roughly Balanced
    /// so the modifier has clean material to scale.
    public static let endgameRusher = FeatureWeights(
        cardsCleared: 0.9,
        winLikelihood: 0.8,
        comboIntegrity: 0.6,
        cardValueSpent: -0.5,
        passBias: -0.2,
        effectiveRank: 0.4,
        eightStopValue: 0.3,
        jokerHoarding: -0.6
    )
}
