# Tycoon-Daifugou

iOS card game app for playing Tycoon (also known as Daifugō / 大富豪), the Japanese climbing card game popularized by Persona 5 Royal's Thieves Den. Swift 5.10+ / SwiftUI / iOS 17+ with SwiftData for persistence. The game engine lives in a pure-Swift local package (`TycoonDaifugouKit`) with zero UI dependencies so it's fully testable from the command line and portable to macOS/watchOS/visionOS later.

## Commands

- `open TycoonDaifugou.xcworkspace` — open in Xcode (always the workspace, never the `.xcodeproj` directly)
- `swift test --package-path Packages/TycoonDaifugouKit` — run engine tests from the CLI, no simulator needed (~1s). **Use this during engine development, not Xcode's test runner.**
- `xcodebuild -workspace TycoonDaifugou.xcworkspace -scheme TycoonDaifugou -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' build` — build the app
- `xcodebuild test -workspace TycoonDaifugou.xcworkspace -scheme TycoonDaifugou -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest'` — run all tests including app-layer
- `swift-format format -i -r App/ Packages/TycoonDaifugouKit/Sources/` — auto-format all Swift files
- `swiftlint` — lint check (also runs automatically via SPM plugin on every build)

## Tooling

- **Primary editor: VSCode + Swift extension + Claude Code CLI.** Install order in the Setup Guide. Claude Code is bundled with Claude Pro/Max subscriptions — it reads this `CLAUDE.md` automatically when launched in the project root, so you don't need to re-paste context on every session.
- **Xcode is the secondary editor**, always open alongside VSCode for: SwiftUI Previews, running the app in the simulator, asset catalog editing, and signing/capabilities. You cannot do these in VSCode.
- **Never edit `project.pbxproj` by hand.** To add a new file to the app target, do it through Xcode (right-click folder → Add Files to TycoonDaifugou…). Creating a file in VSCode places it on disk but doesn't register it with the Xcode project — a classic "my file doesn't exist" bug.
- **Engine work is VSCode-only.** Everything inside `Packages/TycoonDaifugouKit/` can be written, built, and tested entirely in VSCode with `swift build` and `swift test` — the simulator and Xcode are not involved. Take advantage of this fast loop.

## Architecture Decisions

