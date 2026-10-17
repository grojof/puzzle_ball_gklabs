---
type: decision
title: "ADR-0009: A deterministic level generator bounded by a measured movement envelope"
description: "Levels come from a pure Dart package that sizes every obstacle from the ball's measured abilities, and three layers of tests prove each level can be completed."
tags: [levels, procedural-generation, physics, testing]
---

# ADR-0009: A deterministic level generator bounded by a measured movement envelope

**Date:** 2026-10-17 · **Status:** accepted

## Context

Ball Odyssey is an infinite climb: levels never end and keep getting harder. The baseline generator could not support
that. It ignored the savegame seed, its difficulty parameter overflowed after a few levels, it sized gaps and climbs
with fixed numbers unrelated to what the ball can do, and it could place ramps on top of tiles. A level that cannot be
completed ends a run unfairly, and with infinite levels nobody can check them by hand.

## Decision

- **A pure Dart package, `packages/level_generator`,** turns a seed and a level number into `LevelData`: floor runs,
  ramps, boosts, checkpoints, the ball start and the goal. It has no Flutter or Forge2D dependency, so tests generate
  thousands of levels in seconds.
- **The same seed and level give the same level on every platform.** The package uses its own 32-bit PRNG
  (mulberry32 with 16-bit split multiplication) and FNV-1a seed hashing, because `dart:math`'s `Random` gives no such
  guarantee and web integers are exact only to 2^53. Generation uses exact arithmetic only. The difficulty curve's
  outputs that use `exp` are quantized to 1e-6, so tiny platform differences cannot change a level. Golden tests run
  on the VM and in Chrome, and `generatorVersion` changes whenever output changes on purpose.
- **A movement envelope bounds every obstacle.** `MovementEnvelope` holds what the ball can do: jump height, flight
  time, top speed and its acceleration, and the reach of each boost. These numbers were measured with the real
  physics and rounded down. The generator sizes each gap and climb from the speed the player can have at that point,
  times a safety margin that rises towards 0.85 (precise). When a fast player must brake in the air to land on a
  short run, the next obstacle is sized for the slower speed.
- **Difficulty starts high, follows stages and a sawtooth, and has no ceiling.** Level 1 is already a real challenge
  with ramps, gaps, drops and steps; a gentle start felt pointless in play. Stages are five levels long, and each of
  the next three adds a boost. One breather level per stage is easier. Intensity, margins, obstacle density and length
  keep rising with the level number.
- **Each level has its own character.** Besides single obstacles, set pieces combine the same elements (staircases,
  cascades, valleys, island hops). Each level features two or three kinds, which make up most of its obstacles, and
  alternates bursts of obstacles with rest stretches.
- **Three layers of tests check that levels can be completed:**
  - the package's validator checks every generated level against the envelope, over many seeds and levels;
  - a game test drives the real ball and fails if the physics stops reaching an envelope number;
  - a bot plays one level per stage plus deep levels with the real physics.

## Consequences

- Physics can be tuned safely: if the ball gets weaker, the envelope test fails until the envelope numbers are
  lowered, and the generator follows them.
- Changing generation changes the levels for every seed. That is acceptable while savegames keep only a level number,
  and `generatorVersion` lets shared seeds detect it later.
- Curve numbers (durations, margins, breather factor) are named constants in `DifficultyCurve`, tuned by playing.
- The generator only uses the existing elements. New mechanics need envelope numbers, validator rules and bot support.
