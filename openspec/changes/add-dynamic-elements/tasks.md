# Tasks

## 1. Physics and envelope

- [x] 1.1 Add the four game components and the ball's bump response, bullet mode and seesaw reset on respawn (D1–D4, D7); verify `flame_test` tests for floating, bouncing, a mace's knock, tipping and a respawn
- [x] 1.2 Measure `fanClearance`, `fanCatchDepth`, `fanRiseSpeed`, `seesawExitSpeed` and `seesawJumpHeight` on the real ball and add them to `MovementEnvelope` (D1, D4); verify `movement_envelope_test.dart`, and a unit test that the pendulum amplitude stays under 60°

## 2. Generator

- [x] 2.1 Add `Fan`, `Bumper`, `Pendulum` and `Seesaw` data and the five section kinds, with introductions, weights and flow/tense sets (D5); verify the difficulty curve's tests and that levels 15, 17, 19 and 21 each contain their element
- [x] 2.2 Generate fan gaps and fan climbs (D1); verify tests for hover clearance, catch depth and windless stretches
- [x] 2.3 Generate bumper roofs and bumper risers (D2); verify tests for the roof's bounds and the roll-off sizing
- [x] 2.4 Generate pendulum runs (D3); verify tests for waiting rooms, clear time and gauntlets in deep levels
- [x] 2.5 Generate seesaws (D4); verify tests for the rest pose and the gap after the far end
- [x] 2.6 Extend the validator, the laser clearance and the fall detection (D6), bump `generatorVersion` to 6 and recompute the golden digests; verify package coverage at 100 % on the VM and the same digests in Chrome

## 3. Game feedback

- [x] 3.1 Draw the four elements in the depth style, with the bumper's flash and the pendulum's arc (D7); verify render tests
- [x] 3.2 Synthesize the bumper, thud and whoosh effects and add `Haptic.hit` (D7); verify the audio and haptics tests and the loudness check

## 4. Bot and stress

- [x] 4.1 Teach the bot fans, bumper roofs, pendulums and seesaws (D8); verify the playthrough test with levels 15, 17, 19 and 21 and the local stress run of 800 levels

## 5. Docs and verification

- [x] 5.1 Write ADR-0016 and update `docs/product.md`, `docs/glossary.md` and `docs/architecture.md` (D10); verify `docs-check` and the spell check
- [ ] 5.2 Play on the author's phone: levels 15, 17, 19, 21 and a deep one; measure frame time; verify the feedback is noted for the PR
- [ ] 5.3 Run the local CI checks, open the PR as ready, and squash merge when CI passes; verify CI passes

## Workflow follow-up

- After merge, archive the change.
- Next: the logic and memory mechanics, alternating every two or three levels from level 10.
