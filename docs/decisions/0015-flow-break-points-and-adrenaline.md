---
type: decision
title: "ADR-0015: A heavier ball, flow with break points, and the adrenaline rush"
description: "The ball falls a fifth faster with jumps of the same height; levels alternate flow and challenge phrases, with break points that catch a relaxed player; deep levels fill up; the adrenaline rush arrives at level 5; fans, bumpers, pendulums and seesaws follow at levels 15–21."
tags: [difficulty, pacing, level-generation, physics]
---

# ADR-0015: A heavier ball, flow with break points, and the adrenaline rush

**Date:** 2026-10-19 · **Status:** accepted

## Context

After the curved terrain and the new physics (ADR-0014), the author's play-tests found the early levels better but
still too easy, and the deep levels empty: long courses with few boosts and elements, and repeated plain steps,
simple slopes and easy wall climbs. The ball flew off slopes too easily.

The author wants flow as the heart of the game: build speed, chain the route and stop only to interact. Gaps keep
their weight, and somewhere a break point catches the player who relaxes; that contrast is what makes the game
addictive. The traps that punish rushing stay. The author also asked for tense moments where the ball goes faster
and responds more strongly: an "adrenaline rush".

## Decision

- **A heavier ball:** gravity rises from 10 to 12 m/s², with the jump, the jump boost and the trampoline
  compensated so they keep their heights. A jump boost taken while falling first stops the fall, and one taken while
  jumping adds to it.
- **Flow and challenge:** levels alternate flow phrases, taken without stopping, and challenge phrases. A flow phrase
  may end in a break point:
  - a short tread before a riser;
  - spikes just past a landing;
  - a gap right after a crest.

  This happens 20 % of the time at level 1, rising to 80 % deep.
- **Fuller deep levels:**
  - shorter rests and longer phrases;
  - boosts, orbs, trampolines, loops, surfaces, ferries and crumbling islands weigh up to twice as much;
  - plain gaps and climbs weigh less;
  - two plain climbs never follow each other, and deep towers mix in jump-boost steps.
- **A slightly harder start:** intensity 0.80 at level 1, with gentler easing on introductions, and no longer
  courses.
- **The adrenaline rush (level 5):** some tense phrases become zones where the push is 25 % stronger, sized from that
  speed. They are marked in red, with a heartbeat sound and vibration and a heart in the HUD.
- **Next elements:** fans, bumpers, pendulums and seesaws arrive at levels 15, 17, 19 and 21, in their own change,
  measured with the heavier ball. The logic mechanics follow, alternating every two or three levels.

## Consequences

- Courses have a rhythm, and their difficulty comes from contrast as well as precision.
- Existing savegames keep their level numbers and get new courses (generator version 5).
- The movement envelope was re-measured: jumps carry about 8 % less far, and the loop shrank to 1.75 m to keep its
  margin.
