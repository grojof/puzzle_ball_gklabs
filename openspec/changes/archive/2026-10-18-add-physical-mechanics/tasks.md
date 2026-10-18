# Tasks

## 1. A weaker jump, an honest reach

- [x] 1.1 Lower the jump impulse to reach a standing jump of about 2.7 m, measured in `flame_test`; re-measure every envelope number (and the new double-jump height and distance, with an air jump at the apex) and the speed curve every 0.75 m up to 30 m; verify `movement_envelope_test.dart` asserts all of them, including the speed curve at each distance
- [x] 1.2 Add `speedCurve` to `MovementEnvelope` with exact interpolation and inverse interpolation for a start speed (D2), plus the double-jump numbers and `maxDoubleJumpGap`/`maxDoubleJumpClimb`; verify package tests at 100 % coverage on VM and Chrome

## 2. Precision

- [x] 2.1 Add `precision` to `LevelParameters` (D3) and size every gap, climb, set-piece part and boosted section from `reach × U(low, high)`, boosted sections also above 1.05 × the unboosted reach; make the validator check against `reach × high`; verify tests: level 1 gaps within 60–85 % of the reach, deep gaps up to 95 % and never beyond, and the property tests

## 3. New elements in the generator

- [x] 3.1 Add `hazards`, `platforms` and `FloorRun.crumbling` to `LevelData` and `BoostType.doubleJump`, with equality and canonical text; verify unit tests at 100 % coverage
- [x] 3.2 Add the `spikes`, `ferry`, `crumblingHops`, `orbGap` and `orbClimb` sections (D4) and the introductions by level (D5), bumping `generatorVersion` to 2 and the golden digests; verify geometry tests for each section, the introduction levels, and golden digests identical on VM and Chrome
- [x] 3.3 Add the validator rules (D6) with tests that reject a hand-built invalid case for each rule; verify the property tests over seeds and deep levels stay clean

- [x] 3.4 Guarantee each element in the level that introduces it, featured (play-test feedback: level 21 had no orb); verify a test over ten seeds per introduction level

## 4. Mechanics in the game

- [x] 4.1 Add `SpikeComponent` with `LevelComponent.sendBack()` shared with falls (D7); verify `flame_test` tests for both respawn and restart
- [x] 4.2 Add `MovingPlatformComponent` (kinematic, pauses, `GroundSurface`); verify tests that it shuttles between its ends and carries a resting ball to the far edge
- [x] 4.3 Add `CrumblingPlatformComponent` (shakes, collapses after 0.6 s of standing, restores); verify tests for collapse timing, no collapse before contact, and restore after respawn
- [x] 4.4 Add the double-jump orb (charge, air jump with the vertical speed reset, cleared on respawn and new level, orb restored on respawn); verify tests for the air jump, a single use, and restore
- [x] 4.5 Draw spikes, moving and crumbling platforms, and the orb in the visual style with the reserved colors (game-visuals); verify rendering tests and the contrast test extended to the new colors

## 5. Controls and bot

- [x] 5.1 Restyle the joystick and the jump button (D8) with the charged indicator; verify tests that the indicator shows while a charge is held and the existing control tests pass
- [x] 5.2 Teach the bot spikes, ferries, crumbling islands and the orb, with the tighter jump lead (D9); verify the bot test on one level per introduction plus deep levels, and a local stress run of at least 280 levels

## 6. Docs and verification

- [x] 6.1 Update `docs/product.md`, `docs/architecture.md` and `docs/glossary.md` (spikes, ferry, crumbling platform, orb, precision); verify `docs-check` and the spell check pass
- [x] 6.2 Play on the author's phone: early levels with spikes and ferries, crumbling islands, orb sections, and deep precision; tune the jump impulse and the precision bounds from the feedback; measure frame time; verify the feedback is noted for the PR
- [x] 6.3 Run the local CI checks (format, analyze, bloc lint, tests with coverage, packages on VM and Chrome, spell check), open the PR as ready, and squash merge when CI passes; verify CI passes

## Workflow follow-up

- After merge, archive the change so `level-mechanics` lands in `openspec/specs/` with the updated specs.
- Next change: logic and memory mechanics (color switches with blocks and doors, memory platforms, portals), and an
  explanatory bubble on first encounters if the play-test asks for it.
- Later: progression (modes, lives, savegames, permanent abilities).
