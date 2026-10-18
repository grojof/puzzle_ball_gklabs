---
type: decision
title: "ADR-0013: A demanding pace from level 1, everything known by level 8"
description: "Level 1 starts as hard as the old level 50, courses last 1.5 to 4 minutes over a wide band of heights, every physical element is introduced by level 8, and shortcuts stay possible but laser barriers guard them."
tags: [difficulty, pacing, level-generation]
---

# ADR-0013: A demanding pace from level 1, everything known by level 8

**Date:** 2026-10-18 · **Status:** accepted

## Context

After the physical mechanics and the HUD, the author's play-test found the levels too easy and repetitive: only levels
50 to 60 felt right, so about thirty levels went by without a real challenge. The courses were short (35 seconds at
first) and stayed within a narrow band of heights. The author also wanted players free to try long jumps and drops,
with the course designed so that such shortcuts are risky rather than impossible.

## Decision

- **Start:** level 1 is as demanding as the old level 50 (intensity 0.76: gaps and climbs use 82–89 % of the reach).
  The curve keeps rising towards 90–95 % with no ceiling. Breathers and introductions ease off less, so no level is
  trivial.
- **Length:** courses last about 90 seconds at level 1, growing to about 4 minutes, with a checkpoint about every 35
  seconds.
- **Introductions:**
  - level 1: the basics, spikes and the set pieces (staircase, cascade, valley, tower, descent);
  - then one element per level: ferries at 2, speed boosts at 3, crumbling islands at 4, island hops at 5, jump boosts
    at 6, gravity boosts at 7 and orbs at 8.
  - Levels from 10 on are kept for the logic and memory mechanics.
- **Heights:** the course travels within a band of about 65 m, heading for a new height when it reaches one. Towers
  climb 8–14 m and descents drop 8–16 m.
- **Freedom with a price:**
  - a fall is detected only once no ground is left that the ball could still reach, so a long jump or drop onto real
    ground always counts;
  - laser barriers hang over descents and after tower tops, above every jump of the intended route. They light and
    darken in turn, so a shortcut through them needs timing.

## Consequences

- New players meet a real challenge at once. The play-test checks that levels 1–10 stay fair.
- The bot tests take longer, since levels are longer, and the local stress run guards generator changes.
- Existing savegames keep their level numbers and get new courses (generator version 3).
- New mechanics after this one start at level 10 or later.
