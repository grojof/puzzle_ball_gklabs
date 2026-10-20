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
| **Difficulty curve** | The function from level number to generation parameters: intensity, precision, obstacle share, target duration, checkpoint spacing and which sections may appear. |
| **Stage** | Five consecutive levels, for pacing: each has one breather. Elements are introduced by level: hills, half-pipes, spikes and the set pieces at level 1, ferries at 2, speed boosts at 3, crumbling islands at 4, island hops and the adrenaline rush at 5, jump boosts at 6, gravity boosts at 7, orbs at 8, trampolines at 9, conveyor belts, ice and mud at 11, loops at 13, fans at 15, bumpers at 17, pendulums at 19 and seesaws at 21. |
| **Breather** | The gentler fourth level of each stage, so difficulty rises in a sawtooth rather than a straight line. |
| **Movement envelope** | What the ball can do, as numbers measured with the real physics: jump height, flight time, top speed, the reach of each boost and trampoline, the speed and jump on each surface, and the speed a loop needs. The generator keeps every obstacle within it. |
| **Precision** | The share of the reach each gap and climb uses, drawn from an interval that grows with the level: about 82–89 % on the first level, towards 90–95 % deep. Its high end is the most any gap may use, which the validator checks. |
| **Reach** | How far or how high the ball can jump at a point of the course, from the speed it can build on the run-up there, measured against the real physics. |
| **Section** | One piece of a generated level: a flat, a ramp, a gap, a drop, a step up, a set piece or a boost setup, followed by a landing. |
| **Set piece** | A section composed of several elements: a staircase (steps up), a cascade (drops), a valley (ramp down, gap, ramp up), island hops (gaps between platforms at changing heights), a tower (a climb of 8–14 m by tall steps) or a descent (a drop of 8–16 m by drops, ramps and gaps). |
| **Featured sections** | The two or three sections and set pieces a level uses most, which give it its own character. |
| **Phrase** | A group of back-to-back obstacles, or a rest stretch of flat ground; levels alternate them for rhythm. A **flow phrase** is taken without stopping, each obstacle sized for the speed carried; a **challenge phrase** mixes any obstacles. |
| **Break point** | The end of a flow phrase where carrying its speed fails: a short tread before a riser, spikes just past a landing, or a gap right after a crest. A player who brakes in time gets through. |
| **Adrenaline rush** | A tense stretch marked in red where the ball's push is a quarter stronger, so it runs faster; gaps there are sized from that speed. Leaving it or a respawn ends it. |
| **Depth** | How far a level has climbed the difficulty curve, from 0 at the start to 1 deep; richer sections, break points and rushes grow with it. |
| **Run** | A playthrough of consecutive levels from one seed. |
| **World** | Ten consecutive levels sharing one biome; the first level of a world announces its number and biome. |
| **Biome** | The look of a world: a palette, a terrain material, a backdrop and ambient particles (night forest, desert dusk, snowy peaks, crystal caves, volcano). |
| **Variant** | How a repeated biome differs from its first appearance: palette, time of day and backdrop layers, drawn from the seed. |
| **Floor run** | A stretch of ground at one height, built as a single physics body and drawn with repeated tiles. |
| **Savegame** | Stored progress: seed, current level and timestamps. |
| **Tile** | A floor block of the terrain, 1.5 m wide in the physics world. |
| **Ramp** | A slope joining two floor runs at different heights, no steeper than 35°; the generator builds them rounded, as curves. |
| **Curve** | A smooth stretch of ground between two runs, no steeper than a ramp: a **hill** of one to three bumps, a **half-pipe** dipping below the ground, or a rounded **slope** between two heights. |
| **Surface** | What a floor run's top is made of: plain, a **conveyor belt** that carries the ball forwards or backwards, **ice**, slow to speed up and slow to stop, or **mud**, which holds the ball slow and weakens its jump. |
| **Trampoline** | A pad on a floor run that throws the ball up to the same height whatever its fall, keeping its horizontal speed. |
| **Loop** | A vertical circle the ball rides around on its inside after a speed boost; a ball too slow rolls back out. |
| **Fan** | A column of air blowing upwards, always on, that floats the ball at a hover height halfway up: across a pit too wide to jump, or set in the floor, up a wall. |
| **Bumper** | A pinball bumper that throws the ball away from it at a fixed speed: in a **bumper roof** over a drop gap, which a jump hits and rolling off clears, or low in the riser of a short tread. |
| **Pendulum** | An iron mace on a rigid arm, swinging over a run on a fixed rhythm; it knocks the ball, and leaves its lane clear long enough to cross from the tile before it. |
| **Seesaw** | A plank on a pivot over a pit, resting with its near end level with the run; past the pivot it tips forwards, and the ball jumps from its far end. |
| **Gap** | A stretch without floor that the ball must jump. |
| **Boost** | A sensor that changes the ball's motion: jump, speed or gravity, or an orb. |
| **Orb** | A double-jump orb: collecting it charges one jump the player can use in mid-air, shown on the jump button; it comes back after a respawn. |
| **Spikes** | A strip on a floor run that sends the ball back like a fall. |
| **Laser barrier** | A beam hanging in the air over a descent or after a tower top, lit and dark in turn; touching it lit sends the ball back. It hangs above every jump of the intended route, so only shortcuts meet it. |
| **Heading** | The height a course is traveling towards; once reached, the generator picks another inside the 65 m band. |
| **Ferry** | A moving platform that shuttles across a gap too wide to jump, pausing next to each edge. |
| **Crumbling island** | A short floor run between gaps that collapses 0.6 s after the ball stands on it. |
| **Checkpoint** | A sensor that the ball activates by passing; after a fall the ball respawns above the last active one. |
| **Goal** | The sensor at the end of a level that completes it. |
| **Meter** | The physics unit; `metersToPixels` converts it to screen pixels. |
| **Look-ahead** | How much more of the course the camera shows ahead of the ball, growing with its speed. |
