# Design

## Context

See proposal.md (Why). Current state that shapes the approach:

- `lib/game/levels/` holds the generator, `LevelData` (Forge2D `Vector2` positions; floors and ramps by top-left
  corner, boosts, checkpoints and goal by centre) and `predefinedLevel(level, total)`.
- `LevelComponent` builds one `FloorComponent` per 1.5 m tile.
- The ball's abilities, measured with real Box2D in `flame_test` using the current constants:

| Ability | Measured |
|---|---|
| Standing jump height | 3.72 m |
| Top speed | 7.94 m/s, 90 % reached after about 2.2 s of pushing |
| Running jump at top speed | 13.55 m horizontally, flight time about 1.7 s |

  The horizontal force also applies in the air, so the player keeps speed while flying.
- Boosts:
  - jump: 120 N·s upwards;
  - speed: 100 N·s to the right;
  - gravity: gravity scale 0.1 for 2 s.
- The world is y-down, in meters; the fall line is the lowest terrain plus 10 m.
- Seeds: savegames store a string seed (today the creation time); the old generator ignored it.

Specs: `level-generation` (new) and `game-session` (checkpoints) in this change.

## Goals / Non-Goals

**Goals:**

- Levels that read as designed: purposeful sections, readable rhythm, a scaling challenge.
- A guarantee, checked by tests at three levels (envelope, validator, bot), that every level is completable.
- Bit-identical output for a seed and level on the VM and on the web.

**Non-Goals:**

- Play modes, the original world, the daily challenge, seed sharing, the savegame model (next change).
- New mechanics or physics tuning. The envelope makes tuning safe later, but none is done here.
- Visual variety (themes, decorations).

## Decisions

### D1. A pure Dart `level_generator` package with its own data types

`packages/level_generator` has no Flutter or Forge2D dependency. It defines:

- `Vec2`, an immutable pair of doubles;
- `LevelData` (floors as runs, ramps, boosts, checkpoints, ball start, goal);
- `MovementEnvelope`;
- `DifficultyCurve` / `LevelParameters`;
- `LevelGenerator.generate(seed, level)`;
- `LevelValidator`.

The game maps `LevelData` to components. Keeping Forge2D out makes the generator testable at speed. Thousands of levels
per test run are possible because the generator is pure computation.

- *Alternative: keep generation in `lib/game/`.* Rejected by ADR-0005, and it would tie tests to Flutter.

### D2. Cross-platform determinism: own 32-bit PRNG and seed hashing

`dart:math`'s `Random(seed)` does not guarantee the same sequence across platforms or SDK versions, and on the web,
integers are JavaScript doubles, exact only up to 2^53.

- The package uses **mulberry32**, with 32-bit operations only. Multiplication is split into 16-bit halves, so it is
  exact on both the VM and the web.
- Seeds are strings, hashed with 32-bit FNV-1a. Level `n`'s stream is seeded with `hash(seed) ⊕ mix(n)`.
- The generator uses exact arithmetic only (no transcendental functions; tan 35° is a constant). The difficulty
  curve's outputs that use `exp` are quantized to 1e-6, so a last-bit difference between platforms cannot change a
  level.
