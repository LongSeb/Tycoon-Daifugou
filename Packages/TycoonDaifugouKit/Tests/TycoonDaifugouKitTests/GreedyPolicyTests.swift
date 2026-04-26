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
    isRevolutionActive: Bool = false,
    passCount: Int = 0,
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
        isRevolutionActive: isRevolutionActive,
        round: 1,
        scoresByPlayer: scores,
        passCountSinceLastPlay: passCount,
        lastPlayedByIndex: lastPlayedByIndex
    )
}

// MARK: - Tests

@Suite("Greedy policy")
struct GreedyPolicyTests {

    /// Argmax greedy bot — same scenarios that previously validated the legacy
    /// `GreedyOpponent` struct now validate the `Policy.greedy` weight vector
    /// at τ = 0. Behavior under these scenarios is the spec for what "greedy"
    /// means in the new framework.
    let greedy = PolicyOpponent(policy: .greedy, temperature: 0, seed: 1)

    // MARK: Trick lead

    @Test("Leads trick with lowest single when holding multiple singles")
    func leadsTrickWithLowestSingle() {
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs), .regular(.king, .diamonds)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let state = makeState(players: [p0, p1])

        let move = greedy.move(for: p0.id, in: state)

        guard case .play(let cards, let by) = move else {
            Issue.record("Expected .play, got \(move)")
            return
        }
        #expect(by == p0.id)
        #expect(cards == [.regular(.five, .clubs)])
    }

    @Test("Prefers single over pair when leading a trick")
    func prefersSingleOverPairOnLead() throws {
        let p0 = makePlayer("P0", cards: [
            .regular(.five, .clubs), .regular(.five, .diamonds), .regular(.king, .hearts),
        ])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let state = makeState(players: [p0, p1])

        let move = greedy.move(for: p0.id, in: state)

        guard case .play(let cards, _) = move else {
            Issue.record("Expected .play, got \(move)")
            return
        }
        #expect(cards.count == 1)
        let hand = try Hand(cards: cards)
        #expect(hand.rank == .five)
    }

    @Test("Leads trick with only card when holding a single card")
    func leadsTrickWithOnlyCard() {
        let p0 = makePlayer("P0", cards: [.regular(.queen, .hearts)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let state = makeState(players: [p0, p1])

        let move = greedy.move(for: p0.id, in: state)

        #expect(move == .play(cards: [.regular(.queen, .hearts)], by: p0.id))
    }

    @Test("Conserves Joker when a non-Joker lead is available")
    func conservesJokerWhenLeading() {
        let jokerRuleSet = RuleSet(
            revolution: false, eightStop: false, jokers: true,
            threeSpadeReversal: false, bankruptcy: false, jokerCount: 1
        )
        let p0 = makePlayer("P0", cards: [.regular(.three, .diamonds), .joker(index: 0)])
        let p1 = makePlayer("P1", cards: [.regular(.seven, .clubs)])
        let state = makeState(players: [p0, p1], ruleSet: jokerRuleSet)

        let move = greedy.move(for: p0.id, in: state)

        #expect(move == .play(cards: [.regular(.three, .diamonds)], by: p0.id))
    }

    // MARK: Active trick

    @Test("Plays lowest valid beater on an active single trick")
    func playsLowestBeaterOnActiveTrick() throws {
        let trickCard = Card.regular(.five, .clubs)
        let trick = try Hand(cards: [trickCard])
        let p0 = makePlayer("P0", cards: [.regular(.king, .hearts), .regular(.ace, .spades)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 0,
            currentTrick: [trick],
            lastPlayedByIndex: 1
        )

        let move = greedy.move(for: p0.id, in: state)

        #expect(move == .play(cards: [.regular(.king, .hearts)], by: p0.id))
    }

    @Test("Plays lowest valid pair on an active pair trick")
    func playsLowestValidPairOnPairTrick() throws {
        let trick = try Hand(cards: [.regular(.five, .clubs), .regular(.five, .diamonds)])
        let p0 = makePlayer("P0", cards: [
            .regular(.seven, .clubs), .regular(.seven, .diamonds),
            .regular(.eight, .hearts), .regular(.eight, .spades),
        ])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 0,
            currentTrick: [trick],
            lastPlayedByIndex: 1
        )

        let move = greedy.move(for: p0.id, in: state)

        guard case .play(let cards, _) = move else {
            Issue.record("Expected .play, got \(move)")
            return
        }
        #expect(cards.count == 2)
        let hand = try Hand(cards: cards)
        #expect(hand.rank == .seven)
    }

    @Test("Passes when no cards can beat the current trick")
    func passesWhenNoBeatersAvailable() throws {
        let trick = try Hand(cards: [.regular(.two, .diamonds)])
        let p0 = makePlayer("P0", cards: [.regular(.five, .clubs)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 0,
            currentTrick: [trick],
            lastPlayedByIndex: 1
        )

        let move = greedy.move(for: p0.id, in: state)

        #expect(move == .pass(by: p0.id))
    }

    @Test("Prefers non-Joker play when both a regular card and Joker can beat the trick")
    func prefersNonJokerOverJokerBeater() throws {
        let jokerRuleSet = RuleSet(
            revolution: false, eightStop: false, jokers: true,
            threeSpadeReversal: false, bankruptcy: false, jokerCount: 1
        )
        let trick = try Hand(cards: [.regular(.five, .clubs)])
        let p0 = makePlayer("P0", cards: [.regular(.king, .hearts), .joker(index: 0)])
        let p1 = makePlayer("P1", cards: [.regular(.three, .spades)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 0,
            currentTrick: [trick],
            ruleSet: jokerRuleSet,
            lastPlayedByIndex: 1
        )

        let move = greedy.move(for: p0.id, in: state)

        #expect(move == .play(cards: [.regular(.king, .hearts)], by: p0.id))
    }

    @Test("Uses Joker when it is the only card that can beat the trick")
    func usesJokerWhenOnlyOptionToBeat() throws {
        let jokerRuleSet = RuleSet(
            revolution: false, eightStop: false, jokers: true,
            threeSpadeReversal: false, bankruptcy: false, jokerCount: 1
        )
        let trick = try Hand(cards: [.regular(.ace, .diamonds)])
        let p0 = makePlayer("P0", cards: [.regular(.three, .clubs), .joker(index: 0)])
        let p1 = makePlayer("P1", cards: [.regular(.seven, .spades)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 0,
            currentTrick: [trick],
            ruleSet: jokerRuleSet,
            lastPlayedByIndex: 1
        )

        let move = greedy.move(for: p0.id, in: state)

        #expect(move == .play(cards: [.joker(index: 0)], by: p0.id))
    }

    // MARK: Revolution

    @Test("Under revolution plays the weakest beater, which has the highest natural rank")
    func playsWeakestBeaterUnderRevolution() throws {
        let trick = try Hand(cards: [.regular(.eight, .spades)])
        // Under revolution ranks < 8 (rawValue) beat 8. 4 and 5 both qualify.
        // Weakest beater under revolution = highest rawValue among beaters = 5♦.
        let p0 = makePlayer("P0", cards: [.regular(.four, .clubs), .regular(.five, .diamonds)])
        let p1 = makePlayer("P1", cards: [.regular(.king, .hearts)])
        let state = makeState(
            players: [p0, p1],
            currentPlayerIndex: 0,
            currentTrick: [trick],
            isRevolutionActive: true,
            lastPlayedByIndex: 1
        )

        let move = greedy.move(for: p0.id, in: state)

        #expect(move == .play(cards: [.regular(.five, .diamonds)], by: p0.id))
    }
}
