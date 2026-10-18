# Proposal

## Why

The play-test of `add-physical-mechanics` showed that the game gives little feedback on what the player holds or has
reached:

- a running boost is only felt, not seen;
- a checkpoint is only visible where it stands;
- collecting an orb is noticed only on the jump button.

The author asked for small, informative indicators and a floating message when something is gained. The layout was
agreed with the author on 2026-10-18.

## What Changes

- **Checkpoint track:** a row of small flags at the top left, under the pause button, one per checkpoint in the
  level. A pending checkpoint is grey; a reached one turns gold. The row is hidden in levels without checkpoints.
- **Active boosts and orb:** a short column at the top right, under the sound button, where the player looks.
  - Each running boost (jump, speed, gravity) shows its icon with a ring that empties over its duration.
  - The orb's icon shows while its charge is held; the jump button's charged look stays.
  - These temporary indicators are larger than the fixed ones.
- **Pickup message:** collecting an orb or reaching a checkpoint shows a short floating message above the ball, with
  the element's icon and color, such as "Double jump!" or "Checkpoint". It rises a little and fades in under a
  second. It is smaller and shaped differently from the level-start banner, and translated into English, Spanish and
  Catalan.
- **Restraint:** indicators stay small, in the top corners under the buttons, clear of the system's status bar and
  camera cutout; nothing covers the joystick or the jump button. The pause and sound buttons also move clear of the
  status bar and cutout.
- **ADR-0011** records the HUD layout and sizing.

Out of scope: first-encounter explanation bubbles (a later change may reuse the message), and new mechanics.

## Capabilities

### New Capabilities
- `game-hud`: the in-game indicators and messages that report the player's state during play: checkpoints reached,
  running boosts, the orb's charge, and pickups.

### Modified Capabilities

## Impact

- **Game (`lib/game/`):**
  - new HUD components in the camera viewport;
  - the ball exposes which boost is running and for how long;
  - the level reports pickups;
  - `HudLayout` gains indicator sizes.
- **App:**
  - `GamePage` passes the translated message texts to the game, as it does for the level label;
  - new strings in `lib/l10n/arb/app_{en,es,ca}.arb`.
- **Docs:** ADR-0011, `docs/architecture.md`, and the product table in `docs/product.md`.
- No new dependencies. Frame time is measured on the reference phone.
