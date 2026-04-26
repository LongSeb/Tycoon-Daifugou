# AI Opponent Framework

Design reference for the opponent system. Codebase home: `Packages/TycoonDaifugouKit/Sources/TycoonDaifugouKit/AI/`.

---

## 1. Goals

1. **Variety** — opponents must play differently from each other so the game doesn't feel "solved" after a few sessions.
2. **Realism at every difficulty** — even Easy bots should look like a casual human, never like a bot that throws away Jokers.
3. **Tunable difficulty** — a single difficulty knob whose only job is to vary how often the bot picks its preferred move vs a near-optimal alternative.
4. **Interpretable** — no ML, no opaque models. Every decision can be traced to a weighted feature score.
5. **Engine-pure** — opponents read only `GameState` and call `state.validMoves(for:)`. No privileged information, no peeking at other hands.

---

## 2. Core Abstraction: Separate Personality from Skill

The biggest insight: these are orthogonal axes.

- **Personality** = what would a good version of this opponent prefer to do? Encoded as a weight vector over move features.
- **Skill** = how often does this opponent actually pick the top-scored move? Encoded as a single sampling-temperature scalar.

This means Aggressive-Easy and Aggressive-Hard play with the same recognizable style; only the consistency varies. Conversely, Greedy-Hard and Aggressive-Hard play at the same skill level but make visibly different choices.

| Personality (weight vector) | Skill (temperature) |
|-----------------------------|---------------------|
| Greedy                      | Easy (τ ≈ 1.0)      |
| Aggressive                  | Medium (τ ≈ 0.5)    |
| ComboKeeper                 | Hard (τ ≈ 0.15)     |
| Balanced                    |                     |

---

## 3. Pipeline

For every CPU turn:

1. Get all legal moves: `state.validMoves(for: playerID)`.
2. For each move, compute a feature vector describing its strategic shape.
3. Apply the personality's weight vector as a dot product → scalar score per move.
4. Softmax-sample over scores using the difficulty's temperature τ → final move.

```swift
let candidates = state.validMoves(for: playerID)
let scored = candidates.map { ($0, policy.score($0, in: state, hand: hand)) }
return softmaxSample(scored, temperature: difficulty.temperature, rng: &rng)
```

A seedable RNG is injected at construction so unit tests are deterministic.

---

## 4. Feature Set (v1: Five Features)

Each feature returns a `Double`, normalized to a known range so weights remain interpretable as importance ratios.

| Feature | Range | What it measures |
|---------|-------|------------------|
| `cardsCleared` | [0, 1] | Cards shed by the move, normalized against the largest possible move size in base rules (4 = quad). Pass = 0. |
| `winLikelihood` | [0, 1] | Estimated probability the move takes the lead. ~1 if the move is unbeatable given what's been played; ~0 on a fresh lead (no trick to win) or for a fragile beat. |
| `comboIntegrity` | [0, 1] | 1 if no held same-rank group is split by this move; lower as splits get worse. Playing the whole held pair = 1 (group is gone but not shattered). |
| `cardValueSpent` | [0, 1] | Strength of cards being spent, with revolution applied internally. Joker = 1, 3 = 0. Almost always paired with a negative weight. |
| `passBias` (additive) | constant | Flat offset added only to the `.pass` move's score. Positive = lean toward passing on close calls; negative = fight to play. |

**Score formula:**

```
score(move) =   w.cardsCleared    × f.cardsCleared
              + w.winLikelihood   × f.winLikelihood
              + w.comboIntegrity  × f.comboIntegrity
              + w.cardValueSpent  × f.cardValueSpent
              + (move == .pass ? w.passBias : 0)
```

Revolution is handled inside `cardValueSpent` (the rank → strength mapping inverts when `state.isRevolutionActive`), so weight vectors don't carry revolution branches.

---

## 5. Personalities (v1: Four)

Weight values below are starting points. The tournament harness produces final-tuned values.

