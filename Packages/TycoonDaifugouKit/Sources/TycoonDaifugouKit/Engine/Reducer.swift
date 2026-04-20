import Foundation

// MARK: - GameError

public enum GameError: Error, Sendable, Equatable {
    case notYourTurn
    case cardsNotInHand
    case handTypeMismatch
    case notStrongerThanCurrent
    case invalidHand(HandError)
    case wrongPhase
    case noSuchTrade
    case wrongCardCount(expected: Int, got: Int)
    case mustGiveStrongestCards
    case mustCompletePartnerTrade
}

// MARK: - Reducer

extension GameState {

    /// Applies `move` to the current state and returns the resulting state.
    /// Throws `GameError` for any rule violation.
    public func apply(_ move: Move) throws -> GameState {
        switch move {
        case .play(let cards, let by):
            return try applyPlay(cards: cards, by: by)
        case .pass(let by):
            return try applyPass(by: by)
        case .trade(let cards, let from, let to):
            return try applyTrade(cards: cards, from: from, to: to)
        }
    }

    /// All legal `Move`s the given player may make right now.
    /// Returns `[]` if it is not `playerID`'s turn or the round has ended.
    /// Pass is omitted when the trick is empty — the leader must play.
    public func validMoves(for playerID: PlayerID) -> [Move] {
        guard phase == .playing else { return [] }
        guard players[currentPlayerIndex].id == playerID else { return [] }
        let player = players[currentPlayerIndex]
        var moves: [Move] = []

        if !currentTrick.isEmpty {
            moves.append(.pass(by: playerID))
        }

        let nonJokers = player.hand.filter { !$0.isJoker }
        let byRank = Dictionary(grouping: nonJokers) { $0.rank! }
        let jokerCards = ruleSet.jokers ? player.hand.filter { $0.isJoker } : []

        if let lastHand = currentTrick.last {
            let size = lastHand.type.rawValue
            for (rank, cards) in byRank
                where Revolution.isStronger(rank, than: lastHand.rank, revolutionActive: isRevolutionActive)
                    && cards.count >= size {
                for combo in combinations(of: cards, count: size) {
                    moves.append(.play(cards: combo, by: playerID))
                }
            }
            if lastHand.type == .single {
                for joker in jokerCards {
                    moves.append(.play(cards: [joker], by: playerID))
                }
                if lastHand.isSoloJoker && ruleSet.threeSpadeReversal && ruleSet.jokers
                    && !isRevolutionActive {
                    let threeSpades = Card.regular(.three, .spades)
                    if player.hand.contains(threeSpades) {
                        moves.append(.play(cards: [threeSpades], by: playerID))
                    }
                }
            }
        } else {
            for (_, cards) in byRank {
                for size in 1...min(cards.count, 4) {
                    for combo in combinations(of: cards, count: size) {
                        moves.append(.play(cards: combo, by: playerID))
                    }
                }
            }
            for joker in jokerCards {
                moves.append(.play(cards: [joker], by: playerID))
            }
        }

        return moves
    }
}

// MARK: - Private helpers

extension GameState {

