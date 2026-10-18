# Tasks

## 1. Baseline

- [x] 1.1 Measure frame time on the author's phone with the current camera (profile build, a deep level, the frame probe used for earlier changes) and record it for comparison; verify the numbers are noted for the PR

## 2. Camera controller

- [x] 2.1 Add `lib/game/camera/camera_controller.dart` with the critically damped smoothing (D2) and the framing by screen shape (D3); verify unit tests for the resting zoom on 800 × 360 and 360 × 800 screens (16 m × 9 m and 12 m minimums), the ground at about 65 % of the screen height, and identical results at 30 and 120 steps per second
- [x] 2.2 Add the look-ahead (D4) and ground following with the ball-in-view guard (D5), with sorted terrain and binary search; verify unit tests: more course ahead at top speed, a monotonic camera height over a staircase, a camera close to ground height during a jump in place, and the ball kept within 15–85 % of the height during a jump boost and a fall
- [x] 2.3 Add the anticipated zoom for boosts and speed (D6) and `reset`; verify unit tests: zoomed out before reaching a boost at top speed, back to normal after passing it, about 0.69 at 23 m/s, and a reset that snaps without sweeping

## 3. Game integration

- [x] 3.1 Use the controller in `BallOdysseyGame` (no `camera.follow`, centre anchor, reset on level load and respawn) and delete `lib/game/utils/camera_utils.dart`; verify `flame_test` tests in portrait and landscape game sizes that the ball is in the lower half and the visible world meets the minimums, that a respawn frames the ball on the next frame, and that the existing game tests, envelope test and bot test still pass
- [ ] 3.2 Keep the parallax backdrop working with the new zoom and position; verify the rendering test and a check on the phone

## 4. Controls

- [x] 4.1 Rebuild `JumpButtonComponent` with the size, margin, up-arrow icon and pressed state of D7, and size the joystick to match; verify widget or `flame_test` tests for both sizes on a landscape and a portrait screen, the arrow being drawn, and a press requesting a jump
- [x] 4.2 Make `TiltInput` relative to the screen orientation (D8); verify unit tests with synthetic accelerometer events for portrait and both landscape sides, including a nearly flat phone keeping the last side

## 6. Play-test additions

- [x] 6.1 Zoom out while the ball is far above the ground (D10); verify unit tests that the ground and the ball stay on screen during a jump boost, the zoom is floored at 0.5, and it returns to rest after landing
- [x] 6.2 Add the `vibration` setting to `PlayerSettings` and `SettingsRepository` (default on, invalid values fall back), with a switch on the settings screen (Android only, three languages); verify package tests at 100 % coverage and a widget test of the switch
- [x] 6.3 Add `HapticsSink` and report `jump`, `boost` and `checkpoint` from the game (D9); verify `flame_test` tests that an effective jump, a boost and a checkpoint each report their event and that a mid-air press reports nothing
- [x] 6.4 Add `DeviceHaptics` with the per-event feedback and the setting check, used by `GamePage` (a no-op sink on the web); verify unit tests of the platform haptic calls per event and with vibration off

## 5. Docs and verification

- [x] 5.1 Update `docs/architecture.md` (camera section), `docs/product.md` (gameplay today, known gaps) and `docs/glossary.md` (look-ahead); verify `docs-check` and the Markdown spell check pass
- [x] 5.4 Update the docs for the play-test additions (ground-in-view zoom, vibration setting and feedback); verify `docs-check` and the spell check pass
- [ ] 5.2 Play on the author's phone in portrait and landscape, with joystick and tilt, record frame time against task 1.1, and tune the camera constants from the author's feedback; verify no runtime errors in the logs and the feedback noted for the PR
- [ ] 5.3 Run the local CI checks (format, analyze, bloc lint, tests in random order with coverage at or above the threshold, spell check), open the PR as a draft and mark it ready once green locally; verify CI passes

## Workflow follow-up

- After merge, archive the change with `/opsx:archive` so `game-camera` and the updated `player-controls` land in
  `openspec/specs/`.
- The next change: play modes, the original world, the daily challenge, shareable seeds, and the savegame and menu
  model.