```swift
.greedy = FeatureWeights(
    cardsCleared:    0.1,
    winLikelihood:   0.0,
    comboIntegrity:  0.4,
    cardValueSpent: -1.5,
    passBias:        0.5
)

.aggressive = FeatureWeights(
    cardsCleared:    1.2,
    winLikelihood:   0.8,
    comboIntegrity:  0.2,
    cardValueSpent: -0.5,
    passBias:       -0.3
)

.comboKeeper = FeatureWeights(
    cardsCleared:    0.3,
    winLikelihood:   0.1,
    comboIntegrity:  1.5,
    cardValueSpent: -0.8,
    passBias:        0.2
)

.balanced = FeatureWeights(
    cardsCleared:    0.6,
    winLikelihood:   0.5,
    comboIntegrity:  0.7,
    cardValueSpent: -0.7,
    passBias:        0.0
)
```

**Roster assignment:** when a match starts, each CPU seat is assigned a personality uniformly at random from the four. Same difficulty across the table, mixed personalities. No UI for explicit personality selection in v1.

---

## 6. Difficulty (v1: Three Tiers)

Difficulty maps to a temperature τ used in softmax sampling.

| Tier | τ | Meaning |
|------|---|---------|
| Easy | ~1.0 | Sample broadly. Top move chosen often, but realistic-looking second-bests get sampled regularly. Feels like a casual human — never plays a Joker on a 4. |
| Medium | ~0.5 | Strong preference for the top move; occasional honest second-best. |
| Hard | ~0.15 | Almost always plays the top-scored move. Near-deterministic. |

τ values are placeholders; the tournament harness tunes them to hit calibration targets.

**Calibration targets** (bot finishing as Millionaire in a 4-player round vs a Balanced-policy proxy for a skilled human, ~1000 seeded games):

- Easy: ~25% (baseline = no edge over random play)
- Medium: ~40%
- Hard: ~60%

---

## 7. File Layout

```
Packages/TycoonDaifugouKit/Sources/TycoonDaifugouKit/AI/
├── Opponent.swift             ← protocol (existing, unchanged)
├── Difficulty.swift           ← new: enum + τ table
├── FeatureWeights.swift       ← new: struct + .greedy/.aggressive/.comboKeeper/.balanced presets
├── MoveFeatures.swift         ← new: feature struct + features(for:in:hand:)
├── Policy.swift               ← new: { id, weights } + score(move:in:hand:)
├── PolicyOpponent.swift       ← new: softmax sampler conforming to Opponent
├── OpponentRoster.swift       ← updated: opponent(kind:difficulty:rng:)
└── GreedyOpponent.swift       ← retained as frozen reference impl during migration; deleted in v1.1

Tests/TycoonDaifugouKitTests/AI/
├── MoveFeaturesTests.swift    ← per-feature unit tests
├── PolicyTests.swift          ← scoring math correctness
├── PolicyOpponentTests.swift  ← determinism with seeded RNG, pass behavior, revolution flip
├── GreedyParityTests.swift    ← assert PolicyOpponent(.greedy, τ=0) reproduces GreedyOpponent on seed corpus
└── Tournament.swift           ← calibration harness (test-target only, not shipped)
```

---

## 8. Migration Plan

1. Land features + `FeatureWeights` + `Policy` + `PolicyOpponent` with tests at the unit level.
2. Add `GreedyParityTests`: existing `GreedyOpponent` is the oracle; `PolicyOpponent(.greedy, τ=0)` must produce the same move on a seeded corpus of game states. This validates the abstraction is faithful before any weight tuning.
3. Run the tournament harness; tune weights and τ values to hit calibration targets.
4. Wire `Difficulty` through `MatchConfig` (or sibling of `RuleSet`) and into `SettingsView`.
5. Delete `GreedyOpponent.swift` once the parity test has proved equivalent and a regression scenario covers the path.

---

## 9. Test Strategy

- **Tier 1 (unit)** — `MoveFeaturesTests`, `PolicyTests`, `PolicyOpponentTests`. Each feature is a pure function; tests are fast and deterministic.
- **Tier 2 (regression)** — at least one scenario per personality showing it makes a recognizably different choice from Greedy on a curated state.
- **Tier 3 (invariants)** — softmax always picks a move from `validMoves`; never produces a `.pass` when only `.play` is legal (or vice versa per engine rules); seeded RNG produces identical output across runs.
- **Tournament harness** — N-game simulator, reports millionaire rate per (personality × difficulty). Used for calibration, not assertion. Can be a `@Test(.disabled)` test that's run manually.

