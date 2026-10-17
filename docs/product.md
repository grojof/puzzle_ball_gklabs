---
type: explanation
title: "Product"
description: "What Ball Odyssey is, who it is for, and the gameplay it is being rebuilt towards."
tags: [product, gameplay, vision]
audience: maintainer
---

# Product

## Vision

Ball Odyssey is a physics platformer where you guide a ball through **infinite, procedurally generated levels whose
difficulty keeps rising**. Each level is generated from a seed, so a run can be replayed and shared.

It should work for two kinds of players:

- **Casual players** enjoy the early levels: short, readable, forgiving.
- **Hardcore players** treat it as a long challenge: deep runs where the levels get long, complicated, varied and
  still fun, never absurd or unfair.

"Competitive" means the climb itself: there is no last level, only how far you get.

## Gameplay today

What the current baseline does (the rebuild changes it through OpenSpec changes):

| Element | Behavior |
|---|---|
| Ball | Rolls with tilt (Android), the on-screen joystick or `A`/`D`; jumps with the button, `Space` or a shake |
| Terrain | Floor tiles and ramps, flat runs, height changes and gaps |
| Boosts | Jump (upward impulse), speed (forward impulse) and gravity (low gravity for 2 s) |
| Checkpoints | Shown, but falling still restarts the whole level |
| Goal | Reaching it flashes the screen and loads the next level |
| Savegames | A savegame has a seed and a fixed number of levels; levels unlock as you clear them |
| Languages | English, Spanish, Catalan |

## Known gaps

- The savegame seed is ignored: every savegame plays the same levels.
- The difficulty curve overflows its intended range on later levels, so generation parameters stop making sense.
- Levels are finite per savegame, which contradicts the infinite-climb vision.
- Long sessions slow the game down (audio players and timers accumulate).

## Open product questions

To be answered with the author while specifying the rebuild, and recorded as ADRs:

- How progress is kept in an infinite climb (runs, best level reached, lives or checkpoints).
- How difficulty scales and which mechanics are introduced as levels advance.
- Whether seeds are shareable and whether there is a daily or fixed-seed mode to compare runs.
