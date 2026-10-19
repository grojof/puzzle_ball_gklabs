# Tasks

## 1. Measurements and data

- [x] 1.1 Add the ball's surface effects (D4) and trampoline launch (D3) behind `GroundSurface`, then measure with the real physics the speed a pushing ball leaves the biggest hill and half-pipe at, the trampoline's height and distance, each surface's speeds, the mud jump, and the loop's entry speed; verify `movement_envelope_test.dart` asserts each new envelope number
- [x] 1.2 Add `CurvedRun`, `Trampoline`, `FloorRun.surface` and `Loop` to `LevelData`, and the new numbers to `MovementEnvelope`; verify unit tests at 100 % coverage

## 2. Generator

- [x] 2.1 Add hills and half-pipes with exact polynomial points and the speed model over them (D1, D2); verify geometry tests (smooth joins, no steeper than a ramp) and determinism
- [x] 2.2 Add trampoline hops (D3); verify tests that each pad is an island before a pit within reach
- [x] 2.3 Add surfaced sections and the speed model per surface (D4); verify tests that gaps and climbs after each surface fit its speed and jump
- [x] 2.4 Add the loop section with its boost and landing (D5); verify tests for the boosted speed margin and a free path
- [x] 2.5 Introduce the elements by level (D6), bump `generatorVersion` to 4 and recompute the golden digests; verify the introduction tests, package coverage at 100 % on the VM and the same digests in Chrome
- [x] 2.6 Add the validator rules and extend `LaserClearance` (D7); verify tests rejecting a hand-built invalid case for each rule

## 3. Game

- [x] 3.1 Add `CurvedTerrainComponent` with chains, `GroundSurface` and biome drawing (D1); verify `flame_test` tests that the ball rolls over a hill and through a half-pipe without catching
- [x] 3.2 Add `TrampolineComponent` (D3); verify tests that two different falls bounce to the same height
- [x] 3.3 Draw and apply the surfaces on floor runs (D4); verify tests that a belt carries a resting ball, ice slows acceleration, and mud lowers speed and jump
- [x] 3.4 Add `LoopComponent` with its collision switching (D5); verify tests for going around, rolling back when slow, leaving on the exit run, and a reset on respawn
- [x] 3.5 Extend fall detection to curves and trampolines, and frame the loop with the camera (D7, D8); verify tests for each

## 4. Bot and stress

- [x] 4.1 Teach the bot the new elements and add levels 9, 11 and 13 to the playthrough (D9); verify the playthrough test and a local stress run on two seed sets

## 5. Docs and verification

- [x] 5.1 Update `docs/product.md`, `docs/glossary.md` and `docs/architecture.md`; verify `docs-check` and the spell check
- [x] 5.2 Play on the author's phone: curves from level 1, trampolines at 9, surfaces at 11, the loop at 13; measure frame time; verify the feedback is noted for the PR
- [ ] 5.3 Run the local CI checks, open the PR as ready, and squash merge when CI passes; verify CI passes

## Workflow follow-up

- After merge, archive the change.
- Next: the logic and memory mechanics at levels 10, 12, 14 and beyond.