    private func applyPlay(cards: [Card], by: PlayerID) throws -> GameState {
        guard players[currentPlayerIndex].id == by else { throw GameError.notYourTurn }

        let playerIndex = currentPlayerIndex
        let player = players[playerIndex]

        let updatedPlayer: Player
        do { updatedPlayer = try player.removing(cards) } catch { throw GameError.cardsNotInHand }

        let newHand: Hand
        do {
            newHand = try Hand(cards: cards)
        } catch let handErr as HandError {
            throw GameError.invalidHand(handErr)
        } catch {
            throw GameError.invalidHand(.mixedRanks)
        }

        if newHand.isSoloJoker && !ruleSet.jokers { throw GameError.invalidHand(.allJokers) }

        let newRevolutionActive = Revolution.newState(
            active: isRevolutionActive, after: newHand, ruleEnabled: ruleSet.revolution)

        let trickTop = currentTrick.last
        if let lastHand = trickTop {
            guard newHand.type == lastHand.type else { throw GameError.handTypeMismatch }
            let isReversal = ThreeSpadeReversal.triggers(newHand: newHand, onto: lastHand, ruleSet: ruleSet)
            if !isReversal {
                let isStronger = Joker.isSoloStronger(newHand: newHand, ruleEnabled: ruleSet.jokers)
                    || Revolution.isStronger(newHand, than: lastHand, revolutionActive: isRevolutionActive)
                guard isStronger else { throw GameError.notStrongerThanCurrent }
            }
        }

        var newPlayers = players
        newPlayers[playerIndex] = updatedPlayer
        let updatedScores = scoresByPlayer

        if updatedPlayer.hand.isEmpty {
            return applyFinish(
                playerIndex: playerIndex,
                newHand: newHand,
                newRevolutionActive: newRevolutionActive,
                newPlayers: newPlayers,
                updatedScores: updatedScores
            )
        }

        let nextIndex = nextActive(after: playerIndex, in: newPlayers)

        if EightStop.triggers(hand: newHand, ruleEnabled: ruleSet.eightStop) {
            return trickCleared(newHand: newHand, leadIndex: playerIndex, players: newPlayers,
                scores: updatedScores, revolutionActive: newRevolutionActive)
        }

        if let trickTop, ThreeSpadeReversal.triggers(newHand: newHand, onto: trickTop, ruleSet: ruleSet) {
            return trickCleared(newHand: newHand, leadIndex: playerIndex, players: newPlayers,
                scores: updatedScores, revolutionActive: newRevolutionActive)
        }

        return GameState(
            players: newPlayers,
            deck: deck,
            currentTrick: currentTrick + [newHand],
            currentPlayerIndex: nextIndex,
            phase: phase,
            ruleSet: ruleSet,
            isRevolutionActive: newRevolutionActive,
            round: round,
            scoresByPlayer: updatedScores,
            passCountSinceLastPlay: 0,
            lastPlayedByIndex: playerIndex,
            playedPile: playedPile,
            defendingMillionaireID: defendingMillionaireID
        )
    }

    /// Handles the case where the current player just played their last card.
    /// Assigns titles, fires bankruptcy if applicable, and returns either a
    /// `.roundEnded` state or a continuation state with the active players remaining.
    private func applyFinish(
        playerIndex: Int,
        newHand: Hand,
        newRevolutionActive: Bool,
        newPlayers: [Player],
        updatedScores: [PlayerID: Int]
    ) -> GameState {
        var newPlayers = newPlayers
        var updatedScores = updatedScores

        let finishPosition = newPlayers.filter { $0.currentTitle != nil }.count
        let titleForPlayer = Scoring.title(forFinishPosition: finishPosition, playerCount: newPlayers.count)
        newPlayers[playerIndex] = newPlayers[playerIndex].withTitle(titleForPlayer)
        updatedScores[newPlayers[playerIndex].id, default: 0] += Scoring.xp(for: titleForPlayer)

        if Bankruptcy.shouldTrigger(
            finishPosition: finishPosition,
            finishedPlayerID: newPlayers[playerIndex].id,
            defendingMillionaireID: defendingMillionaireID,
            ruleSet: ruleSet,
            playerCount: newPlayers.count
        ), let bankruptIdx = newPlayers.firstIndex(where: { $0.id == defendingMillionaireID }) {
            newPlayers[bankruptIdx] = newPlayers[bankruptIdx].withBankruptcy()
        }

        let nonBankruptUntitled = newPlayers.indices.filter {
            newPlayers[$0].currentTitle == nil && !newPlayers[$0].isBankrupt
        }

        if nonBankruptUntitled.count <= 1 {
            if let lastIdx = nonBankruptUntitled.first {
                let lastPos = newPlayers.filter { $0.currentTitle != nil }.count
                let lastTitle = Scoring.title(forFinishPosition: lastPos, playerCount: newPlayers.count)
                newPlayers[lastIdx] = newPlayers[lastIdx].withTitle(lastTitle)
                updatedScores[newPlayers[lastIdx].id, default: 0] += Scoring.xp(for: lastTitle)
            }
            if let bkIdx = newPlayers.firstIndex(where: { $0.isBankrupt && $0.currentTitle == nil }) {
                let bkID = newPlayers[bkIdx].id
                newPlayers[bkIdx] = newPlayers[bkIdx].withTitle(.beggar)
                updatedScores[bkID, default: 0] += Scoring.xp(for: .beggar)
            }
            return GameState(
                players: newPlayers,
                deck: deck,
                currentTrick: [],
                currentPlayerIndex: currentPlayerIndex,
                phase: .roundEnded,
                ruleSet: ruleSet,
                isRevolutionActive: newRevolutionActive,
                round: round,
                scoresByPlayer: updatedScores,
                passCountSinceLastPlay: 0,
                lastPlayedByIndex: nil,
                playedPile: playedPile + currentTrick.flatMap { $0.cards } + newHand.cards
            )
        }

        let nextIdx = nextActive(after: playerIndex, in: newPlayers)
        return GameState(
            players: newPlayers,
            deck: deck,
            currentTrick: currentTrick + [newHand],
            currentPlayerIndex: nextIdx,
            phase: phase,
            ruleSet: ruleSet,
            isRevolutionActive: newRevolutionActive,
            round: round,
            scoresByPlayer: updatedScores,
            passCountSinceLastPlay: 0,
            lastPlayedByIndex: playerIndex,
            playedPile: playedPile,
            defendingMillionaireID: defendingMillionaireID
        )
    }

