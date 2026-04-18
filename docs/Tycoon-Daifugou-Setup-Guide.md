# Tycoon-Daifugou — Setup & Collaboration Guide

Zero to a working dev environment, a shared GitHub repository, and a smooth pair-programming workflow with your collaborator. Follow the steps in order — later steps assume earlier ones are done.

---

## 0. Prerequisites (both of you)

- **macOS** (any currently-supported version). The app is iOS-only; Xcode runs on macOS only.
- **Xcode 15.3 or later** from the Mac App Store. Wait for the full install — ~40 min and ~20 GB.
- **Git** — comes with Xcode Command Line Tools. If you don't have it: `xcode-select --install`.
- **VSCode** from code.visualstudio.com.
- **A GitHub account** for each of you.
- **An Apple ID** (free tier is enough for simulator builds — you don't need a paid Developer Program membership until TestFlight).
- **An active Claude Pro (or Max) subscription** for each developer, so Claude Code works. Pro is $20/month and bundles Claude.ai access with Claude Code.

Optional but recommended:
- **Homebrew** — makes installing Claude Code and other CLI tools one command each.
- **SF Symbols app** (free from Apple) for browsing system icons.

---

## 1. Install VSCode Extensions

Open VSCode, then the Extensions panel (⇧⌘X), and install:

- **Swift** (publisher: Swift Server Work Group). Provides SourceKit-LSP integration: syntax highlighting, autocomplete, go-to-definition, test runner, and build tasks.
- **CodeLLDB** (publisher: Vadim Chugunov). Debugger support for Swift.
- **GitLens** (publisher: GitKraken) — optional but helpful for inline blame and history.
- **Even Better TOML** (publisher: tamasfe) — nice-to-have for editing config files.

---

## 2. Install Claude Code

On macOS, the native installer is the recommended method (no Node.js or npm required):

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Or via Homebrew:

```bash
brew install --cask claude-code
```

After install, verify:

```bash
claude --version
```

First run will open your browser for OAuth — sign in with the Anthropic account that has your Pro/Max subscription:

```bash
claude
```

Type `/help` inside the Claude Code session to see available commands. `/status` shows your auth state and remaining usage.

---

## 3. Decide Who Owns the Repo

Pick one of you to be the **repo owner** (creates the repository, manages permissions). The other becomes a **collaborator**. This doesn't mean the owner does more coding — it's just a GitHub admin role.

The rest of this guide is from the repo owner's perspective unless noted.

---

## 4. Create the Xcode Project

Create the local project first so your first commit isn't empty.

1. Xcode → **Create New Project** → **iOS → App** → Next.
2. Fill in:
   - **Product Name:** `TycoonDaifugou`
   - **Team:** your personal team (free Apple ID is fine)
   - **Organization Identifier:** `com.<yourname>` (reverse-DNS — becomes bundle ID `com.yourname.TycoonDaifugou`)
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Storage:** SwiftData
   - **Include Tests:** ✓ checked
3. Save to `~/Documents/Tycoon-Daifugou`. **Uncheck "Create Git Repository"** — we'll init git manually so we control the first commit.

---

## 5. Create the Local Swift Package for the Game Engine

The engine lives in its own package, decoupled from the app target.

```bash
cd ~/Documents/Tycoon-Daifugou
mkdir -p Packages && cd Packages
mkdir TycoonDaifugouKit && cd TycoonDaifugouKit
swift package init --type library
```

Replace the generated `Package.swift` with the one provided in the scaffolding bundle (it pins SwiftLint and configures iOS 17 as the minimum platform).

Back in Xcode:
1. **File → Add Package Dependencies → Add Local** → select `Packages/TycoonDaifugouKit`.
2. **Project Settings → TycoonDaifugou target → General → Frameworks, Libraries, and Embedded Content → `+` → TycoonDaifugouKit**.

Verify from VSCode:

```bash
cd ~/Documents/Tycoon-Daifugou/Packages/TycoonDaifugouKit
swift build
```

Should compile cleanly. If Swift Testing imports fail, your Swift toolchain is too old — update Xcode.

---

## 6. Convert the Project to a Workspace

Xcode creates a `.xcodeproj` by default. Convert to a `.xcworkspace` so local packages and the app project coexist cleanly.

1. **File → New → Workspace** → save as `TycoonDaifugou.xcworkspace` at the project root.
2. Close the existing `.xcodeproj`.
3. Open `TycoonDaifugou.xcworkspace`. Drag the `TycoonDaifugou.xcodeproj` into the workspace sidebar.
4. Drag the `Packages/TycoonDaifugouKit` folder into the workspace sidebar too.

From now on: **always open `TycoonDaifugou.xcworkspace`, never the `.xcodeproj` directly.**

---

## 7. Set Up SwiftLint and swift-format

SwiftLint is already declared as a dependency in the `Package.swift` provided. It runs as an SPM build-tool plugin — no Homebrew install needed. First build of `TycoonDaifugouKit` will resolve it automatically.

Add SwiftLint to the main app target via **File → Add Package Dependencies → paste the GitHub URL → Add Package**.

Create `.swiftlint.yml` at the project root:

```yaml
disabled_rules:
  - trailing_comma
  - identifier_name
opt_in_rules:
  - empty_count
  - closure_end_indentation
  - explicit_init
  - redundant_nil_coalescing
  - unused_declaration
excluded:
  - .build
  - .swiftpm
  - Packages/*/.build
line_length: 140
file_length: 500
```

swift-format is bundled with Swift 5.10+ — just run `swift-format --version` to verify. No install step.

---

## 8. Initialize the Git Repository

From the project root:

```bash
cd ~/Documents/Tycoon-Daifugou
git init
git branch -M main
```

Drop in the four provided docs at the root:
- `CLAUDE.md`
- `TESTING.md`
- `.gitignore`
- `docs/Tycoon-Daifugou-Setup-Guide.md` (this file)

Then:

```bash
git add .
git commit -m "chore: initial project scaffold"
```

---

## 9. Create the GitHub Repository

1. github.com → **New repository**.
2. **Repository name:** `tycoon-daifugou` (lowercase).
3. **Description:** "iOS card game app for Tycoon (Daifugō)."
4. **Private** — keep it private until you're ready to share.
5. **Do NOT initialize with a README, .gitignore, or license.** We already have these.
6. **Create repository**.

Push the existing repo:

```bash
git remote add origin git@github.com:<your-username>/tycoon-daifugou.git
git push -u origin main
```

If SSH isn't set up, use HTTPS and GitHub will walk you through a personal access token. (Generating an SSH key takes 2 minutes and is worth it: [github.com/settings/keys](https://github.com/settings/keys).)

---

## 10. Add Your Friend as a Collaborator

1. GitHub repo → **Settings → Collaborators → Add people**.
2. Enter their GitHub username. They'll receive an email invite.
3. Give them **Write** access (the default).

Once they accept:

```bash
git clone git@github.com:<your-username>/tycoon-daifugou.git
cd tycoon
claude      # launches Claude Code — reads CLAUDE.md automatically
# and in another terminal/Xcode:
open TycoonDaifugou.xcworkspace
```

Xcode will resolve package dependencies automatically on first open. They should set their own personal team under **Project Settings → Signing & Capabilities** — each developer uses their own Apple ID for local simulator signing. This setting isn't committed (Xcode stores it in per-user files, excluded by our `.gitignore`).

---

## 11. Set Up Branch Protection on `main`

Prevents either of you from pushing broken code directly to main.

1. GitHub repo → **Settings → Branches → Add branch protection rule**.
2. **Branch name pattern:** `main`.
3. Enable:
   - ✓ **Require a pull request before merging**
     - Require approvals: **1**
   - ✓ **Require status checks to pass before merging** (we'll configure this after Step 12 once CI exists)
   - ✓ **Require conversation resolution before merging**
   - ✓ **Do not allow bypassing the above settings** (apply to admins too — this is the whole point)
4. Save.

With two people, you'll approve each other's PRs. You can't approve your own — which is the point. If you're blocked on a truly trivial change and can't wait, have a "trusted" agreement documented somewhere (e.g., typo-only fixes). Don't abuse it.

---

## 12. Set Up GitHub Actions CI

Create `.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Cache SPM
        uses: actions/cache@v4
        with:
          path: |
            ~/Library/Developer/Xcode/DerivedData/**/SourcePackages
            .build
            Packages/TycoonDaifugouKit/.build
          key: ${{ runner.os }}-spm-${{ hashFiles('**/Package.resolved') }}
          restore-keys: ${{ runner.os }}-spm-

      - name: Run TycoonDaifugouKit engine tests
        run: swift test --package-path Packages/TycoonDaifugouKit

      - name: Build app
        run: |
          xcodebuild \
            -workspace TycoonDaifugou.xcworkspace \
            -scheme TycoonDaifugou \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
            -configuration Debug \
            build-for-testing | xcpretty || exit ${PIPESTATUS[0]}

      - name: Run app tests
        run: |
          xcodebuild \
            -workspace TycoonDaifugou.xcworkspace \
            -scheme TycoonDaifugou \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=latest' \
            test-without-building | xcpretty || exit ${PIPESTATUS[0]}
```

Commit on a branch, open a PR, watch it run. Once it's green, go back to **Settings → Branches → main → Edit** and add the `test` job as a required status check. Now no PR can merge without CI passing.

---

## 13. PR Template

Create `.github/pull_request_template.md`:

```markdown
## What
<!-- One or two sentences describing the change. -->

## Why
<!-- The problem this solves or the feature this delivers. Link to issue if applicable. -->

## How
<!-- Brief notes on the approach, especially if non-obvious. -->

## Testing
- [ ] `swift test --package-path Packages/TycoonDaifugouKit` passes
- [ ] Manually tested in simulator
- [ ] New regression test added (if this PR fixes a bug)
- [ ] No new SwiftLint warnings

## Screenshots (UI changes only)
<!-- Drag and drop simulator screenshots. -->
```

---

## 14. Daily Dev Workflow

### The dual-editor setup

Keep two windows open, always:

- **VSCode**: main editor. Engine code, tests, markdown. Claude Code runs in the integrated terminal (⌃`).
- **Xcode**: SwiftUI previews canvas, app builds, simulator runs. Open alongside for any UI work.

Files sync between them automatically via the filesystem. No configuration needed.

### Start of day

```bash
git checkout main
git pull
```

### Starting a feature

```bash
git checkout -b feat/scoring-logic
# Open Claude Code in the project root — it'll pick up CLAUDE.md automatically:
claude
# ... work, commit often ...
git push -u origin feat/scoring-logic
```

Open a PR on GitHub. Request review from your collaborator. They review, approve, you squash-merge. Delete the branch.

### The engine-first feedback loop

Keep this running in a side VSCode terminal while you work on `TycoonDaifugouKit`:

```bash
# Re-run engine tests on every save (optional, requires `fswatch`)
brew install fswatch
fswatch -o Packages/TycoonDaifugouKit/Sources Packages/TycoonDaifugouKit/Tests | \
  xargs -n1 -I{} swift test --package-path Packages/TycoonDaifugouKit
```

Or simpler: just hit ⌃R in the Swift extension's test view in VSCode.

### Merge strategy

**Prefer squash merges.** One PR = one commit on `main`. Keeps history linear and readable. Only use merge commits when preserving individual commits genuinely matters (rare).

### Commit message conventions

```
feat(engine): implement revolution rule
fix(game-view): card tap not registering after pass
refactor(ai): extract opponent strategy into protocol
test(engine): add property tests for valid moves
docs: update CLAUDE.md with design system notes
chore: bump SwiftLint to 0.55.0
```

### When you and your friend work on overlapping code

Talk first. Merge conflicts in Swift are especially nasty because auto-merge can produce code that compiles but is subtly wrong (Xcode project files in particular). Coordinate via whatever you already use (Discord, iMessage, Slack). Ideally: one of you lands their change, the other rebases on top.

### If Xcode project files conflict (`TycoonDaifugou.xcodeproj/project.pbxproj`)

This is the most common painful conflict. When it happens:
1. Don't auto-resolve.
2. The person with the newer branch takes the *other* person's version of `project.pbxproj`.
3. Re-add your new files through Xcode (right-click folder → Add Files to TycoonDaifugou…).
4. Commit the re-merged project file.

Minimize this by **not frequently adding files to both branches in parallel**. If you know your friend is adding files, hold your add-file work until they merge.

---

## 15. Working with Claude — The Design-to-Code Loop

### Architecture, planning, and UI prototyping (claude.ai)

Open claude.ai in a browser. Great for:
- High-level feature planning
- Debugging obscure errors where you want to think it through
- **Prototyping UI as React artifacts before porting to SwiftUI** — claude.ai renders React inline, so you iterate on the layout in a browser in seconds before committing it to Swift.

### Writing Swift (Claude Code in VSCode)

In the VSCode integrated terminal at the project root:

```bash
claude
```

Claude Code reads `CLAUDE.md` on launch, so it has full project context — architecture decisions, conventions, testing strategy — without you re-pasting. Once inside Claude Code you can:
- Ask it to implement a file, a function, or an entire module
- Paste screenshots of React prototypes and ask it to port to SwiftUI
- Have it run `swift test` and iterate until tests pass

Claude Pro shares usage between claude.ai and Claude Code on the same account — so a long claude.ai design session and a long Claude Code build session draw from the same bucket. Keep an eye on `/status` inside Claude Code to see remaining capacity.

### The full design-to-code loop

1. **In claude.ai**: describe the screen you want. Reference the Offsuit aesthetic notes in `CLAUDE.md`. Ask for a React artifact prototype.
2. **Iterate** on the artifact until layout and hierarchy feel right.
3. **Screenshot** the final artifact.
4. **In VSCode**, launch Claude Code with `claude`. Paste the screenshot and say: *"Port this to SwiftUI, using the existing `DesignSystem` components. Add new components to `App/DesignSystem/Components/` if needed."*
5. **In Xcode**, watch the SwiftUI Preview update as Claude Code writes the view.

This loop is dramatically faster than iterating directly in SwiftUI. Layout experiments happen in seconds in a browser, not 20+ seconds per rebuild in Xcode.

---

## 16. Build Order Recommendation

Don't build the UI first. Build the engine first.

1. **Engine models** (`TycoonDaifugouKit/Models/`): `Card`, `Rank`, `Suit`, `Hand`, `Player`, `GameState`, `Move`, `RuleSet`. Write tests as you go — `CardTests.swift` is provided as an example.
2. **Core engine** (`TycoonDaifugouKit/Engine/`): `apply(move:to:)`, `validMoves(for:state:)`, dealing, basic turn logic. No House Rules yet.
3. **Scoring + titles** (`TycoonDaifugouKit/Engine/`): rank awarding at end of round, scoring table for different player counts.
4. **Trading phase** (`TycoonDaifugouKit/Engine/`): Millionaire↔Beggar and Rich↔Poor exchanges.
5. **House Rules one at a time** (`TycoonDaifugouKit/Rules/`): Revolution, 8-Stop, Joker, 3-Spade Reversal, Bankruptcy. Each behind a `RuleSet` flag, each with dedicated unit tests + a regression scenario.
6. **Basic AI** (`TycoonDaifugouKit/AI/`): `GreedyOpponent` — plays lowest valid card, passes when it can't. Good enough to play a full game.
7. **Now UI.** Home screen → New game screen → Game screen → Result screen → Settings.
8. **Polish:** animations, sounds, haptics, icon, launch screen, marketing copy.

Getting the engine solid with a comprehensive test suite *before* any SwiftUI means you can confidently swap AI strategies, tweak rules, and build UI knowing the foundation is correct. Engine bugs discovered after the UI is built are 10x harder to chase.

---

## 17. Next Steps

1. Commit all the provided docs (`CLAUDE.md`, `TESTING.md`, `.gitignore`, this guide in `docs/`) on a `chore/initial-docs` branch and merge via PR. That's your first end-to-end test of the workflow.
2. Drop `Packages/TycoonDaifugouKit/Package.swift` and `Packages/TycoonDaifugouKit/Sources/TycoonDaifugouKit/Models/Card.swift` into place. Verify with `swift build`.
3. Drop the provided test files into `Packages/TycoonDaifugouKit/Tests/TycoonDaifugouKitTests/`. Run `swift test` — the `CardTests` should all pass, and `RegressionTests` / `EngineInvariantTests` should be skipped (they're `.disabled` until the engine exists).
4. Open GitHub issues for the first engine milestones: "Implement Hand and HandType", "Implement `apply(move:to:)` for base rules", "Implement dealing", etc.
5. Start on the engine. Test-first.

Ship it.