---

## 10. v1 Scope (Definition of Done)

- `FeatureWeights`, `MoveFeatures`, `Policy`, `PolicyOpponent`, `Difficulty` types landed
- All 5 features computed correctly for all `Move` cases under regular and revolution states
- Four personality presets defined
- Three difficulty tiers defined
- Greedy parity test passing on a seed corpus of ≥50 states
- Tournament harness exists and produces calibration data
- Weights and τ values tuned to hit (~25 / ~40 / ~60) targets within ±5%
- `OpponentRoster` randomly assigns one of four personalities per CPU seat
- Difficulty selectable in `SettingsView`
- Old `GreedyOpponent` deleted

---

## v2 — Smarter Opponents

Adds two new dimensions: awareness (counting) and adaptation (phase-aware play). Two new personalities and one new difficulty tier.

### v2 Features (New Additions to MoveFeatures)

| Feature | What it measures |
|---------|------------------|
| `effectiveRank` | `cardValueSpent` recomputed against unseen cards rather than absolute rank. Uses `state.playedPile + state.currentTrick.flatMap{$0.cards}` to compute "what's still out there?" If every other 2 has been played, the 2 in my hand is effectively a Joker — the feature reflects that. Unlocks card-counting personalities. |
| `eightStopValue` | When 8-Stop is enabled, bonus on plays that include an 8 in situations where seizing the lead is high-value. Lets a personality opportunistically lock tricks. |
| `jokerHoarding` | Separates Joker-spending from `cardValueSpent`, since Jokers are categorically different (unconditional trump). Lets us tune "willing to spend 2s but never Jokers until last 3 cards." |

### v2 Phase Awareness

A `PhaseModifier` struct multiplies the weight vector by a phase-dependent factor:

```swift
struct PhaseModifier {
    let earlyGameMultipliers: FeatureWeights  // hand size > 8
    let midGameMultipliers:   FeatureWeights  // hand size 4–8
    let endgameMultipliers:   FeatureWeights  // hand size ≤ 3
}
```

Most personalities will have endgame multipliers that bump `cardsCleared` and dampen `cardValueSpent` — the rational shift toward "just dump everything" once you can see the finish line.

### v2 Personalities

- **`.counter`** — Greedy-like base, but uses `effectiveRank` so it confidently spends 2s once nothing higher remains. Reads as "this bot is thinking."
- **`.endgameRusher`** — defensive early, frantic late. Heavy phase modifier on endgame.

### v2 Difficulty

Add **Expert** with 1-ply lookahead: the score for each move is augmented by the best score the bot could achieve on its next turn assuming opponents play their respective top-scored moves. Cheap to compute (already have a pure reducer; just simulate one step). Bumps win rate to ~75%.

### v2 UI

Optional: per-CPU personality selection in pre-game setup. Random remains the default.

---

## v3+ — Speculative

These are listed for future awareness, not committed.

- **Opponent modeling.** Track each opposing player's revealed plays, infer their personality, exploit it. Bayesian update on a small set of personality priors. Most useful in long matches where there's signal to infer from.
- **Adversarial weight tuning.** Use the tournament harness as a fitness function and run a genetic algorithm over weight vectors. Lets the system discover personalities humans wouldn't think to write down.
- **Title-aware strategy.** Different play depending on previous-round title (Tycoon defends; Beggar takes risks). The trade phase already creates structural asymmetry — a Beggar with a hand stripped of its 2s has very different optimal play.
- **Dynamic personality.** A single bot whose weight vector shifts based on score standings — plays Aggressive when behind in cumulative score, Greedy when ahead. Adds long-game texture.
- **Search depth as a continuous knob.** Right now Easy / Medium / Hard / Expert is discrete. A long-term version exposes search depth (0-ply / 1-ply / 2-ply) and τ as separate tunable axes for power users.
- **Replay analysis tool.** Engine is already deterministic and replayable; a debug view that scores every move a bot considered would be invaluable for balancing.
- **ML opponent.** Only after the above are exhausted. The interpretability cost is real and should not be paid lightly. If you reach for it, train a small policy network using the tournament harness as the data source and benchmark it head-to-head against the interpretable version. If it doesn't decisively beat them, don't ship it.
