# Proposal

## Why

In the author's play-test on an Android phone after the level generator rebuild, the camera got in the way of
playing:

- it sways for no reason over uneven ground;
- it zooms out for boosts too late to help;
- in landscape it frames the ball too low, with too much sky and too little ground ahead.

The jump button is also small and has no icon, and tilt mode reads the portrait axis even when the phone is held
in landscape. The levels now demand precise jumps, so seeing what comes next and reaching the controls comfortably
matter more than before.

## What Changes

- Replace the legacy camera helpers (`lib/game/utils/camera_utils.dart`) with a small camera controller. The old code
  still treats each floor run's position as a tile centre and switches between fixed anchors with thresholds, which
  makes the view jump. The new controller:
  - looks ahead in the direction of travel, further at higher speed;
  - follows the height of the ground under and ahead of the ball, not the ball's every bounce;
  - smooths every movement without overshoot (critically damped), with no thresholds that make the view jump;
  - zooms out ahead of time before boosts and at high speed, based on the time to reach them, not a fixed distance;
  - frames by the screen's shape: the visible world keeps a minimum width and height in portrait and landscape, with
    the ball in the lower middle and enough ground ahead to judge a jump.
- A bigger jump button with a clear up-arrow icon, sized and placed for the thumb relative to the screen, in both
  orientations; the joystick gets the same treatment so the two controls mirror each other.
- Tilt mode follows the screen orientation: in landscape, tilting the phone like a steering wheel moves the ball the
  way the screen is turned.
- After the author's play-test of the above:
  - the camera also zooms out when the ball rises far above the ground, so the ground stays in view;
  - a vibration setting (on by default, Android only) gives a distinct vibration for each event: an effective jump, a
    boost and a checkpoint.

## Capabilities

### New Capabilities

- `game-camera`: how the camera frames the ball and the course: look-ahead, ground following, smoothing, anticipated
  zoom, and framing in portrait and landscape.

### Modified Capabilities

- `player-controls`: the on-screen controls get a minimum size, an icon and thumb placement in both orientations; tilt
  follows the screen orientation; and the device vibrates on jumps, boosts and checkpoints.
- `player-settings`: a vibration setting, on by default and offered on Android only.

## Impact

- **Code:**
  - a new camera controller under `lib/game/camera/`, used by `BallOdysseyGame.update`;
  - `lib/game/utils/camera_utils.dart` is removed;
  - `JumpButtonComponent` and the joystick setup in `BallOdysseyGame._addHud`;
  - `TiltInput` and the `GameConfig` or game input it needs for the orientation.
- **Tests:**
  - unit tests for the camera math;
  - `flame_test` tests for framing in portrait and landscape and for an early boost zoom;
  - tests for the button size and icon and for tilt in landscape.
- **Performance:** the camera runs every frame. It does work linear in the nearby terrain, with no allocation per
  frame, and frame time is measured on the device.
- **Docs:** architecture (camera), product (gameplay today), glossary (look-ahead).
- No dependency changes; the level generator package is untouched.
