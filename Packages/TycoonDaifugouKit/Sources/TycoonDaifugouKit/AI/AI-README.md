# AI Module Reference

Quick reference for anyone working in `Packages/TycoonDaifugouKit/Sources/TycoonDaifugouKit/AI/`. For the full design rationale, see `docs/AI-OPPONENT-FRAMEWORK.md`.

---

## Architecture

```
validMoves → feature extraction → phase-modified weights → dot product → softmax sample at τ → move
```

For Expert: argmax of (direct + lookahead bonus) instead of softmax.

Two orthogonal axes:

- **Personality** (`FeatureWeights` + optional `PhaseModifier`) — *what* the bot prefers. Six presets: `.greedy`, `.aggressive`, `.comboKeeper`, `.balanced`, `.counter`, `.endgameRusher`.
- **Difficulty** (`Difficulty`) — *how consistently / how deeply* it picks the top-scored move. Four tiers: `.easy` (τ=1.0), `.medium` (τ=0.15), `.hard` (τ=0.02), `.expert` (argmax + 1-ply lookahead).

Same personality at different difficulties = same style, different consistency. Different personalities at same difficulty = different style, similar strength.

## Files

| File | Responsibility |
|------|----------------|
| `Opponent.swift` | Protocol. `func move(for:in:) -> Move` |
| `Difficulty.swift` | Enum with temperature values; `.expert` routes to `LookaheadOpponent` |
| `FeatureWeights.swift` | Weight vector struct + six personality presets + `.ones` / `multiplied(by:)` helpers |
| `PhaseModifier.swift` | Per-phase weight multipliers + `GamePhasePosition.from(handSize:)` |
| `MoveFeatures.swift` | `extract(for:in:hand:)` — extracts the eight features from a move |
| `Policy.swift` | `{ id, weights, phaseModifier }` + `score(move:in:hand:)` — phase-adjusted dot product |
| `PolicyOpponent.swift` | Softmax sampler over scored moves; used by Easy / Medium / Hard |
| `LookaheadOpponent.swift` | Deterministic argmax + 1-ply positional eval; used by Expert |
| `OpponentRoster.swift` | Factory. Routes Expert → `LookaheadOpponent`, others → `PolicyOpponent`. Random personality per seat. |

## Features

| Feature | Range | Typical weight sign | Notes |
|---------|-------|---------------------|-------|
| `cardsCleared`   | [0, 1] | + | Shed count / 4 (max base-rule move). |
| `winLikelihood`  | [0, 1] | + | 0 on lead; rank-strength on contested trick. |
| `comboIntegrity` | [0, 1] | + | Fraction of held same-rank groups left intact. |
| `cardValueSpent` | [0, 1] | − | Mean abs rank-strength of spent cards. Revolution-aware. |
| `passBias`       | additive | ± | Applied only on `.pass`. |
| `effectiveRank`  | [0, 1] | + (counter) / 0 | Mean rank-strength relative to **unseen** cards. **Lead-gated** — returns 0 on a fresh trick. |
| `eightStopValue` | [0, 1] | + (8-Stop on) / 0 | Bonus for 8-containing plays in tempo-critical spots. 0 when 8-Stop is disabled. |
| `jokerHoarding`  | [0, 1] | − | Joker fraction of the play. Lets policies penalize Joker spend separately. |

## Score Formula

```
score(move) = effective.cardsCleared   × f.cardsCleared
            + effective.winLikelihood  × f.winLikelihood
            + effective.comboIntegrity × f.comboIntegrity
            + effective.cardValueSpent × f.cardValueSpent
            + effective.effectiveRank  × f.effectiveRank
            + effective.eightStopValue × f.eightStopValue
            + effective.jokerHoarding  × f.jokerHoarding
            + (isPass ? effective.passBias : 0)

effective = weights.multiplied(by: phaseModifier.multipliers(for: phase))
phase     = GamePhasePosition.from(handSize: hand.count)
```

## Expert Lookahead

`LookaheadOpponent` is **argmax of the policy with a 1-ply tiebreaker** for close-score positions. Behavior:

1. Apply tactical rules (round-ending move, 3♠ reversal). If a rule fires, return that move.
2. Score every candidate by `policy.score`. If the top score is more than `tieBreakEpsilon` above all alternatives, return that move (= Hard's argmax).
3. For multiple top-tier candidates within ε of the leader, run a 1-ply forward sim using `.balanced τ=0` stand-ins, evaluate the resulting position with a hand-quality eval (trump count + combo count − hand size), and pick the candidate with the best resulting position.

Why a tiebreaker rather than an additive bonus: empirically, additive lookahead bonuses with any weight regress play under our policy — the lookahead heuristic is noisier than the direct policy score, so making it influence every move dilutes the signal. As a tiebreaker, lookahead can only fire when the policy itself has no clear preference, so it's a strict improvement over pure argmax.

Stand-in opponents in the rotation use `.balanced τ=0` because the bot doesn't know other seats' real policies in pure-engine code — a single rational baseline keeps the simulation deterministic.

The lookahead infrastructure also leaves room for v2.1 multi-ply search or a stronger terminal evaluator without changing the public API.

## Adding a New Personality

1. Define a new `FeatureWeights` static preset in `FeatureWeights.swift`.
2. (Optional) Add a custom `PhaseModifier` if the personality is phase-shifted.
3. Add a static `Policy` instance and append it to `Policy.allV2` (see `Policy.swift`).
4. Write a unit test in `PolicyTests.swift` showing it makes a recognizably different choice from existing personalities on a curated game state.
5. Run the tournament harness to confirm calibration targets still hold.

## Adding a New Feature

1. Add the field to `MoveFeatures` struct **and** `FeatureWeights` struct (give the weight a default of `0.0` so existing call sites stay valid).
2. Update `FeatureWeights.ones` and `FeatureWeights.multiplied(by:)`.
3. Implement extraction in `extract(for:in:hand:)`.
4. Update the score formula in `Policy.score`.
5. Existing personality presets stay backward-compatible because the new weight defaults to 0.
6. Write unit tests in `MoveFeaturesTests.swift`.
7. Tune weights via the tournament harness.

## Testing

- **Unit:** `MoveFeaturesTests`, `PolicyTests`, `PolicyOpponentTests`, `PhaseModifierTests`, `LookaheadOpponentTests` — pure functions, deterministic, fast.
- **Greedy reference:** `GreedyPolicyTests` — `Policy.greedy` argmax behavior on a curated corpus.
- **Invariants:** softmax / lookahead never return an illegal move; seeded RNG is reproducible across runs.
- **Tournament:** `AITournament.swift` — N-game calibration harness gated by `RUN_AI_TOURNAMENT=1`. Run manually, not in CI.

## Calibration

Mean finish position is the primary metric (1 = millionaire, 4 = beggar). Single-round Millionaire-rate is luck-capped near ~45% in 4-player Tycoon, so it under-represents skill differential at the top tiers; mean rank doesn't.

Vs three Easy-Greedy reference seats (1000 seeded games):

| Difficulty | Mil% | Mean rank |
|------------|------|-----------|
| Easy       | 28%  | 2.38      |
| Medium     | 57%  | 1.68      |
| Hard       | 66%  | 1.48      |
| Expert     | 69%  | 1.47      |

The breakthrough that lifted the curve from a ~1.92 mean-rank ceiling to ~1.47 was retuning `Balanced` for the endgame-stash strategy: large `cardValueSpent` and `jokerHoarding` penalties, reduced `winLikelihood`, softened `passBias`. See `docs/AI-OPPONENT-FRAMEWORK.md` § 6 for the rationale.
