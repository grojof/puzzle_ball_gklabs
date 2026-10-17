---
type: reference
title: "Glossary"
description: "Domain vocabulary of Ball Odyssey: levels, seeds, difficulty, terrain and game objects."
tags: [glossary, domain]
audience: maintainer
---

# Glossary

| Term | Meaning |
|---|---|
| **Level** | One generated course from the ball start to the goal. |
| **Seed** | The value that makes level generation deterministic: same seed and level number, same level. |
| **Difficulty curve** | The function from level number to generation parameters (gap sizes, height changes, boost frequency). |
| **Run** | A playthrough of consecutive levels from one seed. |
| **Savegame** | Stored progress: seed, current level and timestamps. |
| **Tile** | A floor block of the terrain, 1.5 m wide in the physics world. |
| **Ramp** | A triangular block that joins tiles at different heights. |
| **Gap** | A stretch without floor that the ball must jump. |
| **Boost** | A sensor that changes the ball's motion: jump, speed or gravity. |
| **Checkpoint** | A sensor that marks a respawn point within a level. |
| **Goal** | The sensor at the end of a level that completes it. |
| **Meter** | The physics unit; `metersToPixels` converts it to screen pixels. |
