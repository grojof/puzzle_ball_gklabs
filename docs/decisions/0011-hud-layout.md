---
type: decision
title: "ADR-0011: A small HUD in the top corners"
description: "Checkpoint flags under the pause button, running boosts and the orb's charge under the sound button, pickup messages over the ball, all clear of the system's status bar and camera cutout; fixed indicators small, temporary ones larger."
tags: [hud, controls, layout]
---

# ADR-0011: A small HUD in the top corners

**Date:** 2026-10-18 · **Status:** accepted

## Context

After the physical mechanics, the author asked for indicators of the running boosts, the orb's charge and the
checkpoints reached, plus a floating message when something is gained. Their first idea was columns on the sides:
boosts on the right and checkpoints on the left. The screen already holds the pause button at the top left, the sound
toggle at the top right, and the joystick and jump button in the bottom corners. The camera shows more of the course
ahead on the right, where the obstacles come from. The author asked for indicators that are small and merely
informative: the fixed ones minimal, the temporary ones a little larger.

A first version put the boosts at the top centre and the flags beside the pause button. On the author's phone, the
camera cutout at the top centre hid the boost icons, and the author preferred them at the top right under the sound
button, where the player looks. The flags read better under the pause button, a little larger.

## Decision

- **Checkpoints:** a row of small flags under the pause button, one per checkpoint, grey until reached and gold
  after. Beyond eight, a flag and a count.
- **Running boosts and the orb's charge:** a short column under the sound button, at the top right. Each boost's icon
  has a ring that empties over its duration; the orb's icon shows while its charge is held.
- **Pickup messages:** a small pill in the element's color with its icon and text, over the ball. It rises a little,
  follows the ball and fades within 0.9 s. It appears for the orb and checkpoints only, since boosts already show a
  larger timed icon.
- **Sizes**, from the screen's shorter side:
  - flags: 20–28 px;
  - boost and orb icons: 28–40 px;
  - message text: 16–24 px.
- **Safe area:** the indicators and the pause and sound buttons are offset by the system's view padding, so the
  status bar and the camera cutout never cover them. Nothing goes over the joystick, the jump button or the middle of
  the screen.

## Consequences

- The middle of the screen stays clear in both orientations. The top corners, usually sky, carry the indicators.
- The indicators mirror the positions of two Flutter buttons. `HudLayout` holds those positions as constants, and a
  widget test keeps them aligned.
- A future first-encounter explanation can reuse the pickup message's look.
- If a level ever needs more than eight checkpoints, the count replaces the flags.
