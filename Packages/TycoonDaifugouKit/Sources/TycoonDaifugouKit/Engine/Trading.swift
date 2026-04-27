import Foundation

// MARK: - RequiredTrade

/// One pending card exchange in the trading phase.
public struct RequiredTrade: Sendable, Equatable {
    /// The player giving cards.
    public let from: PlayerID
    /// The player receiving cards.
    public let to: PlayerID
    /// Number of cards to exchange.
    public let cardCount: Int
    /// When `true`, `from` must give their strongest `cardCount` cards (no choice).
    /// When `false`, `from` may give any `cardCount` cards.
    public let mustGiveStrongest: Bool
}

// MARK: - requiredTrades(for:)

/// Returns the list of trades still pending in `state`. Empty outside `.trading`.
public func requiredTrades(for state: GameState) -> [RequiredTrade] {
    state.pendingTrades
}

// MARK: - GameState + startNextRound

extension GameState {

    /// Deals fresh hands for all players (preserving identities and previous-round
    /// titles), computes required trades, and transitions to `.trading`.
    /// Must be called from `.roundEnded`; crashes otherwise.
    public func startNextRound(seed: UInt64) -> GameState {
        precondition(phase == .roundEnded, "startNextRound called outside .roundEnded")

        var rng = Xoshiro256StarStar(seed: seed)
        var shuffledDeck = Deck.deck(withJokers: ruleSet.jokerCount)
        rng.shuffle(&shuffledDeck)

        let total = shuffledDeck.count
        let base = total / players.count
        let leftover = total % players.count

        var dealtPlayers: [Player] = []
        var offset = 0
        for (seatIndex, player) in players.enumerated() {
            let handSize = base + (seatIndex < leftover ? 1 : 0)
            let newHand = Array(shuffledDeck[offset..<offset + handSize])
            dealtPlayers.append(
                Player(
                    id: player.id,
                    displayName: player.displayName,
                    hand: newHand,
                    currentTitle: player.currentTitle,
                    previousTitle: player.currentTitle
                )
            )
            offset += handSize
        }

        let trades = Self.computePendingTrades(players: dealtPlayers)
        let newPhase: GamePhase = trades.isEmpty ? .playing : .trading

        let startIndex: Int
        if newPhase == .playing {
            // Rounds 2+: Beggar leads. Fall back to seat 0 if titles aren't set (shouldn't happen).
            startIndex = dealtPlayers.firstIndex { $0.currentTitle == .beggar } ?? 0
        } else {
            startIndex = 0
        }

        // Record the previous round's Millionaire so the Bankruptcy rule can track
        // whether they defend their title in the new round.
        let defending: PlayerID? = {
            guard Bankruptcy.isApplicable(ruleSet: ruleSet, playerCount: players.count) else { return nil }
            return players.first(where: { $0.currentTitle == .millionaire })?.id
        }()

        return GameState(
            players: dealtPlayers,
            deck: shuffledDeck,
            currentTrick: [],
            currentPlayerIndex: startIndex,
            phase: newPhase,
            ruleSet: ruleSet,
            isRevolutionActive: false,
            round: round + 1,
            scoresByPlayer: scoresByPlayer,
            pendingTrades: trades,
            defendingMillionaireID: defending
        )
    }

    /// Computes the ordered list of pending trades from the titles currently held
    /// by `players`. Lower-ranked players give first (mustGiveStrongest), then
    /// upper-ranked give back (any cards).
    static func computePendingTrades(players: [Player]) -> [RequiredTrade] {
        guard
            let millionaire = players.first(where: { $0.currentTitle == .millionaire }),
            let beggar = players.first(where: { $0.currentTitle == .beggar })
        else {
            return []
        }

        var trades: [RequiredTrade] = [
            RequiredTrade(from: beggar.id, to: millionaire.id, cardCount: 2, mustGiveStrongest: true),
        ]

        let rich = players.first(where: { $0.currentTitle == .rich })
        let poor = players.first(where: { $0.currentTitle == .poor })

        if let rich, let poor {
            trades.append(RequiredTrade(from: poor.id, to: rich.id, cardCount: 1, mustGiveStrongest: true))
        }

        trades.append(RequiredTrade(from: millionaire.id, to: beggar.id, cardCount: 2, mustGiveStrongest: false))

        if let rich, let poor {
            trades.append(RequiredTrade(from: rich.id, to: poor.id, cardCount: 1, mustGiveStrongest: false))
        }

        return trades
    }
}

