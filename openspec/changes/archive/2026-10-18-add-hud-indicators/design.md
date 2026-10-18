# Design

## Context

See proposal.md for the motivation. Current state:

- **Overlays:**
  - the pause button is a Flutter `FloatingActionButton.small` at 24 px from the top left of `GamePage`;
  - the sound toggle sits at 12 px from the top right;
  - the joystick and the jump button are Flame components in the camera viewport, at the bottom corners, sized by
    `HudLayout` from the screen's shorter side.
- **Level banner:** the level label and world name fade in at the centre of the viewport (`_showFadingText`), large
  and white.
- **Ball:** `BallComponent` runs one boost at a time on a `Timer` of `boostDuration` (2 s), but does not expose which
  boost runs. `hasAirJump` tells whether the orb's charge is held.
- **Level:** `LevelComponent` creates one `CheckPointComponent` per checkpoint, in course order, with `isActivated`.
  Orbs are `BoostComponent`s of type `doubleJump` that call `ball.chargeAirJump()`.
- **Text:** the game never reads Blocs or `BuildContext`. Translated text arrives as callbacks (`levelLabel`,
  `worldLabel`) from `GamePage`.

## Goals / Non-Goals

**Goals:**
- Three HUD pieces in the viewport (checkpoint track, boost tray, pickup message), driven by game state the game
  already owns.
- Minimal sizes for fixed indicators, larger temporary ones, and no cost to frame time.

**Non-Goals:**
- Showing the HUD on the title or levels screens.
- Animating the checkpoint flags beyond the color change.
- First-encounter explanations.

## Decisions

### D1. Layout and sizes (ADR-0011)

Positions, each offset by the system's safe area (D6):

- **Checkpoint track:** a row under the pause button, aligned with its left edge.
- **Boost tray:** a short column under the sound button, aligned with its right edge.
- **Pickup message:** above the ball, in screen space.

`HudLayout` holds the positions and box sizes of the pause and sound buttons as constants that mirror `GamePage` and
`SoundToggleFab`, with a widget test that keeps them aligned.

Sizes, from the screen's shorter side `s`:

| Piece | Size | Range |
|---|---|---|
| Checkpoint flag (fixed) | `0.06 s` | 20–28 px |
| Boost or orb icon (temporary) | `0.08 s` | 28–40 px |
| Message text | `0.05 s` | 16–24 px |

On a 360 px portrait phone, this gives 22 px flags, 29 px boost icons and an 18 px message.

- *Alternative: a row at the top centre (the first version).* Rejected after the play-test: the phone's camera
  cutout hid the boost icons there. The top right under the sound button stays clear and is where the player looks.
  A short column of one or two icons takes little of the course ahead.
- *Alternative: flags beside the pause button.* Rejected after the play-test: under it they read better and can be
  larger.
- *Alternative: the boost timer as a ring around the ball.* Rejected: it would add drawing in the world, and it
  hides under fast motion.

### D2. State the HUD reads

- `BallComponent` exposes `BoostType? activeBoost` (set in `_startBoost`, cleared when the boost ends or the ball
  respawns) and `double boostLeft`, the remaining seconds.
- `LevelComponent` exposes the checkpoints in course order, and `hasAirJump`, which already exists.
- The HUD components read these from `game.level` each frame and keep nothing of their own, so a restart or the next
  level needs no wiring.
- *Alternative: events through a stream.* Rejected: polling a few fields per frame is cheaper and cannot miss an
  event across a level reload.

### D3. Drawing

- **Flags:** a pole and a small pennant, drawn with the element outline and rim. There are two looks (pending grey
  and reached gold), each recorded once as a `Picture` per size.
- **Boost and orb icons:** a small orb and its icon (`ElementPainter.orb` and `ElementPainter.boostIcon`), recorded
  per type and size. The ring is a single `drawArc` per frame over a translucent track.
- **Message:** a rounded pill in the element's color, darkened, with its icon and white text. The pill is laid out
  once with a `TextPainter`, recorded, and drawn with an opacity and a vertical offset over 0.9 s: it rises by about
  20 px, holds, then fades. It stays over the ball as the camera moves, so it never drifts away from it.
- The banner stays large, white and centred; the message is a small colored pill above the ball, so the two never
  look alike.

### D4. Which events show a message

Messages appear for the orb ("Double jump!") and checkpoints ("Checkpoint").

- Boosts already show their larger timed icon, and at deep levels they come several a minute, so a message for each
  would be noise. A boost message can be added later if the play-test asks for it.
- A message pops at the ball's screen position at the moment of the event. If a new message comes while one shows,
  it replaces it.

### D5. Translated text

`BallOdysseyGame` takes `String Function(HudMessage message) hudLabel`, where `HudMessage` is an enum
(`doubleJump`, `checkpoint`). `GamePage` maps it through `hudText` (`lib/game/view/hud_text.dart`, like
`worldTitle`) to new ARB strings in English, Spanish and Catalan
([ADR-0004](../../../docs/decisions/0004-languages.md)).

The pause button's box, with its tap target padding, is 48 px, so `HudLayout.pauseSize` is 48.

### D6. Safe area

The game fills the screen, under the status bar and the camera cutout. `GamePage` passes the system's view padding
(`MediaQuery.viewPaddingOf`) to the game, as a `ValueNotifier<EdgeInsets>`. The HUD pieces add it to their positions
and re-lay themselves out when it changes. The pause and sound buttons add the same padding to their offsets. The
joystick and the jump button keep their places, as the play-test found no problem with them.

## Risks / Trade-offs

- **[The pause button moves in `GamePage` and the flags no longer line up]** → The constants in `HudLayout` are
  checked by a widget test that reads the pause button's rect.
- **[Many checkpoints at deep levels make a long row]** → Spacing is a flag and a quarter. Deep levels have about four
  checkpoints, so the row stays short. Beyond eight, the row shows a count, such as "3/9", instead of flags.
- **[Frame time]** → Every static part is a recorded `Picture`; only the ring and the message's opacity change per
  frame. The frame time is measured on the reference phone.
- **[Notches and rounded corners]** → The pieces follow the system's safe area (D6), and the play-test checks portrait
  and landscape on the reference phone.

## Migration Plan

No data change. **Rollback:** revert the pull request.
