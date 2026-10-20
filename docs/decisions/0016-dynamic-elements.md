---
type: decision
title: "ADR-0016: Fans, bumpers, pendulums and seesaws"
description: "Fans blow upwards and are always on; bumpers stand as posts after gaps and sit low in risers; maces swing on a rhythm and push the ball; seesaws tip over pits. Each is measured with the real ball and introduced at levels 15, 17, 19 and 21."
tags: [level-generation, physics, mechanics]
---

# ADR-0016: Fans, bumpers, pendulums and seesaws

**Date:** 2026-10-20 · **Status:** accepted

## Context

ADR-0015 set four dynamic elements for levels 15 to 21, so deep levels gain life and new kinds of challenge. Unlike
the static terrain, they move or push the ball. The author chose how three of them play:

- **Fans:** upwards and always on, rather than with cycles or in several directions.
- **Pendulums:** maces that push the ball, rather than blades that send it back.
- **Seesaws:** planks over a pit, rather than moving ramps on solid ground.

The bumpers were first proposed as roofs over drop gaps. The author's play-test found them senseless: going under
hit the roof, so they went over it. They chose posts on the ground instead. They also asked for faster, harder maces,
faster fans, and obstacles on wavy stretches, which felt empty.

## Decision

- **Fans (level 15):**
  - a column of air lifts the ball towards a hover height two thirds up and settles it there, while the player
    steers;
  - they float the ball across pits wider than any jump, sometimes split into columns with a tile of no wind between
    them;
  - set in the floor, they lift it over a wall higher than a jump boost reaches.
- **Bumpers (level 17):**
  - a bumper throws the ball away from it at a fixed speed;
  - posts stand on short stands on the run after a gap, to be jumped; landing long or rolling on runs into one,
    which throws the ball back towards the gap;
  - set low in the riser of a short tread, a bumper kicks an overshoot back into the gap.
- **Pendulums (level 19):**
  - iron maces swing on a fixed rhythm and throw the ball away hard when they hit it;
  - two tiles before each mace are out of its reach, for waiting;
  - the lane stays clear long enough to cross from rest at the back of that room;
  - deep runs hang up to three maces.
- **Seesaws (level 21):**
  - a light, balanced plank rests leaning back over a pit;
  - past its pivot it tips forwards;
  - the player jumps from its far end to the far bank, and a ball left on it rolls off the low end;
  - a respawn puts it back at rest.
- **Honest sizes:** each element is measured with the real ball and becomes part of the movement envelope:
  - fans: how low a floating ball's bottom bobs, how deep a column catches the ball, how fast it rises;
  - seesaws: the speed and the jump at the far end.

  The generator needs only exact operations and square roots, so levels stay the same on every platform.
- **Curves with obstacles:** hills and half-pipes often carry spikes in a valley or a speed boost and a long gap
  after them, more often deep.
- **Vertical travel:** a course that has taken more than a minute of play to reach its target height slopes its
  landings towards it, and gaps lean towards that height two to one. Flow-heavy levels with no climbs no longer stay
  flat.

## Consequences

- Deep levels mix floating, rolling off, waiting and riding with the jumps and boosts.
- Existing savegames keep their level numbers and get new courses (generator version 6).
- Fans, maces and seesaws keep laser barriers away, and a fan's base counts as ground for fall detection.
- The logic and memory mechanics come next, at levels 10, 12, 14 and on.