    private func applyPass(by: PlayerID) throws -> GameState {
        guard players[currentPlayerIndex].id == by else { throw GameError.notYourTurn }

        let newPassCount = passCountSinceLastPlay + 1
        let lastIdx = lastPlayedByIndex ?? currentPlayerIndex
        // Exclude bankrupt players from the active-other count so the pass chain
        // resets correctly even when a bankrupt player still holds cards.
        let activeOtherCount = players.indices.filter {
            $0 != lastIdx && !players[$0].hand.isEmpty && !players[$0].isBankrupt
        }.count

        if newPassCount >= activeOtherCount {
            // Trick resets. If the last-to-play is out or bankrupt, pass the
            // lead to the next eligible player.
            let winnerIdx: Int
            if players[lastIdx].hand.isEmpty || players[lastIdx].isBankrupt {
                winnerIdx = nextActive(after: lastIdx, in: players)
            } else {
                winnerIdx = lastIdx
            }
            return GameState(
                players: players,
                deck: deck,
                currentTrick: [],
                currentPlayerIndex: winnerIdx,
                phase: phase,
                ruleSet: ruleSet,
                isRevolutionActive: isRevolutionActive,
                round: round,
                scoresByPlayer: scoresByPlayer,
                passCountSinceLastPlay: 0,
                lastPlayedByIndex: nil,
                playedPile: playedPile + currentTrick.flatMap { $0.cards },
                defendingMillionaireID: defendingMillionaireID
            )
        } else {
            let nextIdx = nextActive(after: currentPlayerIndex, in: players)
            return GameState(
                players: players,
                deck: deck,
                currentTrick: currentTrick,
                currentPlayerIndex: nextIdx,
                phase: phase,
                ruleSet: ruleSet,
                isRevolutionActive: isRevolutionActive,
                round: round,
                scoresByPlayer: scoresByPlayer,
                passCountSinceLastPlay: newPassCount,
                lastPlayedByIndex: lastPlayedByIndex,
                playedPile: playedPile,
                defendingMillionaireID: defendingMillionaireID
            )
        }
    }

    /// Returns a new state where the current trick is cleared and `leadIndex` gets the lead.
    /// Used by rules that end a trick mid-play (8-Stop, 3-Spade Reversal).
    private func trickCleared(
        newHand: Hand,
        leadIndex: Int,
        players newPlayers: [Player],
        scores updatedScores: [PlayerID: Int],
        revolutionActive newRevolutionActive: Bool
    ) -> GameState {
        GameState(
            players: newPlayers,
            deck: deck,
            currentTrick: [],
            currentPlayerIndex: leadIndex,
            phase: phase,
            ruleSet: ruleSet,
            isRevolutionActive: newRevolutionActive,
            round: round,
            scoresByPlayer: updatedScores,
            passCountSinceLastPlay: 0,
            lastPlayedByIndex: nil,
            playedPile: playedPile + currentTrick.flatMap { $0.cards } + newHand.cards,
            defendingMillionaireID: defendingMillionaireID
        )
    }

    private func nextActive(after index: Int, in playerList: [Player]) -> Int {
        for offset in 1...playerList.count {
            let candidate = (index + offset) % playerList.count
            if !playerList[candidate].hand.isEmpty && !playerList[candidate].isBankrupt {
                return candidate
            }
        }
        return index
    }
}

// MARK: - Combination utility

private func combinations<T>(of array: [T], count: Int) -> [[T]] {
    guard count > 0, count <= array.count else { return count == 0 ? [[]] : [] }
    if count == array.count { return [array] }
    if count == 1 { return array.map { [$0] } }
    var result: [[T]] = []
    for idx in 0...(array.count - count) {
        let sub = combinations(of: Array(array[(idx + 1)...]), count: count - 1)
        for combo in sub { result.append([array[idx]] + combo) }
    }
    return result
}
