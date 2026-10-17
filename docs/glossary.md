---
type: reference
title: "Glossary"
description: "Domain vocabulary of Ball Odyssey: levels, seeds, difficulty, generation, terrain and game objects."
tags: [glossary, domain]
audience: maintainer
---

# Glossary

| Term | Meaning |
|---|---|
| **Level** | One generated course from the ball start to the goal. |
| **Seed** | The value that makes level generation deterministic: same seed and level number, same level. |
| **Difficulty curve** | The function from level number to generation parameters: intensity, safety margin, obstacle share, target duration, checkpoint spacing and which sections may appear. |
| **Stage** | Five consecutive levels. The first stage has ramps, gaps, drops, steps, staircases, cascades and valleys; the next three each add a boost (speed, then jump with island hops, then gravity); later stages only raise intensity. |
| **Breather** | The gentler fourth level of each stage, so difficulty rises in a sawtooth rather than a straight line. |
| **Movement envelope** | What the ball can do, as numbers measured with the real physics: jump height, flight time, top speed and the reach of each boost. The generator keeps every obstacle within it. |
| **Safety margin** | The fraction of the envelope a level may use: about 0.63 on the first level, rising towards 0.85. |
| **Section** | One piece of a generated level: a flat, a ramp, a gap, a drop, a step up, a set piece or a boost setup, followed by a landing. |
| **Set piece** | A section composed of several elements: a staircase (steps up), a cascade (drops), a valley (ramp down, gap, ramp up) or island hops (gaps between platforms at changing heights). |
| **Featured sections** | The two or three sections and set pieces a level uses most, which give it its own character. |
| **Phrase** | A group of back-to-back obstacles, or a rest stretch of flat ground; levels alternate them for rhythm. |
| **Run** | A playthrough of consecutive levels from one seed. |
| **Floor run** | A stretch of ground at one height, built as a single physics body and drawn with repeated tiles. |
| **Savegame** | Stored progress: seed, current level and timestamps. |
| **Tile** | A floor block of the terrain, 1.5 m wide in the physics world. |
| **Ramp** | A slope with its own horizontal span, at most 35°, joining two floor runs at different heights. |
| **Gap** | A stretch without floor that the ball must jump. |
| **Boost** | A sensor that changes the ball's motion: jump, speed or gravity. |
| **Checkpoint** | A sensor that the ball activates by passing; after a fall the ball respawns above the last active one. |
| **Goal** | The sensor at the end of a level that completes it. |
| **Meter** | The physics unit; `metersToPixels` converts it to screen pixels. |
