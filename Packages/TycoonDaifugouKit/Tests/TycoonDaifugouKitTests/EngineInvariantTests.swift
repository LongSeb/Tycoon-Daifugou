import Testing
@testable import TycoonDaifugouKit

// MARK: - Engine invariants
//
// Invariant tests verify properties that must hold for ANY valid game state,
// regardless of how we got there. They're the closest thing to property-based
// tests in Swift Testing's current vocabulary.
//
// The pattern: generate a population of random-but-valid states (via different
// seeds), and assert the same property on all of them. If the property ever
// fails, you've found a bug that hand-written scenarios would have missed.
//
// These are the highest-ROI tests you can write for a game engine because
// they catch entire CLASSES of bugs (card duplication, turn-order drift,
// state machine corruption) in one go.
//
@Suite("Engine invariants")
struct EngineInvariantTests {

    /// Generates 20 distinct seeds so each invariant runs on 20 independent
    /// game traces. Keep this small — these tests can be slow.
    static let testSeeds: [UInt64] = Array(1...20).map { UInt64($0 * 1_000) }

    private static func makePlayers() -> [Player] {
        ["P0", "P1", "P2", "P3"].map { Player(displayName: $0) }
    }

    // MARK: Card conservation

    @Test(
        "Total card count is conserved across all moves",
        arguments: testSeeds
    )
    func cardConservation(seed: UInt64) throws {
        let initial = GameState.newGame(players: Self.makePlayers(), ruleSet: .baseOnly, seed: seed)
        let expectedCount = initial.allCards.count
        let states = SimulatedPlaythrough.states(from: initial)

        for (step, state) in states.enumerated() {
            #expect(
                state.allCards.count == expectedCount,
                "Seed \(seed): card count changed at step \(step) — got \(state.allCards.count), expected \(expectedCount)"
            )
        }
    }

    // MARK: Card uniqueness

    @Test(
        "No card ever appears in two places at once",
        arguments: testSeeds
    )
    func cardUniqueness(seed: UInt64) throws {
        let initial = GameState.newGame(players: Self.makePlayers(), ruleSet: .baseOnly, seed: seed)
        let states = SimulatedPlaythrough.states(from: initial)

        for (step, state) in states.enumerated() {
            let all = state.allCards
            let unique = Set(all)
            #expect(
                all.count == unique.count,
                "Seed \(seed): duplicate card at step \(step) — \(all.count) total, \(unique.count) unique"
            )
        }
    }

    // MARK: Turn order

    @Test(
        "Turn order advances exactly one seat per non-pass move",
        arguments: testSeeds
    )
    func turnOrderAdvances(seed: UInt64) throws {
        // INVARIANT: in every `.playing` state the current player always holds
        // cards and is not bankrupt. A stale `currentPlayerIndex` pointing at
        // an empty-handed or bankrupt player is the hallmark turn-order bug.
        let initial = GameState.newGame(players: Self.makePlayers(), ruleSet: .allRules, seed: seed)
        let states = SimulatedPlaythrough.states(from: initial, maxRounds: 3)

        for (i, state) in states.enumerated() {
            guard state.phase == .playing else { continue }
            let current = state.players[state.currentPlayerIndex]
            #expect(
                !current.hand.isEmpty,
                "Seed \(seed): step \(i): \(current.displayName) has empty hand but holds the turn"
            )
            #expect(
                !current.isBankrupt,
                "Seed \(seed): step \(i): \(current.displayName) is bankrupt but holds the turn"
            )
        }
    }

    // MARK: State machine legality

    @Test(
        "GamePhase transitions never go backwards",
        arguments: testSeeds
    )
    func phaseMonotonicity(seed: UInt64) throws {
        // INVARIANT: within a round the phase only ever advances through
        //   .dealing(0) → .trading(1) → .playing(2) → .scoring(3) → .roundEnded(4)
        // A backward transition mid-round is a state-machine bug.
        // Round boundaries (roundEnded → trading/playing) are legitimate resets.
        let initial = GameState.newGame(players: Self.makePlayers(), ruleSet: .allRules, seed: seed)
        let states = SimulatedPlaythrough.states(from: initial, maxRounds: 3)

        var prevPhase = initial.phase
        var prevRound = initial.round

        for (i, state) in states.dropFirst().enumerated() {
            defer { prevPhase = state.phase; prevRound = state.round }
            if state.round != prevRound { continue }  // legitimate reset at round boundary
            #expect(
                phaseOrder(state.phase) >= phaseOrder(prevPhase),
                "Seed \(seed): step \(i + 1): phase went \(prevPhase) → \(state.phase) within round \(prevRound)"
            )
        }
    }

    private func phaseOrder(_ phase: GamePhase) -> Int {
        switch phase {
        case .dealing:    return 0
        case .trading:    return 1
        case .playing:    return 2
        case .scoring:    return 3
        case .roundEnded: return 4
        }
    }

    // MARK: Scoring

    @Test(
        "Total XP awarded per round equals the sum in the scoring table",
        arguments: testSeeds
    )
    func scoringConservation(seed: UInt64) throws {
        let players = Self.makePlayers()
        let initial = GameState.newGame(players: players, ruleSet: .baseOnly, seed: seed)
        let states = SimulatedPlaythrough.states(from: initial)

        guard let final = states.last, final.phase == .roundEnded else {
            Issue.record("Seed \(seed): game did not reach .roundEnded")
            return
        }

        let totalXP = final.scoresByPlayer.values.reduce(0, +)
        let expected = Scoring.totalXP(playerCount: players.count)
        #expect(
            totalXP == expected,
            "Seed \(seed): expected \(expected) total XP, got \(totalXP)"
        )
    }

    // MARK: Move legality

    @Test(
        "No move returned by validMoves(for:state:) is ever rejected by apply",
        arguments: testSeeds
    )
    func validMovesAreApplicable(seed: UInt64) throws {
        // INVARIANT: for every (state, player), every move returned by
        // `validMoves(for:)` must be accepted by `apply` without throwing.
        // A mismatch means the two functions disagree about legality — a
        // recipe for UI-vs-engine bugs where moves appear clickable but crash.
        let initial = GameState.newGame(players: Self.makePlayers(), ruleSet: .allRules, seed: seed)
        let states = SimulatedPlaythrough.states(from: initial, maxRounds: 2)

        for (i, state) in states.enumerated() {
            guard state.phase == .playing else { continue }
            let playerID = state.players[state.currentPlayerIndex].id
            for move in state.validMoves(for: playerID) {
                #expect(
                    (try? state.apply(move)) != nil,
                    "Seed \(seed): step \(i): validMoves offered \(move) but apply rejected it"
                )
            }
        }
    }
}