- A **golden test** fixes the first values of the PRNG and a digest of selected generated levels. It runs on the VM
  and in Chrome (`dart test -p vm,chrome`; the package workflow's `platform: vm,chrome`).
- A `generatorVersion` constant is bumped whenever output changes on purpose. The next change uses it to keep shared
  seeds meaningful.

### D3. The movement envelope, derived from physics and proved by a test

`MovementEnvelope` holds the ball's abilities as plain numbers:

- jump height `H` and level flight time `T₀`;
- top speed `V` and the time to reach it;
- jump-boost height `H_b`;
- the jump distances with a speed boost and with a gravity boost.

Derived helpers:

- `speedAfter(d, startSpeed)`: uniform-acceleration approximation, capped at `V`.
- `airTime(rise)`: fitted ballistic arc with effective gravity `8H/T₀²` and launch speed `4H/T₀`, solved for the
  landing height.
- `maxGap(speed, rise, margin)` = `margin · speed · airTime(rise)`, and 0 for a rise above `maxClimb`.
- `maxClimb(margin)` = `margin · H`, and `maxBoostedClimb(margin)` = `margin · H_b`.
- `maxSpeedBoostGap(margin)` and `maxGravityBoostGap(speed, margin)`, the latter scaled by the approach speed.

The game builds the envelope from its own constants. `test/game/movement_envelope_test.dart` simulates the real ball,
as in the measurement above, and asserts the physics meets or exceeds every envelope number. That check is the
`level-generation` "matches the ball's physics" requirement.

- *Alternative: a hand-tuned "max gap = 4 tiles" table.* Rejected: it would silently break when the physics is tuned.

### D4. Segment grammar on a cursor

Generation walks a cursor (x, ground height) from left to right and appends **segments**. Each segment emits terrain
and knows its exit run-up length:

| Segment | Emits | Constraint |
|---|---|---|
| `Flat(n)` | one floor run of `n` tiles | — |
| `RampUp(h)` / `RampDown(h)` | a ramp box spanning `w ≥ h / tan 35°` between two floor runs | slope at most 35° |
| `StepUp(h)` | a ledge to jump onto | `h ≤ maxClimb` |
| `Drop(h)` | a ledge to fall from | a landing run follows |
| `Gap(g, Δh)` | empty span, landing higher or lower | `g ≤ maxGap(previous run-up, Δh)` |
| `BoostSetup(type)` | a run-up with the boost, then the section it serves | see D6 |

Every obstacle is followed by a landing run of three tiles while the margin is below 0.6, two after that. Ramps get
their own span by construction, which fixes today's bug where ramps sat on top of tiles. Floors are emitted
as **runs**, one wide box each. The game builds one static body per run and tiles the sprite, so long levels stay at a
few dozen bodies instead of hundreds.

- *Kept from the `level_generator_v2` branch:* the path → events → placement pipeline, as segments followed by
  placement passes, and a difficulty parameter.

### D5. Difficulty curve: stages, sawtooth, unbounded growth

`DifficultyCurve.parametersFor(level)` returns `LevelParameters`:

- target duration;
- segment weights (which segment types are allowed and how often);
- size ranges as fractions of the envelope limits;
- the safety margin;
- checkpoint spacing.

How the curve is built:

- **Stage and position:** `stage = (level - 1) ~/ 10`, and `position = (level - 1) % 10`.
- **Intensity:** `1 - e^(-(level - 1)/40)`, times a sawtooth factor. Positions 3 and 7 are breathers (×0.65), and
  position 0 eases in the stage's new element (×0.85). Intensity approaches 1 and never stops rising.
- **Margins:** the safety margin is `0.45 + 0.4 · intensity`, from 0.45 (forgiving) towards a cap of 0.85, so even
  very deep levels keep a 15 % slack. The share of obstacle sections is `0.35 + 0.45 · intensity`.
- **Duration:** `35 + 115 (1 - e^(-(level - 1)/60)) + 25 (1 - e^(-(level - 1)/600))` seconds: about 35 s at level 1,
  about 150 s around level 150, then slowly towards 175 s. Duration is estimated as length over a reference speed
  (5 m/s) plus 0.8 s per obstacle. The generator adds sections until the estimate reaches the target.
- **Element introduction** follows the `level-generation` spec's stage list. A section type's weight is zero until its
  stage and doubled in the stage that introduces it.

### D6. Placement passes: boosts with purpose, checkpoints after hard sections, start and goal

- **Start:** a `Flat(3)` start platform, with the ball spawned above the middle of its first tile.
- **Goal:** a final `Flat(≥ 3)`, with the goal on its last tile.
- **Boosts:** only emitted by `BoostSetup`, whose section is generated to need or use the boost:
  - **Speed:** before a gap wider than the run-up allows unboosted, but within the boosted envelope.
  - **Jump:** before a climb above `maxClimb`, within the boosted `maxClimb`.
  - **Gravity:** before a long low gap that relies on the floaty arc.
- **Checkpoints:** from stage 1 on, at the start of a floor run at least two tiles long, once the estimated time since
  the last respawn point passes the stage's spacing (three quarters of it after an obstacle). The spacing is 40 s,
  shrinking to 35 s by stage 10.

### D7. Three layers of verification

1. **Validator** (`LevelValidator`, in the package). An independent pass over `LevelData` checks:
   - geometry: no overlaps; ramps join floors; boosts, checkpoints and goal sit above ground;
   - every gap and climb against the envelope and margin;
   - start and goal rules.

   Property tests run the generator plus validator over thousands of (seed, level) pairs: levels 1–200 for many
   seeds, and spot levels up to 10 000.
2. **Envelope test** (game): real physics reaches the envelope (D3).
3. **Bot playthrough** (game): a scripted player pushes right and jumps when the ball nears the end of a run before a
   gap or a step up, never before ramps or drops; boosts act on their own. In the air it steers like a player: it
   predicts its landing with Box2D's integration and brakes to land on the next run (after a jump, the run beyond the
   gap; after a launch off a ramp top or a drop, the nearest run ahead). It must finish with no fall and no checkpoint
   respawn. It runs on one level per scripted stage plus two deep levels, headless with fixed steps, in a few seconds.
   During development it also passed 252 further (seed, level) pairs, levels 1 to 1000.

   Without steering in the air, a player who keeps pushing right overshoots short landings. That is the player's
   skill, not a generator fault: the horizontal force acts in the air and brakes the ball within a fraction of a
   second.

### D8. Checkpoints in the game

`CheckPointComponent` reports activation to its `LevelComponent`, and its flag turns from green to gold. On a fall:

- if the level has an active checkpoint, the ball is teleported to rest above it, with velocity zeroed, the boost timer
  cancelled and gravity scale reset;
- otherwise the level restarts as today.

No level rebuild is needed for a respawn.

### D9. Seed plumbing for this change

`GamePage` passes the savegame's seed and level number to `LevelGenerator.generate`. Savegames keep `totalLevels` for
now. The next change replaces the progression model, and it will introduce the original world's fixed seed.

## Risks / Trade-offs

- **[The envelope model is too optimistic in some arcs]** → Margins at most 0.85, the bot playthrough on every stage,
  and the envelope test against real physics. Any failure points to the exact level and seed.
- **[mulberry32 quality]** → Enough for level layout. Its known weaknesses matter for statistics, not for games.
- **[Wide floor bodies change how contacts feel]** → One box per run removes the seams between tiles, where the ball
  could catch. The ground-contact counting already handles any number of bodies.
- **[Bot tests are flaky]** → Fixed time step and deterministic levels make every run identical. The bot asserts
  completion within twice the estimated duration, not exact timing.
- **[Existing savegames play different levels]** → Accepted. Progress (level number) is kept, and the next change
  rebuilds progression anyway.

## Migration Plan

- Old `lib/game/levels` code is removed. Savegames are untouched: same keys, and the seed field is now used.
- **Rollback:** revert the pull request. Stored data is unchanged.

## Open Questions

- The exact numbers of the curve (duration growth, margin schedule, breather factor) are tuned by playing.
  `DifficultyCurve` keeps them as named constants, so tuning does not change the approach.
