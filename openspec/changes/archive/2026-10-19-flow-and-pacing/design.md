# Design

## Context

See proposal.md for the motivation. Today:

- **Physics:** the world's gravity is 10 m/s². The ball's jump impulse (65.5), the jump boost's (120) and the trampoline's
  launch speed (15.5 m/s) are set for it. The push is 80 N against a damping of 1.5/s.
- **Pacing:**
  - a level is a sequence of phrases: a rest stretch of 3–5 tiles (up to 7 on breathers), or 2 to `2 + 3 ×
    intensity` obstacles back to back;
  - obstacles are featured kinds 75 % of the time, otherwise heading for the course's target height or any kind;
  - intensity starts at 0.76, and the obstacle share is `0.35 + 0.45 × intensity`.
- **Weights:** fixed per kind, doubled for five levels after an introduction. Deep levels mostly repeat plain gaps,
  steps and curves, and use boosts only as often as level 10 does.
- **Generator:** exact arithmetic, a measured envelope, an honest speed model, a validator, golden digests, a bot and
  a local stress run of 680 levels.

## Goals / Non-Goals

**Goals:**
- A slightly heavier ball, with jumps of the same height.
- A rhythm of flow and challenge, with break points.
- Fuller deep levels, varied climbs, and a slightly harder start.
- The adrenaline rush.

**Non-Goals:**
- Fans, bumpers, pendulums and seesaws: `add-dynamic-elements`, next.
- Logic and memory mechanics: later, alternating every two or three levels.
- Longer levels.

## Decisions

### D1. Heavier ball, same jump heights
- **Gravity:** the world's gravity goes from 10 to 12 m/s².
- **Compensated launches:** the jump impulse, the jump boost's impulse and the trampoline's launch speed rise so each
  reaches the height it reached before. A launch's height against damping `k` is `v/k − (g/k²) ln(1 + k v / g)`, which
  gives the starting values: about +6 % for the jump. They are then measured with the real ball.
- **Unchanged:** the gravity boost keeps its scale, now of a stronger gravity, and the double jump follows the jump.
- **Re-measured:** the whole envelope:
  - flight times shrink, so jumps carry about 8 % less far;
  - the speed curve is nearly unchanged;
  - the curve exit speed, the loop's entry speed and the trampoline's reach are measured anew.

  The loop's entry speed rose with gravity, so its radius shrank from 2 m to 1.75 m to keep the boost at 1.2 times
  that speed.
- **Floor tops:** every floor run's top becomes a chain with level ghost ends, as runs next to a curve or a run at the
  same height already had. A ball landing right on a run's edge no longer catches on the box's corner and bounces,
  which the stress run showed costing a jump its speed.
- **The ball:**
  - it allows fast rotation: Box2D otherwise caps its rotation per step, which capped a rolling ball near 9.3 m/s;
  - it never sleeps, since it is the only moving body.
- **Jump boosts from a fall:** a jump boost taken while falling, as on a short tread reached by a gap, first stops the
  fall, so it climbs at least as high as from the ground. One taken while jumping still adds to the jump.
- **Measured** (rounded down): flight time 1.4 s, double jump 20 m, speed-boost jump 20 m, gravity-boost jump 27.5 m,
  trampoline flight 1.95 s and reach from rest 13.5 m, mud jump 1.7 m in 1.1 s; the jump and the boosts' heights are
  unchanged.
- *Alternative: a gravity scale on the ball only.* Rejected: the gravity boost already sets the ball's scale, and
  only the ball is dynamic, so the world's gravity is the simpler knob.

### D2. Phrases: flow and challenge
Each phrase after a rest stretch is a flow phrase or a challenge phrase, half and half.

- **Flow phrases:** three to six sections drawn from the flow kinds, featured kinds first:
  - hills, half-pipes, slopes down, plain gaps, drops and cascades;
  - speed boosts, loops, trampoline hops and forward belts.

  Each lands on a run of at least two tiles, and the speed model carries the speed through, as it does today. So a
  player who keeps pushing chains them without stopping.
- **Challenge phrases:** the current phrases, from every kind available, with what follows.
- **Introductions:** while a level still has an element to introduce, its phrases are challenge phrases, so every
  element appears in its level.
- **Character:** at least one featured kind fits a flow phrase, so flow phrases share the level's character.

### D3. Break points
A flow phrase ends in a break point with a probability of `0.2 + 0.6 × (intensity − 0.76) / 0.24`: 20 % at level 1,
rising to 80 % deep. A break point is one of:

- **Short tread:** a gap onto a single tile, followed at once by a step up: beyond a jump with a jump boost on the
  tile once jump boosts are known, a plain step before that. A player who flies in fast overshoots the tile into the
  riser and falls back into the gap.
- **Spiked landing:** a drop or gap whose landing run has spikes starting two tiles in. A fast player lands on them;
  a careful one lands short and has a tile to run up to them.
- **Gap after a crest:** a hill whose last bump ends a tile before a gap. A fast ball takes off from the crest over
  the tile, short of the gap's far side.

Each is built from existing primitives, sized with the landing cap, which assumes a player braking in the air to land
on the given landing. So the validator's rules already prove a braking player gets through. The speed model resets to
what a player has after braking to land.

The stress run showed the speed model too generous in two places, which more flow made common:

