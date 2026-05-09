import Foundation

// MARK: - TacticalRules

/// A small set of "obvious" plays that override policy scoring entirely.
/// The linear scorer can blunder on positions that have a clear correct
/// answer (e.g. Greedy refusing to play a quad that would end the round
/// because cardsCleared is weighted negatively in its preset). These rules
/// fire as a fast-path inside `PolicyOpponent.move(...)` and
/// `LookaheadOpponent.move(...)` before any softmax sampling or lookahead
/// runs — applied uniformly across all difficulties so refs and subjects
/// both benefit.
public enum TacticalRules {

    /// Returns a forced move if any tactical rule applies, else `nil`.
    /// `candidates` should already be the legal-move set for `playerID`.
    public static func forcedMove(
        for playerID: PlayerID, in state: GameState, candidates: [Move]
    ) -> Move? {
        guard let me = state.players.first(where: { $0.id == playerID }) else { return nil }

        // Rule A: Round-ending play.
        // If any candidate empties our hand, play it. Even strong heuristics
        // (e.g. Greedy with negative cardsCleared, or ComboKeeper saving a
        // pair) can score a non-ending move higher than the ending one.
        // Going out is the entire point of the round, so always close.
        let myHandSize = me.hand.count
        if myHandSize > 0 {
            for move in candidates {
                if case .play(let cards, _) = move, cards.count == myHandSize {
                    return move
                }
            }
        }

        // Rule B: 3-Spade reversal.
        // If a solo Joker is on the trick and we hold the 3 of Spades and
        // the rule is enabled, the reversal is a free trick win — there's no
        // scenario where saving the 3♠ for later beats taking the trick now.
        if state.ruleSet.threeSpadeReversal, state.ruleSet.jokers,
           let lastHand = state.currentTrick.last, lastHand.isSoloJoker,
           me.hand.contains(.regular(.three, .spades)) {
            for move in candidates {
                if case .play(let cards, _) = move, cards == [.regular(.three, .spades)] {
                    return move
                }
            }
        }

        return nil
    }
}
