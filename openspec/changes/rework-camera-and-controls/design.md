# Design

## Context

See proposal.md (Why). The current state that shapes the approach:

- **The camera follows the ball** (`camera.follow(ball, maxSpeed: 400, snap: true)` in `_loadLevel`). Every frame,
  `BallOdysseyGame.update`:
  1. calls `adjustCameraHeightForTerrain`, which picks one of three viewfinder anchors from averaged floor heights,
     with thresholds;
  2. calls `adjustCameraForBoostsSmooth`, which zooms to 0.55 within 2.5 m of a boost;
  3. moves anchor and zoom 8 % of the way to their targets each frame, which depends on the frame rate.
- **The geometry is wrong since the generator rebuild:** the helpers treat `FloorRun.position` as a centre, but it is
  the top-left corner of a run that can be 20 m long.
- **Zoom is relative to `metersToPixels` = 40**, so zoom 1 shows 20 m × 9 m on an 800 × 360 landscape phone and only
  9 m of width in portrait.
- **The ball** has a top speed of 7.94 m/s, about 23 m/s with a speed boost; a running jump covers about 13.5 m.
- **The HUD:** the joystick has a 40 px radius and the jump button is 48 px; both have fixed 20 px margins, and the
  jump button has no icon.
- **Tilt** pushes with `-event.x`, the portrait axis. `sensors_plus` reports axes relative to the device's natural
  (portrait) orientation, whatever the screen rotation.

## Goals / Non-Goals

**Goals:**

- A camera whose behavior is pure math on plain inputs, testable without Flame and independent of the frame rate.
- No per-frame allocation and no work proportional to the whole level.

**Non-Goals:**

- Screen shake, cinematic transitions, or a camera the player controls.
- Changing the parallax backdrop beyond keeping it working with the new zoom.
- Locking the screen orientation. Both orientations stay supported.

## Decisions

### D1. A `CameraController` with plain inputs and outputs

`lib/game/camera/camera_controller.dart` holds the camera's state: smoothed centre, look-ahead, ground height and
zoom.

- **Input:** `update(dt, ballPosition, ballVelocity)`; the level's floors, ramps and boosts and the viewport size are
  set when they change.
- **Output:** the world point to centre on and the zoom.

The game stops using `camera.follow`, sets the viewfinder anchor to the centre and copies the controller's outputs
into the viewfinder each frame. `reset(ballPosition)` snaps the state on a level load and on a respawn.

- *Alternative: keep `camera.follow` and tweak anchors.* Rejected: follow and anchor both own the position, which is
  how the current sway arises, and neither is testable on its own.

### D2. Critically damped smoothing, frame-rate independent

Every smoothed value moves with a critically damped spring (the "smooth damp" formulation): no overshoot, and the
same result at 30, 60 or 120 frames per second. Smoothing times:

| Value | Smoothing time |
|---|---|
| Ground height | 0.35 s |
| Look-ahead | 0.5 s |
| Zoom | 0.3 s |

No thresholds: the targets are continuous functions of the inputs, so the view cannot snap between states.

### D3. Framing by screen shape

- **Pixels per meter at rest:** `min(width / minWidth, height / minHeight)`, with:
  - `minWidth` 16 m in landscape (width ≥ height), 12 m in portrait;
  - `minHeight` 9 m.

  Zoom = pixels per meter / `metersToPixels`.
- **Vertical framing:** the camera centre sits above the reference ground height by 15 % of the visible height, which
  puts the ground at about 65 % of the screen height, in the lower half, with room above for jumps.

### D4. Look-ahead from velocity

The target horizontal offset is `clamp(vx · 0.6 s, -3 m, +5 m)`, smoothed (D2). It is asymmetric because levels run
to the right. At top speed it is about 4.8 m, so a running jump's landing is in view.

### D5. Ground following, with the ball always in view

- **Reference height:** the highest ground (smallest world y) among the surfaces under the ball and the 4 m ahead of
  it in the direction of travel, sampled at a few points on floors and ramps.
- **Over a gap:** with nothing under the ball, the last known height is kept.
- **Lookups:** floors and ramps are sorted by x when the level is set, and found by binary search.
- **Guard:** after smoothing, the centre is clamped so that the ball stays between 15 % and 85 % of the visible
  height. The ball moves continuously, so the clamp does too. This covers big jumps, jump boosts and falls without
  following every bounce.

### D6. Anticipated zoom

The zoom factor is the smaller of two factors, applied to the resting zoom (D3):

- **Boost lead:** for the nearest boost ahead within reach, `t = (boost.x - x) / max(vx, 2 m/s)`. When
  `t < 1.2 s`, the factor is 0.75. With a 0.3 s smoothing time, the zoom is about 95 % done 0.9 s after it starts, so
  it is done before the ball arrives. The factor stays for 1.5 s after passing the boost, then eases back.
- **Speed:** `1 / (1 + 0.03 · max(0, |v| - 8 m/s))`, floored at 0.6. A speed boost at 23 m/s gives about 0.69.

### D7. Thumb-sized HUD

- **Sizes:** both controls are `clamp(0.22 · shortSide, 72, 120)` logical pixels across, recomputed in
  `onGameResize`, with a margin of `max(16, 0.04 · shortSide)`.
- **Jump button:** a filled circle with a white up-arrow path, and a lighter fill while pressed.
- **Joystick:** the knob radius is 0.4 of the background radius. The joystick keeps the bottom-left corner.
- **Clean-up:** the unused `enabled` API on the jump button is removed.

### D8. Tilt relative to the screen

`TiltInput` gets whether the game is in landscape from the game size (width > height), refreshed on resize.

- **Portrait:** the push stays `-x`.
- **Landscape:** the push is `y · s`, where `s` is the side the phone is turned to, taken from the sign of the
  low-pass-filtered `x` (gravity lies along the device's x axis in landscape). `s` updates only when `|x|` is clearly
  above zero (3 m/s²), so a phone held nearly flat keeps the last side.

The sign convention is fixed by unit tests with synthetic events and checked on the phone in the play-test.

- *Alternative: a plugin for the native display rotation.* Rejected for now: a new dependency for one sign that
  gravity already gives.

## Risks / Trade-offs

- **[Smoothing feels slow or floaty]** → The numbers are named constants. They are tuned in the play-test on the
  author's phone.
- **[Zooming out in portrait makes the ball tiny]** → A 12 m minimum width in portrait, and zoom-out floors (0.6).
- **[The sign of the landscape tilt is wrong on some devices]** → The tests fix the convention, and the play-test on
  a real phone confirms it. The side comes from gravity, so it adapts to how the phone is held.
- **[Per-frame cost]** → A binary search and a few samples per frame, with no allocation. Frame time is measured on
  the phone before and after the change.

## Migration Plan

No data or settings change. **Rollback:** revert the pull request.
