# Testing Strategy

This project follows a deliberate, three-tier test strategy. Each tier has a different cost, runs at a different frequency, and catches a different class of bug. Keeping them separate prevents the common failure mode where "unit tests" balloon into slow integration tests and the whole suite becomes too painful to run.

---

## Tier 1 — Engine unit tests (`TycoonDaifugouKitTests`)

**Where:** `Packages/TycoonDaifugouKit/Tests/TycoonDaifugouKitTests/`
**Run with:** `swift test --package-path Packages/TycoonDaifugouKit`
**Framework:** Swift Testing (`import Testing`, `@Test`, `#expect`)
**Runtime budget:** entire suite under 3 seconds

These test individual types and functions in isolation. No simulator, no SwiftUI, no SwiftData.

**What belongs here:**
- Model invariants: `Card`, `Rank`, `Suit`, `Hand`, `Move`, `GameState`
- Pure functions: `apply(move:to:)`, `validMoves(for:state:)`, dealing logic, scoring table
- Each House Rule as its own file: `RevolutionTests.swift`, `EightStopTests.swift`, `JokerTests.swift`, `ThreeSpadeReversalTests.swift`, `BankruptcyTests.swift`
- AI strategy: `GreedyOpponentTests.swift` checks the opponent's chosen move against expected behavior for a given state

**Pattern:** one `@Suite` per file, descriptive test names, one assertion concept per test. Use parameterized tests (`@Test("...", arguments:)`) aggressively instead of for-loops.

**Example:** see `CardTests.swift` — 10 passing tests across ~120 lines, covers the entire `Card`/`Rank`/`Suit`/`Deck` surface.

---

## Tier 2 — Regression scenarios (`TycoonDaifugouKitTests`, same package)

**Where:** `Packages/TycoonDaifugouKit/Tests/TycoonDaifugouKitTests/RegressionTests.swift`
**Run with:** same as Tier 1
**Runtime budget:** under 10 seconds for the full regression suite

Scenarios that replay a recorded game and verify final state. Unit tests catch isolated bugs; regression tests catch integration bugs between engine pieces.

**Two use cases:**

1. **Canonical scenarios.** A handful of "golden" games that exercise the full engine end-to-end (4-player base game, Revolution mid-game, Bankruptcy trigger, Joker followed by 3-Spade Reversal). These live in the repo forever and serve as executable documentation of how the engine behaves.

2. **Post-mortem regression tests.** Every time you fix a non-trivial bug, add a test here named `regression_<issueNumber>_<short_description>` that reproduces the exact scenario that triggered it. The test suite accumulates these over time and becomes an institutional memory of every bug you've ever shipped.

**Pattern:** scenarios are declared as data (seed + rule set + list of moves), not constructed imperatively in the test body. This makes them readable, diffable, and easy to extend. See the `Scenario` fixture and `assertScenarioReplays` helper in `RegressionTests.swift`.

---

## Tier 3 — Invariant tests (`TycoonDaifugouKitTests`, same package)

**Where:** `Packages/TycoonDaifugouKit/Tests/TycoonDaifugouKitTests/EngineInvariantTests.swift`
**Run with:** same as Tier 1
**Runtime budget:** under 15 seconds

Property-style tests that verify invariants across many randomly-seeded game traces. These catch the bugs unit tests miss: card duplication, turn-order drift, state corruption.

**Invariants worth testing:**
- **Card conservation:** total card count is constant across all moves.
- **Card uniqueness:** no `Card` value ever appears in two places at once.
- **Turn order:** `currentPlayerIndex` advances exactly one seat per non-pass move.
- **Phase monotonicity:** `GamePhase` never moves backwards within a round.
- **Scoring conservation:** total XP awarded per round matches the scoring table.
- **Move legality:** every move returned by `validMoves(for:state:)` is accepted by `apply(move:to:)`.

**Pattern:** parameterize the test over a static array of seeds (say, 20 distinct seeds). Each seed runs a simulated playthrough and asserts the invariant. If an invariant ever fails on any seed, you've found a bug.

