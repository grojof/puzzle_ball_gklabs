# Tasks

## 1. Curve and pacing

- [x] 1.1 Change the intensity curve, the breather and introduction factors, the target duration and the checkpoint spacing (D1, D2); verify difficulty-curve tests for level 1 (intensity 0.76, precision 0.82–0.89, 90 s, 35 s spacing), level 4 as a breather, and deep levels approaching 0.95 and 4 minutes
- [x] 1.2 Introduce every element by level 8 (D3); verify tests that each level 2–8 uses and features its newcomer for ten seeds and that nothing appears before its level

## 2. Vertical variety

- [x] 2.1 Widen the vertical band to −40/+25 m around the start (D4); verify a test that long levels span over 15 m of height and stay within 65 m
- [x] 2.2 Add the tower set piece (D5); verify geometry tests: four to six steps, at least 8 m climbed, each step and gap within the envelope at the precision high
- [x] 2.3 Add the descent set piece (D6); verify geometry tests: three to five parts, 8–16 m descended, each part within the envelope
- [x] 2.4 Bump `generatorVersion` to 3 and recompute the golden digests (D8); verify the package tests at 100 % coverage on the VM and the same digests in Chrome

## 3. Game

- [x] 3.1 Detect falls by reachable ground (D7); verify `flame_test` tests that a long drop onto distant lower ground is not cut short, that a hopeless fall from high up is detected within about a second, and that rolling down a riser is not taken for a fall
- [x] 3.2 Add laser barriers to `LevelData`, their placement over descents and after towers with the route clearance, and validator rules (D9); verify geometry tests that every barrier clears the route's jumps, boosted ones included, and validator tests rejecting a low barrier
- [x] 3.3 Add the laser barrier component: rhythm, warning flicker, send-back while on, pass-through while off, drawn with the hazard red (D9); verify `flame_test` tests for each state and that a respawn keeps the rhythm

## 4. Bot and stress

- [x] 4.1 Teach the bot towers and descents if needed, and set the playthrough levels to 1–8, 45, 120 and 300 (D8); verify the playthrough test and a local stress run of 600 levels on two seed sets

## 5. Docs and verification

- [x] 5.1 Write ADR-0013 (pacing) and update `docs/product.md`, `docs/glossary.md` and the README index; verify `docs-check` and the spell check
- [ ] 5.2 Play on the author's phone: levels 1–10 and some deep levels, with towers and descents; measure frame time; verify the feedback is noted for the PR
- [ ] 5.3 Run the local CI checks, open the PR as ready, and squash merge when CI passes; verify CI passes

## Workflow follow-up

- After merge, archive the change.
- Next: new physics (curved terrain, loop-the-loop, trampolines, conveyor belts and ice or mud), then the logic and
  memory mechanics from level 10.