// MARK: - GameState + applyTrade

extension GameState {

    func applyTrade(cards: [Card], from: PlayerID, to: PlayerID) throws -> GameState {
        guard phase == .trading else {
            throw GameError.wrongPhase
        }

        guard let tradeIndex = pendingTrades.firstIndex(where: { $0.from == from && $0.to == to }) else {
            throw GameError.noSuchTrade
        }
        let trade = pendingTrades[tradeIndex]

        guard cards.count == trade.cardCount else {
            throw GameError.wrongCardCount(expected: trade.cardCount, got: cards.count)
        }

        // Upper-ranked player cannot give back until lower-ranked has given first.
        if !trade.mustGiveStrongest {
            let lowerStillPending = pendingTrades.contains { $0.from == to && $0.to == from }
            if lowerStillPending {
                throw GameError.mustCompletePartnerTrade
            }
        }

        guard
            let fromIndex = players.firstIndex(where: { $0.id == from }),
            let toIndex = players.firstIndex(where: { $0.id == to })
        else {
            throw GameError.noSuchTrade
        }

        let fromPlayer = players[fromIndex]
        let updatedFromPlayer: Player
        do {
            updatedFromPlayer = try fromPlayer.removing(cards)
        } catch {
            throw GameError.cardsNotInHand
        }

        if trade.mustGiveStrongest {
            try validateStrongest(cards, fromHand: fromPlayer.hand)
        }

        var newPlayers = players
        newPlayers[fromIndex] = updatedFromPlayer
        newPlayers[toIndex] = players[toIndex].adding(cards)

        var newPending = pendingTrades
        newPending.remove(at: tradeIndex)

        if newPending.isEmpty {
            // Beggar leads after trading; find them before titles are cleared.
            let startIndex = newPlayers.firstIndex { $0.currentTitle == .beggar } ?? 0
            let cleared = newPlayers.map {
                Player(
                    id: $0.id, displayName: $0.displayName, hand: $0.hand,
                    currentTitle: nil, previousTitle: $0.previousTitle
                )
            }
            return GameState(
                players: cleared,
                deck: deck,
                currentTrick: [],
                currentPlayerIndex: startIndex,
                phase: .playing,
                ruleSet: ruleSet,
                isRevolutionActive: false,
                round: round,
                scoresByPlayer: scoresByPlayer,
                pendingTrades: [],
                defendingMillionaireID: defendingMillionaireID
            )
        } else {
            return GameState(
                players: newPlayers,
                deck: deck,
                currentTrick: [],
                currentPlayerIndex: currentPlayerIndex,
                phase: .trading,
                ruleSet: ruleSet,
                isRevolutionActive: false,
                round: round,
                scoresByPlayer: scoresByPlayer,
                pendingTrades: newPending,
                defendingMillionaireID: defendingMillionaireID
            )
        }
    }

    /// Validates that the minimum strength among `cards` is not less than the
    /// maximum strength of any card in `hand` that is not being given.
    /// Jokers count as the strongest cards.
    private func validateStrongest(_ cards: [Card], fromHand hand: [Card]) throws {
        let minGiven = cards.map(\.tradingStrength).min() ?? 0
        let notGiven = hand.filter { !cards.contains($0) }
        let maxKept = notGiven.map(\.tradingStrength).max() ?? -1
        if minGiven < maxKept {
            throw GameError.mustGiveStrongestCards
        }
    }
}

// MARK: - Card trading strength

extension Card {
    /// Numeric strength used only for trading validation. Jokers outrank all regular cards.
    var tradingStrength: Int {
        switch self {
        case .joker: return Int.max
        case .regular(let rank, _): return rank.rawValue
        }
    }
}