- **Game engine is a local Swift package (`Packages/TycoonDaifugouKit`), not in the app target.** Pure Foundation imports — zero SwiftUI, UIKit, or Combine. The engine exposes `GameState`, `Card`, `Hand`, `Player`, `Rank`, `Move`, and a pure `apply(move:to:)` reducer. This makes the game logic (1) fully testable without a simulator, (2) reusable across Apple platforms, and (3) forces a clean rules-vs-presentation boundary. If you find yourself importing SwiftUI from inside `TycoonDaifugouKit`, you've made a wrong turn.
- **Immutable state, pure reducer.** Every move produces a new `GameState` — nothing mutates in place. Same pattern as Redux/Elm/The Composable Architecture. Makes undo, replay, and debugging trivial: log every state, step through. Structs throughout.
- **Game flow is an explicit state machine.** `GamePhase` enum with cases `.dealing`, `.trading`, `.playing`, `.scoring`, `.roundEnded`. Transitions are methods on the engine, not ad-hoc boolean flags. Prevents impossible states like "trading while a trick is in progress."
- **`@Observable` macro for view models, not `ObservableObject`.** iOS 17's `@Observable` gives fine-grained automatic dependency tracking without `@Published` boilerplate. Views re-render only for the specific properties they actually read. If you're tempted to write `@Published`, stop — use `@Observable`.
- **SwiftUI only, no UIKit bridges unless absolutely necessary.** We target iOS 17+. Nothing in this app requires UIKit.
- **SwiftData for persistence.** Player profile, game history, stats, and settings live in SwiftData models in `App/Persistence/`. The engine never touches SwiftData directly — it returns plain structs and the app layer persists them. Keeps the engine pure and makes engine tests trivial.
- **House Rules are toggleable.** Revolution, 8-Stop, Jokers, 3-Spade Reversal, and Bankruptcy are all marked ★ in the rules doc and must be individually on/off-able in Settings. Store the rule config in a `RuleSet` struct passed into the engine at game creation. Don't hardcode rule checks.
- **Wonder mechanic is explicitly out of scope** for the current release. Don't implement it.
- **Design system lives in `App/DesignSystem/`, centralized.** Colors (`.tycoonBlack`, `.cardCream`, `.cardLavender`), typography (`.displayXL`, `.bodyMono`), and reusable components (`CardView`, `PillButton`, `PlayerAvatar`) all in one folder. Mimics the **Offsuit (Texas Hold'em Poker)** aesthetic: pure black backgrounds, pastel gradient accent cards, large display typography, 20pt rounded corners, generous padding. **Never hardcode a hex color in a view** — add it to `DesignSystem/Colors.swift` first.
- **Animations use SwiftUI-native `.animation` + `.matchedGeometryEffect`**, no Lottie or Rive. Card movements between hand and trick pile use `matchedGeometryEffect`. Revolutions use a full-screen `.rotation3DEffect` transition. Keep motion snappy (0.2–0.3s), never over-animate.
- **AI strategy lives in `TycoonDaifugouKit/AI/`.** Single `Opponent` protocol with multiple implementations (`GreedyOpponent`, `CountingOpponent`, etc.). AI receives the same `GameState` the UI does — no privileged information, no cheating. When adding a new AI, conform to the protocol and register it in `OpponentRoster`.
- **No third-party runtime dependencies.** Game engine: 100% Foundation. App target: Apple frameworks only (SwiftUI, SwiftData, AVFoundation). Dev tooling (SwiftLint, swift-format) is fine as SPM plugins. If you find yourself reaching for Alamofire, RxSwift, SnapKit, etc. — stop. You don't need it.
- **Local-first, offline-first.** MVP has no network calls, no analytics SDK, no crash reporter. Add them only when there's a reason. Privacy-by-default is a feature.

## Project Structure

```
Tycoon-Daifugou/
├── TycoonDaifugou.xcworkspace           # always open this, not the .xcodeproj
├── App/                         # iOS app target
│   ├── TycoonDaifugouApp.swift          # @main entry
│   ├── Views/
│   │   ├── Home/                # HomeView, StatsRow, FeaturePlayCard
│   │   ├── Game/                # GameView, HandView, TrickPileView, PlayerHUD
│   │   ├── Result/              # RoundResultView, TitleAwardSheet
│   │   └── Settings/            # SettingsView, RuleToggle
│   ├── ViewModels/
│   │   └── GameController.swift # @Observable wrapper around TycoonDaifugouKit
│   ├── DesignSystem/
│   │   ├── Colors.swift
│   │   ├── Typography.swift
│   │   └── Components/          # CardView, PillButton, PlayerAvatar, GradientCard
│   └── Persistence/
│       ├── Models/              # SwiftData @Model types
│       └── PersistenceController.swift
├── Packages/
│   └── TycoonDaifugouKit/               # Pure Swift package — game engine
│       ├── Package.swift
│       ├── Sources/TycoonDaifugouKit/
│       │   ├── Models/          # Card, Rank, Suit, Hand, Player, GameState, Move, RuleSet
│       │   ├── Engine/          # apply(move:to:), validMoves(for:state:), dealing, scoring
│       │   ├── Rules/           # Revolution, EightStop, Joker, ThreeSpadeReversal, Bankruptcy
│       │   └── AI/              # Opponent protocol + concrete strategies
│       └── Tests/TycoonDaifugouKitTests/
│           ├── CardTests.swift             # Tier 1 unit tests (example included)
│           ├── EngineReducerTests.swift    # Tier 1 unit tests
│           ├── <Rule>Tests.swift           # one file per House Rule
│           ├── RegressionTests.swift       # Tier 2 scenario tests
│           └── EngineInvariantTests.swift  # Tier 3 property-style tests
├── TycoonDaifugouTests/                 # App-layer integration tests
├── TycoonDaifugouUITests/               # XCUITest end-to-end (optional for MVP)
├── .github/
│   ├── workflows/ci.yml         # Build + test + lint on PR
│   └── pull_request_template.md
├── TESTING.md                   # test strategy and conventions
└── CLAUDE.md                    # you are here
```

## Testing

Five test tiers. Full details and examples in `TESTING.md`.

- **Tier 1 — Engine unit tests** (`TycoonDaifugouKitTests`): individual types and pure functions. Runs in <3s via `swift test`. Framework: **Swift Testing** (`import Testing`, `@Test`, `#expect`).
- **Tier 2 — Regression scenarios** (`TycoonDaifugouKitTests`): replay recorded games end-to-end. Every non-trivial bug fix gets a regression test named `regression_<issue>_<desc>`.
- **Tier 3 — Engine invariants** (`TycoonDaifugouKitTests`): parameterized tests verifying properties like card conservation and turn-order advancement across many seeds.
- **Tier 4 — App-layer integration** (`TycoonDaifugouTests`): `GameController` wiring, SwiftData round-trips, settings persistence.
- **Tier 5 — UI end-to-end** (`TycoonDaifugouUITests`, optional for MVP): critical-path XCUITest flows.

**Run constantly during development:** `swift test --package-path Packages/TycoonDaifugouKit`. This runs Tiers 1–3 in seconds and is the tightest feedback loop in the project. If you're editing the engine without this command running in a side terminal, you're doing it wrong.

## Code Conventions

- **One primary type per file**, filename matches type. `CardView.swift` contains `CardView`.
- **Default access control is `internal`.** Mark things `public` only on package boundaries (`TycoonDaifugouKit`). Mark things `private` aggressively inside files.
- **Structs over classes** unless reference semantics are required. `GameState`, `Card`, `Hand`, `Player` are all structs.
- **No force-unwraps in production code.** `!` is banned outside tests. Use `guard let`, `if let`, or nil-coalescing.
- **Typed throws** (Swift 5.10+ style): `throw GameError.invalidMove`, not `throw NSError(...)`.
- **Tests use Swift Testing**, not XCTest. New test files start with `import Testing`. One `@Suite` per file, descriptive `@Test` names that spell out the invariant in plain English.
- **Commit messages: conventional commits.** `feat:`, `fix:`, `refactor:`, `test:`, `chore:`, `docs:`. Scope optional but encouraged: `feat(engine): add revolution rule`.

## Workflows

### Adding a New Rule (e.g., 8-Stop)

1. Add the rule as a dedicated file in `TycoonDaifugouKit/Rules/`. Rules are pure functions or methods: `(GameState, Move) -> GameState?` returning `nil` if the rule doesn't apply.
2. Wire it into the main `apply(move:to:)` reducer.
3. Add toggle to `RuleSet` struct (all House Rules must be individually toggleable).
4. **Write engine tests first** in `TycoonDaifugouKitTests/<Rule>Tests.swift`. TDD this — the engine is pure, tests are deterministic and fast.
5. Add at least one regression scenario in `RegressionTests.swift` exercising the rule end-to-end.
6. Only after tests pass, wire the UI affordance (animation, sound) in `App/Views/Game/`.
7. Add the toggle to `SettingsView`.

### Adding a New Feature

1. Open a GitHub issue describing the feature, even if you're the one building it.
2. Create a feature branch from `main`: `git checkout -b feat/short-description`.
3. If the engine is involved, start in `TycoonDaifugouKit` with tests.
4. Build the UI in `App/Views/`, using existing `DesignSystem` components.
5. Wire through `GameController`.
6. Open a PR against `main`. Request review from your collaborator.

### Before Opening a PR

1. `swift test --package-path Packages/TycoonDaifugouKit` passes.
2. Run the app end-to-end in the simulator — no crashes, no visual regressions.
3. `swift-format format -i -r App/ Packages/TycoonDaifugouKit/Sources/`.
4. CI green before requesting review.

### After Fixing a Bug

Always add a regression test in `RegressionTests.swift` reproducing the scenario that triggered it, named `regression_<issueNumber>_<short_description>`. This is non-negotiable. The suite of accumulated regression tests is worth more than any individual fix.

### After a PR is Merged

1. `git checkout main && git pull`.
2. Delete the local and remote feature branches.

## Design Aesthetic Reference

Mimicking **Offsuit (Texas Hold'em Poker)** on the App Store. Key traits:

- Pure black (`#000000`) backgrounds, full-bleed
- Pastel gradient cards as feature elements (soft cream, blush, lavender, mint)
- Large display typography (48–72pt), tight tracking, often italicized serif for expressive numbers
- Memoji/emoji avatars for players (never real photos)
- 20pt corner radius on feature cards, 12pt on buttons, 999pt on pills
- Generous padding (24–32pt horizontal margins)
- Subtle shadows, never heavy
- Minimalist — if something on screen isn't doing a job, delete it
- Decorative wavy SVG lines between sections for rhythm

### Design-Before-SwiftUI Loop

When adding a new screen:

1. In claude.ai (this interface), describe the screen and reference the aesthetic notes above.
2. Ask Claude to create an HTML/React artifact mocking it up.
3. Iterate on the artifact until layout and hierarchy feel right.
4. Screenshot the final artifact.
5. Switch to VSCode. Launch Claude Code with `claude` in the project root. Paste the screenshots and describe the route you want to build. Example prompt: *"Port this to SwiftUI, using the existing `DesignSystem` components in `App/DesignSystem/`. If a new component is needed, add it to `DesignSystem/Components/` first, then use it."*
6. Open Xcode alongside to check SwiftUI Previews as Claude Code writes the views.

This loop is significantly faster than iterating directly in SwiftUI — layout experiments happen in seconds in a browser, not the 20+ seconds per rebuild in Xcode.
