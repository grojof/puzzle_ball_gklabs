# Tasks

## 1. Physics and envelope

- [x] 1.1 Raise the world's gravity to 12 m/s² and compensate the jump, the jump boost and the trampoline so their heights stay (D1); verify `movement_envelope_test.dart` with the whole envelope re-measured, and the loop's boost still at 1.2 times its entry speed
- [x] 1.2 Add the rush's push to the ball and `rushGain` to `MovementEnvelope`, with the rush's speed curve (D7); verify an envelope test on the real ball and unit tests at 100 % coverage

## 2. Generator

- [x] 2.1 Split phrases into flow and challenge phrases (D2); verify tests that flow phrases use only flow kinds and every level has both
- [x] 2.2 Add the three break points and their rising probability (D3); verify tests that each appears, deepens with the level, and passes the validator
- [x] 2.3 Fill deep levels: shorter rests, longer phrases, weights by depth (D4); verify tests comparing levels 15 and 60
- [x] 2.4 Vary climbs: no plain climb after another, boosted steps in deep towers (D5); verify tests for both
- [x] 2.5 Raise the start's intensity and ease introductions less (D6); verify the difficulty curve's tests and that level 1 stays about 90 s
- [x] 2.6 Add `AdrenalineZone` data, zones from level 5 and gaps sized with the rush (D7); verify tests for the introduction, the spacing and the sizing
- [x] 2.7 Extend the validator and the laser clearance to zones (D8), bump `generatorVersion` to 5 and recompute the golden digests; verify package coverage at 100 % on the VM and the same digests in Chrome

## 3. Game

- [x] 3.1 Add `AdrenalineZoneComponent`, the ball's rush and its end on a respawn (D7); verify `flame_test` tests for entering, leaving and a respawn
- [x] 3.2 Draw the zone's tint, the edge glow and the ball's trail, and show the heart in the boost tray (D7); verify render and HUD tests
- [x] 3.3 Synthesize the heartbeat sound and add `Haptic.heartbeat` (D7); verify the audio and haptics tests and the loudness check

## 4. Bot and stress

- [x] 4.1 Teach the bot the new gravity, the rush and the break points (D9); verify the playthrough test and the local stress run of 680 levels

## 5. Docs and verification

- [x] 5.1 Write ADR-0015 and update `docs/product.md`, `docs/glossary.md` and `docs/architecture.md` (D10); verify `docs-check` and the spell check
- [x] 5.2 Play on the author's phone: levels 1, 5, 9, 13 and 60; measure frame time; verify the feedback is noted for the PR
- [x] 5.3 Run the local CI checks, open the PR as ready, and squash merge when CI passes; verify CI passes

## Workflow follow-up

- After merge, archive the change.
- Next: `add-dynamic-elements` (fans, bumpers, pendulums and seesaws at levels 15, 17, 19 and 21), then the logic and memory mechanics.
