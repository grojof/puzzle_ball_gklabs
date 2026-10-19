---
type: decision
title: "ADR-0014: Curved terrain from level 1, new physics interleaved with the logic mechanics"
description: "Hills and half-pipes join the basics at level 1; trampolines, conveyor belts with ice and mud, and loops arrive at levels 9, 11 and 13, leaving levels 10, 12, 14 and on to the logic mechanics. Amends the introductions of ADR-0013."
tags: [difficulty, pacing, level-generation, physics]
---

# ADR-0014: Curved terrain from level 1, new physics interleaved with the logic mechanics

**Date:** 2026-10-19 · **Status:** accepted · **Amends:** [ADR-0013](0013-demanding-pacing.md) (introductions)

## Context

After the demanding pace of ADR-0013, the author's play-test still found levels 1 to 60 monotonous: every slope was a
straight ramp, and every climb a step or a ramp. The author asked for new physics, such as curved ramps, and chose
four:
- curved terrain;
- trampolines;
- conveyor belts with ice and mud;
- the loop.

ADR-0013 had every physical element known by level 8 and kept level 10 on for the logic and memory mechanics.

## Decision

- **Level 1:** hills and half-pipes join the basics, and every slope between two heights is rounded: straight ramps,
  whose descents broke the experience, are no longer built.
- **Trampolines** serve the island hops across pits, and come often; high ledges are left to the jump boost, which
  combines with a normal jump.
- **Interleaved introductions:** trampolines at level 9, conveyor belts, ice and mud at level 11, and the loop at level
  13, each featured in its first five levels. Levels 10, 12, 14 and on stay free for the logic and memory mechanics,
  which a later change introduces.
- **The loop** comes with a speed boost before it, so the speed it needs is guaranteed.
- **Honest reach:** each element is measured with the real physics and sized by the generator like the existing ones.

## Consequences

- Variety arrives early: the curves from level 1, a new physical element every other level from 9 to 13.
- Existing savegames keep their level numbers and get new courses (generator version 4).
- The logic mechanics start at level 10 and alternate with the physics.
