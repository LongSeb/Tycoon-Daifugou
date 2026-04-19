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
        .disabled("Not yet implemented"),
        arguments: testSeeds
    )
    func turnOrderAdvances(seed: UInt64) throws {
        // INVARIANT: after any valid non-pass move, `currentPlayerIndex`
        // advances by exactly 1 (mod number of active players). Passes may
        // also advance, but skipping multiple seats without a pass is a bug.
    }

    // MARK: State machine legality

    @Test(
        "GamePhase transitions never go backwards",
        .disabled("Not yet implemented"),
        arguments: testSeeds
    )
    func phaseMonotonicity(seed: UInt64) throws {
        // INVARIANT: within a round, the phase only ever moves in one of
        // these sequences:
        //   .dealing -> .trading -> .playing -> .scoring -> .roundEnded
        //
        // If the engine ever moves BACK to an earlier phase mid-round,
        // something is very wrong.
    }

    // MARK: Scoring

    @Test(
        "Total XP awarded per round equals the sum in the scoring table",
        .disabled("Not yet implemented"),
        arguments: testSeeds
    )
    func scoringConservation(seed: UInt64) throws {
        // INVARIANT: the sum of XP awarded across all players at round end
        // must match the entry in the scoring table for the active player
        // count. If it doesn't, either titles are being assigned wrong or
        // XP is being double-counted.
    }

    // MARK: Move legality

    @Test(
        "No move returned by validMoves(for:state:) is ever rejected by apply",
        .disabled("Not yet implemented"),
        arguments: testSeeds
    )
    func validMovesAreApplicable(seed: UInt64) throws {
        // INVARIANT: for every (state, player), every move returned by
        // `validMoves(for:state:)` must be accepted by `apply(move:to:)`
        // without throwing. If this fails, the two functions disagree about
        // what's legal — a recipe for UI-vs-engine bugs.
    }
}
