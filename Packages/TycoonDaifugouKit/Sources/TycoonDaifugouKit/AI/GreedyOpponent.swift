// MARK: - GreedyOpponent

/// An opponent that always plays the weakest legal hand to conserve strong cards.
///
/// On a trick lead it prefers smaller hand types (single > pair > triple > quad)
/// and within a type plays the weakest rank. On an active trick it plays the
/// weakest rank that still beats the current top, falling back to pass. Jokers
/// are reserved as a last resort: any non-Joker play is preferred.
public struct GreedyOpponent: Opponent {

    public init() {}

    public func move(for playerID: PlayerID, in state: GameState) -> Move {
        let allMoves = state.validMoves(for: playerID)

        let plays: [(cards: [Card], hand: Hand)] = allMoves.compactMap { move in
            guard case .play(let cards, _) = move,
                let hand = try? Hand(cards: cards) else { return nil }
            return (cards, hand)
        }

        let nonJokerPlays = plays.filter { option in
            option.cards.allSatisfy { !$0.isJoker }
        }
        let candidates = nonJokerPlays.isEmpty ? plays : nonJokerPlays

        if state.currentTrick.isEmpty {
            // Lead: smallest hand type first, then weakest rank within type.
            let sorted = candidates.sorted { lhs, rhs in
                if lhs.cards.count != rhs.cards.count {
                    return lhs.cards.count < rhs.cards.count
                }
                return isWeaker(lhs.hand, than: rhs.hand, revolutionActive: state.isRevolutionActive)
            }
            if let best = sorted.first {
                return .play(cards: best.cards, by: playerID)
            }
        } else {
            // Active trick: play weakest beater; validMoves already filtered to legal plays.
            let sorted = candidates.sorted { lhs, rhs in
                isWeaker(lhs.hand, than: rhs.hand, revolutionActive: state.isRevolutionActive)
            }
            if let best = sorted.first {
                return .play(cards: best.cards, by: playerID)
            }
        }

        return .pass(by: playerID)
    }

    /// Returns true if `lhs` is weaker (cheaper to spend) than `rhs`.
    /// Under revolution lower rawValue is stronger, so higher rawValue is weaker.
    private func isWeaker(_ lhs: Hand, than rhs: Hand, revolutionActive: Bool) -> Bool {
        if lhs.isSoloJoker && rhs.isSoloJoker { return false }
        if lhs.isSoloJoker { return false }
        if rhs.isSoloJoker { return true }
        return revolutionActive
            ? lhs.rank.rawValue > rhs.rank.rawValue
            : lhs.rank.rawValue < rhs.rank.rawValue
    }
}
