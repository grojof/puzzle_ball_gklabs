# Tasks

## 1. State and layout

- [x] 1.1 Expose `activeBoost` and `boostLeft` on `BallComponent`, cleared when a boost ends, is replaced or the ball respawns (D2); verify `flame_test` tests for each case
- [x] 1.2 Add the indicator sizes and the pause-button constants to `HudLayout` (D1); verify unit tests for the sizes in portrait and landscape and a widget test that the constants match `GamePage`'s pause button

## 2. HUD components

- [x] 2.1 Add the checkpoint track: flags in course order, grey or gold, hidden without checkpoints, a count beyond eight (D1, D3); verify tests that it follows activations and respawns and renders both looks
- [x] 2.2 Add the boost tray: the running boost with its emptying ring and the orb icon while charged (D2, D3); verify tests for each boost type, the ring after one second, the end of a boost and the orb's charge
- [x] 2.3 Add the pickup message for the orb and checkpoints, above the ball, rising and fading within 0.9 s, one at a time (D3, D4); verify tests that it appears on each event, at the ball, and is gone after one second

- [x] 2.4 Move the checkpoint track under the pause button with larger flags, the boost tray to a column under the sound button, and offset the HUD and both buttons by the system's safe area (play-test feedback: the camera cutout hid the top centre; D1, D6); verify tests for the positions with and without a cutout inset and the widget test for both buttons

## 3. Text and wiring

- [x] 3.1 Add `HudMessage` and the `hudLabel` callback to the game, and the strings to the English, Spanish and Catalan ARB files, wired from `GamePage` (D5); verify a widget test in each language and the l10n generation

## 4. Docs and verification

- [x] 4.1 Write ADR-0011 (HUD layout and sizing) and update `docs/architecture.md`, `docs/product.md` and the README index; verify `docs-check` and the spell check
- [x] 4.2 Play on the author's phone in portrait and landscape, and in the browser; measure frame time; verify the feedback is noted for the PR
- [x] 4.3 Run the local CI checks, open the PR as ready, and squash merge when CI passes; verify CI passes

## Workflow follow-up

- After merge, archive the change so `game-hud` lands in `openspec/specs/`.
- Next change: logic and memory mechanics. The first-encounter bubbles may reuse the pickup message.
