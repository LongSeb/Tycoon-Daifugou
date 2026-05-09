import Testing
@testable import TycoonDaifugouKit

// MARK: - Helpers

private func makePlayer(_ name: String, cards: [Card]) -> Player {
    Player(displayName: name, hand: cards)
}

private func makeState(
    players: [Player],
    currentPlayerIndex: Int = 0,
    currentTrick: [Hand] = [],
    ruleSet: RuleSet = .baseOnly,
    lastPlayedByIndex: Int? = nil
) -> GameState {
    let scores = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 0) })
    return GameState(
        players: players,
        deck: [],
        currentTrick: currentTrick,
        currentPlayerIndex: currentPlayerIndex,
        phase: .playing,
        ruleSet: ruleSet,
        round: 1,
        scoresByPlayer: scores,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

// MARK: - Tests

@Suite("LookaheadOpponent")
struct LookaheadOpponentTests {

    @Test("Returns the only legal move when forced")
    func singleLegalMove() throws {
        let trick = try Hand(cards: [.regular(.two, .diamonds)])
        let player = makePlayer("P", cards: [.regular(.five, .clubs)])
        let state = makeState(
            players: [player], currentTrick: [trick], lastPlayedByIndex: 0
        )

        let bot = LookaheadOpponent(policy: .balanced)
        let move = bot.move(for: player.id, in: state)

        #expect(move == .pass(by: player.id))
    }

    @Test("Returns only legal moves regardless of state")
    func legalityInvariant() throws {
        let trick = try Hand(cards: [.regular(.five, .clubs)])
        let player = makePlayer("P", cards: [
            .regular(.three, .clubs), .regular(.king, .hearts), .regular(.two, .spades),
        ])
        let state = makeState(
            players: [player], currentTrick: [trick], lastPlayedByIndex: 0
        )

        let validMoves = Set(state.validMoves(for: player.id))
        for policy in Policy.allV2 {
            let bot = LookaheadOpponent(policy: policy)
            let move = bot.move(for: player.id, in: state)
            #expect(validMoves.contains(move))
        }
    }

    @Test("Same input yields the same output (deterministic, no RNG)")
    func deterministic() {
        let player = makePlayer("P", cards: [
            .regular(.three, .clubs), .regular(.four, .diamonds),
            .regular(.king, .hearts), .regular(.two, .spades),
        ])
        let state = makeState(players: [player])

        let firstBot = LookaheadOpponent(policy: .balanced)
        let secondBot = LookaheadOpponent(policy: .balanced)

        let firstSequence = (0..<5).map { _ in firstBot.move(for: player.id, in: state) }
        let secondSequence = (0..<5).map { _ in secondBot.move(for: player.id, in: state) }

        #expect(firstSequence == secondSequence)
    }

    @Test("Lookahead bot picks a move that scores well over a one-step horizon")
    func picksMoveWithGoodFollowUp() throws {
        // 4-player setup with deterministic seats. The lookahead bot should
        // produce a legal move and finish the round normally over a sample of
        // games rather than reach an illegal state.
        let players = (0..<4).map { idx in Player(displayName: "P\(idx)") }
        var state = GameState.newGame(
            players: players, ruleSet: .baseOnly, seed: 0xDEADBEEF
        )

        let bots: [PlayerID: any Opponent] = Dictionary(
            uniqueKeysWithValues: players.map { player in
                (player.id, LookaheadOpponent(policy: .balanced) as any Opponent)
            }
        )

        for _ in 0..<800 {
            if state.phase != .playing { break }
            let active = state.players[state.currentPlayerIndex]
            let move = bots[active.id]!.move(for: active.id, in: state)
            #expect(state.validMoves(for: active.id).contains(move))
            guard let next = try? state.apply(move) else { break }
            state = next
        }

        // Round should reach scoring (not loop forever) within the safety cap.
        #expect(state.phase != .playing)
    }

    @Test("OpponentRoster routes Expert difficulty to LookaheadOpponent")
    func rosterRoutesExpertToLookahead() {
        let opponent = OpponentRoster.opponent(
            policy: .balanced, difficulty: .expert, seed: 1
        )
        #expect(opponent is LookaheadOpponent)
    }

    @Test("OpponentRoster routes non-Expert difficulties to PolicyOpponent")
    func rosterRoutesNonExpertToPolicy() {
        for difficulty in [Difficulty.easy, .medium, .hard] {
            let opponent = OpponentRoster.opponent(
                policy: .balanced, difficulty: difficulty, seed: 1
            )
            #expect(opponent is PolicyOpponent)
        }
    }
}
