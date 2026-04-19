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

        if let lastHand = currentTrick.last {
            let size = lastHand.type.rawValue
            for (rank, cards) in byRank where rank > lastHand.rank && cards.count >= size {
                for combo in combinations(of: cards, count: size) {
                    moves.append(.play(cards: combo, by: playerID))
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
        }

        return moves
    }
}

// MARK: - Private helpers

extension GameState {

    private func applyPlay(cards: [Card], by: PlayerID) throws -> GameState {
        guard players[currentPlayerIndex].id == by else {
            throw GameError.notYourTurn
        }

        let playerIndex = currentPlayerIndex
        let player = players[playerIndex]

        let updatedPlayer: Player
        do {
            updatedPlayer = try player.removing(cards)
        } catch {
            throw GameError.cardsNotInHand
        }

        let newHand: Hand
        do {
            newHand = try Hand(cards: cards)
        } catch let handErr as HandError {
            throw GameError.invalidHand(handErr)
        } catch {
            throw GameError.invalidHand(.mixedRanks)
        }

        if let lastHand = currentTrick.last {
            guard newHand.type == lastHand.type else {
                throw GameError.handTypeMismatch
            }
            guard newHand > lastHand else {
                throw GameError.notStrongerThanCurrent
            }
        }

        var newPlayers = players
        newPlayers[playerIndex] = updatedPlayer
        var updatedScores = scoresByPlayer

        if updatedPlayer.hand.isEmpty {
            let finishPosition = newPlayers.filter { $0.currentTitle != nil }.count
            let titleForPlayer = Scoring.title(forFinishPosition: finishPosition, playerCount: newPlayers.count)
            newPlayers[playerIndex] = updatedPlayer.withTitle(titleForPlayer)
            updatedScores[updatedPlayer.id, default: 0] += Scoring.xp(for: titleForPlayer)

            let remainingIndices = newPlayers.indices.filter { newPlayers[$0].currentTitle == nil }
            if remainingIndices.count == 1 {
                let lastIdx = remainingIndices[0]
                let lastPlayerID = newPlayers[lastIdx].id
                newPlayers[lastIdx] = newPlayers[lastIdx].withTitle(.beggar)
                updatedScores[lastPlayerID, default: 0] += Scoring.xp(for: .beggar)
                return GameState(
                    players: newPlayers,
                    deck: deck,
                    currentTrick: [],
                    currentPlayerIndex: currentPlayerIndex,
                    phase: .roundEnded,
                    ruleSet: ruleSet,
                    isRevolutionActive: isRevolutionActive,
                    round: round,
                    scoresByPlayer: updatedScores,
                    passCountSinceLastPlay: 0,
                    lastPlayedByIndex: nil,
                    playedPile: playedPile + currentTrick.flatMap { $0.cards } + newHand.cards
                )
            }
        }

        let nextIndex = nextActive(after: playerIndex, in: newPlayers)
        return GameState(
            players: newPlayers,
            deck: deck,
            currentTrick: currentTrick + [newHand],
            currentPlayerIndex: nextIndex,
            phase: phase,
            ruleSet: ruleSet,
            isRevolutionActive: isRevolutionActive,
            round: round,
            scoresByPlayer: updatedScores,
            passCountSinceLastPlay: 0,
            lastPlayedByIndex: playerIndex,
            playedPile: playedPile
        )
    }

    private func applyPass(by: PlayerID) throws -> GameState {
        guard players[currentPlayerIndex].id == by else {
            throw GameError.notYourTurn
        }

        let newPassCount = passCountSinceLastPlay + 1
        let lastIdx = lastPlayedByIndex ?? currentPlayerIndex
        let activeOtherCount = players.indices.filter {
            $0 != lastIdx && !players[$0].hand.isEmpty
        }.count

        if newPassCount >= activeOtherCount {
            let winnerIdx = players[lastIdx].hand.isEmpty
                ? nextActive(after: lastIdx, in: players)
                : lastIdx
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
                playedPile: playedPile + currentTrick.flatMap { $0.cards }
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
                playedPile: playedPile
            )
        }
    }

    private func nextActive(after index: Int, in playerList: [Player]) -> Int {
        for offset in 1...playerList.count {
            let candidate = (index + offset) % playerList.count
            if !playerList[candidate].hand.isEmpty { return candidate }
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