See `EngineInvariantTests.swift` for templates.

---

## Tier 4 — App-layer integration tests (`TycoonDaifugouTests`)

**Where:** `TycoonDaifugouTests/` in the Xcode project (not in the package)
**Run with:** `xcodebuild test -workspace TycoonDaifugou.xcworkspace -scheme TycoonDaifugou -destination 'platform=iOS Simulator,name=iPhone 15 Pro'`
**Framework:** Swift Testing
**Runtime budget:** under 30 seconds

These test the glue between the engine and the app: `GameController`, SwiftData persistence, settings round-trips.

**What belongs here:**
- `GameController` correctly reflects engine state after `apply(move:)`
- SwiftData `@Model` types round-trip (save → fetch produces an equal object)
- Settings changes persist across app launches
- `RuleSet` configured in settings propagates to new games

**What does NOT belong here:**
- Anything that could be tested in `TycoonDaifugouKitTests` without the app layer
- UI assertions — those go in Tier 5

---

## Tier 5 — UI tests (`TycoonDaifugouUITests`, optional for MVP)

**Where:** `TycoonDaifugouUITests/` in the Xcode project
**Run with:** `xcodebuild test -workspace TycoonDaifugou.xcworkspace -scheme TycoonDaifugou -destination 'platform=iOS Simulator,name=iPhone 15 Pro'`
**Framework:** XCUITest
**Runtime budget:** under 5 minutes

End-to-end tests that drive the actual UI in a simulator. These are slow, brittle, and expensive — but valuable for critical paths right before a release.

**Only write UI tests for:**
- The happy-path critical flow: launch app → start game → play cards → see result screen
- Flows that have caused production bugs in the past (add a UI regression test when fixing)

**Do NOT write UI tests for:**
- Every screen
- Visual appearance (snapshot tests are a different tool)
- Logic that can be tested at a lower tier

---

## Running Tests

**Daily development loop (fast feedback):**
```bash
swift test --package-path Packages/TycoonDaifugouKit
```
Runs Tiers 1–3 in under 15 seconds. Use this constantly — after every meaningful edit to the engine.

**Before opening a PR:**
```bash
# Engine tests
swift test --package-path Packages/TycoonDaifugouKit

# App-layer tests (requires simulator)
xcodebuild test \
  -workspace TycoonDaifugou.xcworkspace \
  -scheme TycoonDaifugou \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest'
```

**CI (GitHub Actions) runs all of the above on every PR.**

---

## Conventions

- **One `@Suite` per file.** File name matches suite name: `CardTests.swift` contains `@Suite("Rank ordering")`, `@Suite("Card identity and properties")`, etc.
- **Descriptive test names.** `@Test("3 is the weakest rank")` beats `@Test("testRankOrdering")`. The name should spell out the invariant in plain English.
- **Arrange-Act-Assert.** Each test has three obvious sections, in that order. If a test is longer than 15 lines, consider splitting it.
- **Prefer `#expect` over `#require`.** `#require` halts the test on failure; use it only for preconditions where continuing makes no sense (e.g., "the state must have at least one player").
- **No shared mutable state between tests.** Swift Testing runs tests in parallel by default. Any shared state is a bug waiting to happen.
- **Parameterized over repeated.** If you'd write the same test 5 times with different inputs, use `@Test("...", arguments: ...)` instead. One test, multiple data points, single failure report.

---

## What Not To Do

- **Don't mock the engine in app-layer tests.** The engine is pure and cheap to run — just instantiate the real one. Mocks are for external systems (network, filesystem when we add them), not for code you control.
- **Don't test framework code.** SwiftData, SwiftUI, Foundation — those are Apple's responsibility. Test *your* code's use of them, not the frameworks themselves.
- **Don't write a test that always passes.** If a `#expect` can never fail given any input, the test isn't testing anything. Delete it.
- **Don't disable flaky tests.** A flaky test is a real bug in either the test or the code. Fix it or delete it — don't `.disabled(...)` it and move on.
