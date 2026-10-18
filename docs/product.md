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
| Ball | Rolls with proportional tilt (Android, portrait or landscape), the on-screen joystick or `A`/`D`; jumps about 2.7 m with the arrow button, `Space` or a gentle flick of the phone, from the top of the ground only, or once in mid-air with an orb's charge |
| Worlds | Ten levels each, cycling through five biomes (night forest, desert dusk, snowy peaks, crystal caves, volcano), with seeded variations when a biome repeats; a new world announces its name |
| Look | Generated terrain and backdrops per biome, the painted night-forest backdrop kept; boosts, orbs, spikes, platforms, checkpoints and the goal drawn with depth and a clear icon, the same in every biome |
| Camera | Frames the ball in the lower half with more course ahead the faster it goes, follows the ground smoothly and zooms out before boosts, at high speed and on high jumps, in portrait and landscape |
| Levels | Generated from the savegame's seed and the level number; about 35 s long at first, growing to two or three minutes deep |
| Difficulty | Demanding from level 1, with ramps, gaps, drops, steps and spikes; ferries from level 3, speed boosts and crumbling islands from 6, jump boosts and island hops from 11, gravity boosts from 16 and double-jump orbs from 21, each featured in its first five levels; one gentler breather level per stage of five; gaps and climbs use a growing share of the ball's reach, from about 70–80 % to 90–95 %, so deep levels demand take-offs near the edge at full speed; it keeps rising with no ceiling |
| Terrain | Floor runs, ramps, gaps (level, rising or falling), drops and steps up, plus set pieces (staircases, cascades, valleys, island hops), all sized to what the ball can do from the speed it can build there |
| Mechanics | Spikes send the ball back like a fall; ferries carry it across gaps too wide to jump, pausing at each edge; crumbling islands collapse 0.6 s after the ball stands on them; a respawn restores crumbled islands and collected orbs |
| Variety | Each level features two or three sections of its own and alternates bursts of obstacles with rest stretches |
| Boosts | Jump (upward impulse), speed (forward impulse), gravity (low gravity for 2 s) and the double-jump orb (one air jump, shown on the jump button), each placed before the section that needs it |
| Checkpoints | In longer levels; touching any part of the flag turns it gold, and a fall respawns the ball there |
| Goal | Reaching it flashes the screen and loads the next level in place |
| Pause | The pause button, the back button and the app going to the background open the pause menu: resume, restart, settings, levels; back again resumes |
| Settings | Music and effects volume, quick mute, control mode and vibration (both hidden on the web), language (device by default) |
| Vibration | On by default on Android: a light pulse when the ball jumps, a strong one for boosts, a double one for checkpoints |
| Audio | Music starts on launch (on the web, at the first interaction); effects share one loudness |
| Savegames | A savegame has a seed and a fixed number of levels; levels unlock as you clear them |
| Languages | English, Spanish, Catalan |

## Known gaps

- Levels are still finite per savegame, which contradicts the infinite-climb vision; the next change replaces the
  progression model.
- There is one mode, with unlimited retries. The challenge mode, the original world, the daily challenge and shared
  seeds come in the next change.
- The difficulty curve's numbers are first estimates, to be tuned by playing.
- Physics feel has not been re-tuned since the move to Box2D v3.

## Open product questions

To be answered with the author while specifying the rebuild, and recorded as ADRs:

- How progress is kept in an infinite climb: best level reached per mode, and lives in the challenge mode.
- How the daily challenge and shared seeds are offered in the menus.
- Which new mechanics, if any, join the generator once the existing elements are tuned.
