# Proposal

## Why

The generator is the heart of the game, and today it produces levels that are neither coherent nor scaled:

- The savegame seed is ignored (every savegame plays the same levels).
- The difficulty value overflows its range, so later levels get negative parameters.
- Ramps are placed on top of tiles.
- Boosts appear by arbitrary rules, and checkpoints are decorative.

The measured movement envelope makes the mismatch concrete. The ball jumps 3.7 m high and covers 13.5 m at top speed,
yet generated gaps are a fraction of a tile. The author wants infinite levels whose complexity scales from a relaxed
start to a long, demanding climb (see `docs/product.md`). This first change rebuilds generation and makes checkpoints
work. The second change adds play modes, the original world, the daily challenge and shareable seeds on top of it.

## What Changes

- **New `level_generator` package** (pure Dart, deterministic):
  - Builds level `n ≥ 1` of any seed.
  - The same seed and level give the same level on every platform, the web included.
  - It uses its own 32-bit PRNG, because `dart:math`'s `Random` is not guaranteed stable across platforms.
- **Difficulty curve:**
  - A demanding first level with the basic obstacles; stages of five levels that each add a boost.
  - A sawtooth: a gentler "breather" level inside each stage.
  - Lengths grow from 30–45 s early to 2–3 min deep.
  - No ceiling: beyond the scripted stages, density and required precision keep rising, but never beyond what the
    ball can do.
- **Segment-based generation:**
  - Segment types: run-ups, flats, ramped climbs and descents whose ramps occupy their own span, jump steps, drops and
    gaps.
  - Boosts are placed only where they serve a section: speed before long gaps, jump before high climbs, gravity before
    floaty gaps.
  - Checkpoints go after hard sections.
  - Every level has a flat start platform and a goal on flat ground.
- **Movement envelope:**
  - Reachability limits come from the ball's measured abilities: jump height, top speed and acceleration, flight time,
    and boost effects.
  - Safety margins tighten as difficulty rises.
  - A validator checks every generated level, and property tests run it over thousands of seeds and levels.
- **Game:**
  - The game uses the package and builds wide floor runs as single bodies.
  - It derives the envelope from its physics constants.
  - A physics test proves the ball actually reaches that envelope. This guards later tuning.
  - A bot playthrough completes a sample of generated levels.
- **Checkpoints:** passing a checkpoint activates it. A fall respawns the ball at the last activated checkpoint, and
  restarts the level only when none was reached. **BREAKING** for the current "a fall restarts the level" behavior.
- **Savegame seed:** savegames now use their seed. Their fixed level count stays until the next change replaces the
  progression model.
- **Removals:** `lib/game/levels/` (old generator, `LevelData`, `predefinedLevel`).

## Capabilities

### New Capabilities

- `level-generation`: how levels are produced from a seed and a level number:
  - determinism, infinite levels, the difficulty curve and pacing;
  - the reachability guarantee against the ball's physics;
  - placement rules for terrain, boosts and checkpoints;
  - start and goal.

### Modified Capabilities

- `game-session`: a fall respawns the ball at the last activated checkpoint instead of always restarting the level,
  and checkpoints activate when the ball passes them.

## Impact

- **New package:** `packages/level_generator`, with its own path-filtered CI workflow. Tests run on the VM and in
  Chrome, to prove cross-platform determinism.
- **Game:** `lib/game/` changes:
  - level building from package data;
  - floor runs as single bodies with a tiled sprite;
  - checkpoint activation and respawn;
  - `GamePage` passes the savegame seed.
- **Tests:** generator property and golden tests; a physics envelope test; bot playthroughs of sampled levels (kept
  small, for CI minutes).
- **Docs:** ADR for the generator design and the movement envelope; updates to `docs/architecture.md`,
  `docs/product.md` and `docs/glossary.md`.
- **Out of scope:** play modes, daily challenge, seed sharing, the savegame and menu model, new mechanics, physics
  tuning.
- **Behavior visible to players:**
  - Existing savegames now play the levels of their own seed, which differ from today's.
  - Level numbers and progress stay as they are.
