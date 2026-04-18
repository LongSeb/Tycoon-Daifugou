import Testing
@testable import TycoonDaifugouKit

// MARK: - Regression tests
//
// Regression tests replay recorded game scenarios and verify final state.
// Unlike pure unit tests, these exercise the full engine — dealing, turn
// order, move validation, scoring — end to end. They serve two purposes:
//
//   1. Catching regressions. When you fix a bug, encode the scenario that
//      triggered it here so it can never silently come back.
//   2. Integration testing the engine. If `apply(move:to:)` is correct but
//      `validMoves(for:state:)` has a bug that prevents a legal move from
//      being recognized, a unit test on either function alone won't catch
//      it. A scenario test will.
//
// PATTERN: define the scenario as data (seed for dealing, list of moves),
// then assert on the final state. Never hand-construct a `GameState` mid-
// scenario — that defeats the point.
//
// All tests below are `.disabled` until the corresponding engine work is
// complete. Enable them one at a time as you build the engine.

/// A recorded scenario: a deterministic seed, a rule set, and a sequence
/// of moves. The engine should be able to replay it and arrive at a
/// predictable final state.
///
/// This type is a fixture for tests only — it does not belong in
/// Sources/TycoonDaifugouKit.
struct Scenario {
    let name: String
    let seed: UInt64
    // Uncomment once these types exist:
    // let ruleSet: RuleSet
    // let players: [PlayerID]
    // let moves: [Move]
    // let expectedFinalRanking: [PlayerID: Title]
}

@Suite("Engine regression scenarios", .disabled("Enable once apply(move:to:) exists"))
struct RegressionTests {

    // MARK: Scenario: vanilla 4-player, no house rules

    @Test("4-player game with base rules completes successfully")
    func fourPlayerBaseGame() throws {
        // let scenario = Scenario(
        //     name: "base-4p-seed-42",
        //     seed: 42,
        //     ruleSet: .baseOnly,
        //     players: [.alice, .bob, .carol, .dave],
        //     moves: ScenarioFixtures.base4PlayerMoves,
        //     expectedFinalRanking: [
        //         .alice: .millionaire,
        //         .bob:   .rich,
        //         .carol: .poor,
        //         .dave:  .beggar
        //     ]
        // )
        // try assertScenarioReplays(scenario)
    }

    // MARK: Scenario: Revolution House Rule

    @Test("Revolution flips card strength mid-game")
    func revolutionFlipsStrength() throws {
        // When a player plays 4-of-a-kind, the next valid move must be
        // evaluated against FLIPPED strength order. Record a scenario where
        // this actually happens and verify the engine enforces it.
    }

    // MARK: Scenario: Bankruptcy rule

    @Test("Millionaire who can't keep title becomes Beggar (Bankruptcy)")
    func millionaireBankruptcy() throws {
        // Per the rules doc: "When playing with 4+ players, if the Millionaire
        // is not able to keep their title, they will instantly become the
        // Beggar and are out of play for the remainder of the round."
        //
        // Record a scenario that triggers this transition and verify.
    }

    // MARK: Past bugs

    // Template for future regression tests. When you fix a bug, add a test
    // here titled `regression_<issueNumber>_<short_description>`. The test
    // body should reproduce the exact scenario that triggered the bug.

    // @Test("Regression #12: passing when no valid moves existed was rejected")
    // func regression_12_forcedPass() throws {
    //     // Reproduce the exact hand and trick pile that triggered #12.
    // }
}

// MARK: - Test helper (once engine is ready, move to a TestHelpers.swift file)

// /// Replays a scenario through the engine and asserts the final state.
// func assertScenarioReplays(_ scenario: Scenario) throws {
//     var state = try GameState.newGame(
//         players: scenario.players,
//         ruleSet: scenario.ruleSet,
//         seed: scenario.seed
//     )
//     for move in scenario.moves {
//         state = try state.apply(move: move)
//     }
//     #expect(state.phase == .roundEnded)
//     #expect(state.finalRanking == scenario.expectedFinalRanking)
// }
