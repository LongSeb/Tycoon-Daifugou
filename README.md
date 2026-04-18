# Tycoon-Daifugou

An iOS implementation of **Tycoon** (also known as *Daifugō* / *Daihinmin*, 大富豪), the Japanese shedding-type card game popularized in *Persona 5 Royal*.

Play against AI opponents on your phone instead of booting up a whole console.

## Status

🚧 Early development. Nothing shippable yet.

## What is Tycoon?

A four-player card game where the goal is to get rid of all your cards first. Ranks (Tycoon → Rich → Poor → Beggar) persist across rounds and affect card trading at the start of each new round. It's got enough quirks — revolutions, 8-stops, suit locking — to stay interesting after the hundredth game.

See [`docs/rules.md`](docs/rules.md) for the full ruleset we're implementing. *(Coming soon.)*

## Goals

- Ship a polished single-player iOS app with believable AI opponents
- Match the clean, minimal aesthetic of apps like [Offsuit: Texas Hold'em Poker](https://apps.apple.com/us/app/offsuit-texas-holdem-poker/id6446099491)
- Learn things. One of us hasn't written code in 6+ years and is knocking rust off; the other is leveling up on iOS.

**Non-goals for v1:** multiplayer, the Wonder mechanic from *Persona 5: The Phantom X*, custom card skins, online leaderboards.

## Tech stack

- **Language**: Swift 5.10+
- **UI**: SwiftUI
- **Minimum iOS**: 17+
- **Architecture**: `@Observable` view models wrapping a pure-Swift game engine package
- **Testing**: Swift Testing (`@Test` / `#expect`) for the game engine
- **AI tooling**: Claude Code for logic-heavy work, Xcode for UI and debugging

## Project structure

*Will expand as the project does.*

```
Tycoon-Daifugou/
├── App/                            # SwiftUI app target — views, navigation, assets
├── Packages/
│   └── TycoonDaifugouKit/          # Game engine — models, rules, AI. Pure Swift.
├── TycoonDaifugouTests/            # App-layer integration tests (engine tests live in the package)
├── docs/                           # Rules spec, design notes, architecture decisions
├── CLAUDE.md                       # Project context for Claude Code
├── TESTING.md                      # Testing strategy
├── CONTRIBUTING.md                 # Team SOP — read this before your first commit
└── README.md                       # You are here
```

## Getting started

### Prerequisites

- macOS with Xcode 15.3+
- A GitHub account with access to this repo
- Git configured with your name and email:
  ```bash
  git config --global user.name "Your Name"
  git config --global user.email "you@example.com"
  ```

### First-time setup

```bash
# Clone the repo
git clone git@github.com:<owner>/<repo>.git
cd <repo>

# Open in Xcode
open TycoonDaifugou.xcworkspace
```

### Running the app

1. Open the project in Xcode.
2. Select an iPhone simulator (iPhone 15 or later recommended).
3. Press ⌘R.

### Running tests

In Xcode: ⌘U. From the command line:

```bash
# Engine tests (fast, no simulator)
swift test --package-path Packages/TycoonDaifugouKit

# Full suite, including app target
xcodebuild test -scheme TycoonDaifugou -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Contributing

Read [`CONTRIBUTING.md`](CONTRIBUTING.md) first. Short version:

- Branch off `main`, open a PR, get a review, squash-and-merge
- Commit messages use [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, etc.)
- Keep PRs small and focused

## The team

- [@LongSeb](https://github.com/LongSeb) — *Lead Dev*
- [@LunariaDev18](https://github.com/lunariadev18) — *Lead Dev*

## Acknowledgments

- The original card game of *Daifugō*, which has existed in one form or another for a very long time
- Atlus and the *Persona 5 Royal* team, whose Thieves Den implementation inspired this project
- The [Megami Tensei Wiki](https://megatenwiki.com/wiki/Rules_of_Tycoon) for the most thorough English-language rules writeup we've found

## License

TBD. We'll pick one before the first external release.
