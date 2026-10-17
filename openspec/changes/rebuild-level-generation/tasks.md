# Tasks

## 1. Package and deterministic randomness

- [x] 1.1 Create `packages/level_generator` (pure Dart, very_good_analysis, barrel file, README) and its path-filtered workflow with `platform: vm,chrome`; verify `dart analyze` is clean and the workflow YAML parses
- [x] 1.2 Implement the 32-bit mulberry32 PRNG (16-bit split multiplication), FNV-1a string hashing and per-level stream derivation, plus `generatorVersion`; verify golden tests of fixed outputs pass with `dart test -p vm,chrome`

## 2. Data model and movement envelope

- [x] 2.1 Add `Vec2`, `LevelData` (floor runs, ramps, boosts, checkpoints, ball start, goal) and value equality; verify unit tests at 100 % coverage
- [x] 2.2 Implement `MovementEnvelope` with `speedAfterRunUp`, `flightTime`, `maxGap` and `maxClimb` (plain and boosted); verify tests against the measured numbers (3.72 m height, 7.94 m/s, 13.55 m running jump within the model's tolerance)

## 3. Difficulty curve

- [x] 3.1 Implement `DifficultyCurve.parametersFor(level)`: stages of ten, element introduction order, breathers, margin schedule capped at 0.85, duration targets and checkpoint spacing; verify tests for the early levels, breathers lower than their neighbors, monotonic growth from level 100 to 300, and no element before its stage

## 4. Generator

- [x] 4.1 Implement the segment grammar on a cursor (flat runs, ramps with their own span, steps, drops, gaps) and the start platform and goal run; verify tests for each segment's geometry and that ramps join floors at both ends
- [x] 4.2 Implement the placement passes for boost setups and checkpoints and the duration-driven length; verify tests that every boost precedes the section it serves and that estimated durations meet the targets (30–45 s at level 3, 2–3 min at level 150)
- [x] 4.3 Add a digest golden test of selected (seed, level) pairs on VM and Chrome; verify the same digests on both platforms

## 5. Validator and property tests

- [x] 5.1 Implement `LevelValidator` (overlaps, ramp joins, elements above ground, gaps and climbs within envelope and margin, start and goal rules); verify it rejects hand-built invalid levels for every rule
- [x] 5.2 Add property tests over many seeds for levels 1–200 and spot levels up to 10 000 that validate cleanly, plus the package at 100 % coverage; verify the suite runs in well under a minute

## 6. Game integration

- [x] 6.1 Build levels from package `LevelData`, with one static body per floor run and a tiled sprite; delete `lib/game/levels`; verify existing game tests pass after migrating `test/helpers/game_helpers.dart`
- [x] 6.2 Derive the `MovementEnvelope` from the game's physics constants and pass the savegame seed to the generator in `GamePage`; verify a widget test that two savegames with different seeds load different levels

## 7. Checkpoints

- [x] 7.1 Make checkpoints report activation (visual feedback) and respawn the ball at rest above the last active checkpoint on a fall, cancelling boosts; restart the level only with no active checkpoint; verify `flame_test` tests for both game-session scenarios and the boost case

## 8. Physics guarantees

- [x] 8.1 Add `test/game/movement_envelope_test.dart` that simulates the real ball and asserts it reaches every envelope number; verify it fails when the jump impulse is lowered in a local experiment
- [x] 8.2 Add the bot playthrough test (push right, jump before edges and steps, use boosts) on one level per scripted stage plus two deep levels; verify it completes all of them and runs in seconds

## 9. Docs

- [x] 9.1 Write ADR-0009 (generator design and movement envelope) and update `docs/architecture.md`, `docs/product.md` (gameplay today, known gaps), `docs/glossary.md` (stage, breather, envelope, segment, run) and the README ADR list; verify `docs-check` and the spell check pass

## 10. Integration verification

- [ ] 10.1 Play early, mid and deep levels on the Android emulator and in Chrome with the author, and record feedback for curve tuning in the PR; verify no runtime errors in the logs
- [ ] 10.2 Run the local CI checks for the app and every package (format, analyze, bloc lint, tests in random order, coverage, licenses, spell check), open the PR as a draft and mark it ready once green locally; verify the CI passes on the first full run

## Workflow follow-up

- After merge, archive the change with `/opsx:archive` so `level-generation` and the updated `game-session` land in `openspec/specs/`.
- The next change (play modes, original world, daily challenge, shareable seeds, savegame and menu model) builds on `generatorVersion` and the seeded generator.
