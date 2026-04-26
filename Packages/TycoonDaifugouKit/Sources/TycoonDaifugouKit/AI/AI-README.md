# AI Module Reference

Quick reference for anyone working in `Packages/TycoonDaifugouKit/Sources/TycoonDaifugouKit/AI/`. For the full design rationale, see `docs/AI-OPPONENT-FRAMEWORK.md`.

---

## Architecture

```
validMoves → feature extraction → dot product with personality weights → softmax sample at difficulty τ → move
```

Two orthogonal axes:

- **Personality** (`FeatureWeights`) — *what* the bot prefers. Four presets: `.greedy`, `.aggressive`, `.comboKeeper`, `.balanced`.
- **Difficulty** (`Difficulty`) — *how consistently* it picks the top-scored move. Three tiers: `.easy` (τ≈1.0), `.medium` (τ≈0.5), `.hard` (τ≈0.15).

Same personality at different difficulties = same style, different consistency. Different personalities at same difficulty = different style, same strength.

## Files

| File | Responsibility |
|------|----------------|
| `Opponent.swift` | Protocol. `func move(for:in:) -> Move` |
| `Difficulty.swift` | Enum with temperature values |
| `FeatureWeights.swift` | Weight vector struct + four personality presets |
| `MoveFeatures.swift` | `features(for:in:hand:)` — extracts the five features from a move |
| `Policy.swift` | `{ id, weights }` + `score(move:in:hand:)` — dot product |
| `PolicyOpponent.swift` | Conforms to `Opponent`. Softmax-samples scored moves |
| `OpponentRoster.swift` | Factory. Assigns random personality per CPU seat |

## Features (v1)

| Feature | Range | Typical weight sign |
|---------|-------|---------------------|
| `cardsCleared` | [0, 1] | + (shedding is good) |
| `winLikelihood` | [0, 1] | + (winning tricks is good) |
| `comboIntegrity` | [0, 1] | + (keeping groups intact is good) |
| `cardValueSpent` | [0, 1] | − (spending strong cards is costly) |
| `passBias` | additive | ± (positive = pass-happy, negative = aggressive) |

Revolution is handled inside `cardValueSpent` — the rank→strength mapping inverts when `state.isRevolutionActive`.

## Score Formula

```
score(move) = w.cardsCleared   × f.cardsCleared
            + w.winLikelihood  × f.winLikelihood
            + w.comboIntegrity × f.comboIntegrity
            + w.cardValueSpent × f.cardValueSpent
            + (move == .pass ? w.passBias : 0)
```

## Adding a New Personality

1. Define a new `FeatureWeights` static preset in `FeatureWeights.swift`.
2. Add it to the roster's random-assignment pool in `OpponentRoster.swift`.
3. Write a regression test showing it makes a recognizably different choice from existing personalities on a curated game state.
4. Run the tournament harness to verify calibration targets still hold.

## Adding a New Feature

1. Add the field to `MoveFeatures` struct and `FeatureWeights` struct.
2. Implement extraction in `features(for:in:hand:)`.
3. Update the score formula in `Policy.score`.
4. Set the new weight to `0.0` in all existing presets (backward compatible — zero weight means no effect).
5. Write unit tests for the new feature in `MoveFeaturesTests.swift`.
6. Tune weights via the tournament harness.

## Testing

- **Unit:** `MoveFeaturesTests`, `PolicyTests`, `PolicyOpponentTests` — pure functions, deterministic, fast.
- **Parity:** `GreedyParityTests` — `PolicyOpponent(.greedy, τ=0)` must match `GreedyOpponent` on a seed corpus.
- **Invariant:** softmax never returns an illegal move; seeded RNG is reproducible across runs.
- **Tournament:** `Tournament.swift` — N-game calibration harness. Run manually, not in CI.

## Calibration Targets

Bot finishing as Millionaire in 4-player rounds vs Balanced-policy proxy (~1000 seeded games):

| Difficulty | Target win rate |
|------------|-----------------|
| Easy       | ~25% (±5%)      |
| Medium     | ~40% (±5%)      |
| Hard       | ~60% (±5%)      |