- after a cascade, a player stepping down the treads comes off the last ledge braking, so the last drop's landing cap
  applies too;
- landing late on a single tile leaves half a tile to speed up, not a whole one.

### D4. Fuller deep levels
- **Rests:**
  - rest stretches last 3–5 tiles at level 1, shrinking to 2–3 deep;
  - breathers keep up to 6.
- **Obstacles:**
  - phrases hold up to `3 + 3 × intensity` obstacles;
  - the obstacle share starts at `0.45 + 0.45 × intensity`.
- **Weights:** they scale with depth `d = (intensity − 0.76) / 0.24`, from 0 at level 1 to 1 deep:
  - boosts, orbs, trampoline hops, loops, surfaces, ferries and crumbling hops: `× (1 + d)`;
  - plain gaps and slopes: `× (1 − 0.4 d)`;
  - plain steps, staircases and towers: `× (1 − 0.5 d)` (D5).

### D5. Varied climbs
- **No repeats:** the generator never draws a plain climb (step up, staircase, tower) right after another. It draws
  again, from the other kinds.
- **Deep towers:** past `d = 0.4`, each of a tower's steps is a jump-boost climb with a probability of `0.3 × d`,
  with its boost on the tread before it.
- **Heading:** curves keep their height, so climbs and descents towards the course's target height weigh three times
  as much (2.5 before), and the course still travels its band.

### D6. A slightly harder start
- **Intensity:** the starting intensity goes from 0.76 to 0.80: precision 83–90 % at level 1.
- **Introductions:** eased less (0.95 instead of 0.92).
- **Breathers:** stay at 0.88.
- **Duration:** stays 90 s at level 1.

The rising obstacle share and the flow phrases make level 1 denser, not longer.

### D7. The adrenaline rush
- **Data:** `LevelData.adrenaline`, a list of `AdrenalineZone(left, right)`.
- **Generation:**
  - from level 5, introduced like an element;
  - a challenge phrase of tense kinds (spikes, crumbling hops, island hops, a descent) becomes a zone with a
    probability of `0.3 + 0.3 d`, at most once every 40 s of estimated play;
  - the zone spans from a tile before its first obstacle to the end of its last landing;
  - no checkpoint stands in a zone, since a respawn ends the rush.
- **Physics:** while the ball is inside a zone, its push is multiplied by 1.25 with the same damping. Its speed after
  `x` meters is `1.25 · v(x / 1.25)` on the plain curve, and its top speed is 1.25 times the usual one. The jump is
  unchanged.
- **Envelope:** `rushGain` 1.24, the rush's 1.25 rounded down, since a rolling ball does not scale exactly; verified
  on the real ball. Inside a zone, the speed
  model reads `speedAfter` through it, and gaps use that speed.
- **Game:**
  - an `AdrenalineZoneComponent`: a sensor the ball enters and leaves, drawn as a red tint along the ground;
  - while inside, the ball's `isRushing` scales its push;
  - entering plays the heartbeat sound and the new `Haptic.heartbeat`;
  - a viewport overlay draws a red edge glow pulsing at 1.2 Hz, fading in 0.5 s when the rush ends;
  - the ball leaves a short red trail;
  - the boost tray shows a beating heart;
  - a respawn ends the rush.
- **Audio:** the heartbeat is synthesized with ffmpeg in `tool/audio`, two low thumps, and normalized like the other
  effects, so it needs no third-party asset.

### D8. Validator, clearance and falls
- **Validator:**
  - zones lie over the course;
  - inside a zone, gaps and climbs are checked against the rush's speed;
  - every break point resolves to the existing rules.
- **Laser clearance:** a laser inside a zone counts the rush's speed for its reach.
- **Fall detection:** unchanged; its sideways reach per meter of fall stays generous for the faster rush.

### D9. Bot and stress
- **Bot:**
  - its landing model reads the new gravity and the rush's push;
  - it brakes for break points like any short landing, by the landing caps, and brakes on the ground before a drop
    onto a single tile;
  - it jumps off a ledge over spikes just below;
  - after a jump boost, even one taken in mid-air, it aims beyond the boost's run;
  - bounced just off the ground it is over, it keeps pushing.
- **Stress run:** the same 680 levels, in files of at most 119 tests, must pass.

### D10. Versions and records
- `generatorVersion` becomes 5, with new golden digests.
- An ADR-0015 records:
  - the heavier ball;
  - the rhythm of flow, challenge and break points;
  - the adrenaline rush at level 5;
  - the four dynamic elements at levels 15, 17, 19 and 21, for the next change.

## Risks / Trade-offs

- **[Break points feel unfair]** → Each is built from primitives the validator proves, and each is readable: a short
  tile against a riser, spikes in view, a gap after a crest. The play-test judges them, and their probability is one
  constant.
- **[Heavier gravity changes the feel of every element]** → Heights are compensated and the envelope is re-measured;
  the play-test covers levels 1, 5, 9, 13 and 60.
- **[The rush is too hard to control]** → The gain is one constant, measured, and gaps inside a zone stay within the
  precision interval.
- **[Frame time]** → The overlay is one gradient rectangle, drawn only during a rush; the trail is a few circles.
  The frame time is measured on the reference phone.

## Migration Plan

No data change. Savegames keep their level numbers and get new courses (`generatorVersion` 5).
**Rollback:** revert the pull request.
