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

## 6. Difficulty (v2: Four Tiers)

Difficulty maps to a temperature τ used in softmax sampling. Expert is the
exception — it uses `LookaheadOpponent` (deterministic argmax with a
hand-quality tiebreaker on close calls) instead of the softmax sampler.

| Tier | τ | Meaning |
|------|---|---------|
| Easy   | 2.0  | Sample broadly. Statistically indistinguishable from random play. |
| Medium | 0.25 | Strong preference for the top move; occasional honest second-best. |
| Hard   | 0.10 | Strong play with occasional human-like slips on close calls. |
| Expert | 0.0  | Deterministic argmax + 1-ply hand-quality tiebreaker on close-score positions. Never picks a sub-optimal move; resolves ties toward better downstream hand quality. Feature-gated by player level (unlock at level 20). |

### Calibration

The single-round Millionaire-rate metric is luck-capped near ~45% in
4-player Tycoon (the deal's contribution to the round dominates skill).
**Mean finish position** (1 = millionaire, 4 = beggar) is the cleaner
measure of play quality across many seeded games.

Calibration vs three Easy-Greedy reference seats (1000 seeded games), as
of the v2 final tuning on `refactor/make-AI-harder`:

| Tier   | Mil% | Mean rank | Comment |
|--------|------|-----------|---------|
| Easy   | 28%  | 2.38      | Within noise of random (2.50). Baseline. |
| Medium | 57%  | 1.68      | Clearly above random; lands top half consistently. |
| Hard   | 66%  | 1.48      | Strong; targets the spec ~70% Mil (within tolerance). |
| Expert | 69%  | 1.47      | Tightest play; edges Hard via the tiebreaker. |

The original spec (25 / 50 / 70 / 80 Mil%) tracked Mil%-only and is
substantially closer to spec under the new tuning than under v2's first
linear-heuristic ceiling (24 / 38 / 44 / 43). The breakthrough was
retuning `Balanced` toward the **endgame-stash** strategy human players
use: heavy `cardValueSpent` and `jokerHoarding` penalties, reduced
`winLikelihood`, softer `passBias` so passing is genuinely on the table.

**Reference baseline.** Calibration uses Easy-Greedy refs rather than
Easy-Balanced because Easy-Balanced was too strong as a baseline (it's
the same heuristic as the subject, just noisier). Easy-Greedy
approximates a casual-human passive playstyle and aligns with the spec's
"Easy ≈ no edge over a casual player" intent.

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

## v2 — Smarter Opponents (Implemented)

Adds two new dimensions: awareness (counting) and adaptation (phase-aware play). Two new personalities and one new difficulty tier. v2 is **landed** as of the `refactor/make-AI-harder` branch with the exception of v2 UI (deferred).

### v2 Features (New Additions to MoveFeatures) — Implemented

| Feature | What it measures |
|---------|------------------|
| `effectiveRank` | Mean rank-strength of played cards normalized against the **unseen** cards (i.e. `Deck − hand − playedPile − currentTrick`). When every Ace and 2 has been played, a held King reads at ~1.0 rather than its absolute ~0.83. **Lead-gated**: returns 0 on a fresh trick (`currentTrick.isEmpty`), so a positive weight doesn't push the bot to lead its strongest cards — it only kicks in when seizing a contested trick is on the table. |
| `eightStopValue` | Positive only when 8-Stop is enabled and the move contains an 8 in a tempo-critical position (long hand to dump, contested trick). Lets a personality opportunistically lock tricks. |
| `jokerHoarding` | Fraction of the played cards that are Jokers (count of Jokers / count of cards). Lets a personality dampen Joker spend separately from regular `cardValueSpent`. |

### v2 Phase Awareness — Implemented

`PhaseModifier` multiplies a `Policy`'s base weight vector by a phase-dependent factor at score time. Phase is resolved from the active player's hand size:

- `early`: hand size > 8
- `mid`: hand size 4–8
- `endgame`: hand size ≤ 3

`PhaseModifier.identity` (all 1.0s) is the default and preserves v1 behavior for the legacy presets. `.endgameRusher` uses a custom modifier that amplifies `cardsCleared` 3.0× and dampens `passBias` to 0 in the endgame bucket.

### v2 Personalities — Implemented

- **`.counter`** — Higher `effectiveRank` weight (+1.2). On a fresh lead the feature is gated to 0, so the bot leads cheap; on a contested trick it's willing to commit a strong card when it dominates the unseen deck. Aggressive `jokerHoarding` (-1.2) to keep Jokers in the bank.
- **`.endgameRusher`** — Roughly Balanced base weights, paired with `PhaseModifier.endgameRusher` so the bot plays defensively early and dumps aggressively in the endgame bucket.

### v2 Difficulty — Implemented

**Expert** uses `LookaheadOpponent` instead of `PolicyOpponent`. The lookahead applies each candidate move, simulates other seats' turns assuming `.balanced` argmax stand-ins, and adds a positional bonus (currently a hand-size differential vs the table) to the direct score.

In current heuristic-only tuning, the lookahead bonus does not measurably improve win rate over Hard τ=0.02 (both ~43% in calibration), so `LookaheadOpponent.defaultLookaheadWeight = 0.0` ships as the default — Expert behaves as deterministic argmax of the same policy. The lookahead infrastructure is in place; v2.1 work to make it productive (better stand-in models, multi-ply search, or a stronger terminal evaluator) is tracked in v3+.

### v2 UI — Deferred

Per-CPU personality selection in pre-game setup is deferred. Random remains the default and is the only mode shipped.

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
