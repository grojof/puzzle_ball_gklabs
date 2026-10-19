# Design

## Context

See proposal.md for the motivation. Before this change:

- **Terrain:** floor runs were boxes and ramps triangles, all static bodies. `GroundSurface.supports(center)` told the
  ball whether it stood on a surface's top.
- **Ball control:** the ball moves by a horizontal force (80 N) on its body, against a linear damping of 1.5/s, so its
  top speed is about 8.5 m/s whatever the ground. Friction only couples its rolling. The moving platforms had already
  shown that physics alone does not carry a rolling ball well: they hand their velocity changes to the ball, and the
  damping acts relative to the deck.
- **Generator:** exact arithmetic only (`+ − × ÷`, quantized `exp`), a measured movement envelope, an honest speed
  model, precision shares, a validator, a bot and a 560-level stress run.
- **Forge2D 0.15 (Box2D v3)** provides chains (`Body.createChain` / `ChainDef`) for smooth curves, and per-shape
  collision filters.

## Goals / Non-Goals

**Goals:**
- Varied slopes from level 1, and four new physical elements, as fair and measured as the existing ones.

**Non-Goals:**
- Logic and memory mechanics (the next change).
- Freely shaped terrain: curves come in a few kinds with sized parameters.

## Decisions

### D1. Curves as exact polylines
- **Data:** `LevelData.curves`, each a `CurvedRun` with a kind (`hill`, `halfPipe` or `slope`) and its top surface,
  left to right, with points at most 0.5 m apart.
- **Shapes:** polynomials only, never trigonometry, so the points are exact on every platform:
  - `CurvedRun.bumps` builds one or more bumps in a row, each `y = −h · 16 t² (1 − t)²` over its width (a negative `h`
    dips);
  - `CurvedRun.slope` joins two heights along `3 t² − 2 t³`.

  Every shape starts and ends flat, so curves join the floor runs with no kink.
- **No straight ramps:** the author's play-test found straight descents broke the experience. So every ramp the
  generator builds, up or down, in valleys and descents too, is a rounded slope.
- **Game:** a `CurvedTerrainComponent` builds one static chain from the points, with ghost vertices continuing the
  floor runs, so the ball never catches on a seam. It draws the biome's body down to a tile below the curve and bends
  the surface strip along it, as textured vertices. It implements `GroundSurface`: a ball is on it when it touches the
  chain and its center lies above the curve at its x.
- **Contacts:** a chain reports a contact per segment, and rolling along it, the ball touches the next segment before
  it leaves the last. So the ball counts the shapes it touches per surface, rather than keeping a set.
- *Alternative: approximate curves with many small ramps.* Rejected: each joint is a corner the ball bumps on.

### D2. Pushing climbs any curve
The push (80 N) beats the ball's weight (63 N): pushing climbs any slope gentler than about 51°. Curves are kept as
gentle as ramps (35°): a bump is 4.4 times wider than it is high, since its steepest slope is 3.08 times its height
over its width.

- **Hills:** one to three bumps, 0.75 m to 3 m high.
- **Half-pipes:** one dip, 1.5 m to 3 m deep, with both lips at the run's height.
- **Slopes:** 2.2 times wider than they are high (their steepest slope is 1.5 times their height over their width), at
  the heights straight ramps had. A slope down caps the speed as a ramp down did, since a fast ball flies off its top.
- **Speed after a curve:** measured with the real physics, pushing from rest just before the smallest or biggest hill,
  half-pipe or slope up leaves it at 3.87 m/s or more (`curveExitSpeed`, 3.8). The speed model and the validator take
  that speed after any curve but a slope down, which only adds.
- **Crests:** a fast ball takes off from a crest and comes down on the next slope or on the landing run after the hill.

### D3. Trampolines with a fixed bounce
- A trampoline is a sensor pad on the ground, not a bouncy shape. On contact, unless the ball is already flying up
  from it, it sets the ball's vertical speed to 15.5 m/s and keeps its horizontal speed. So every bounce rises to the
  same height, about 5 m.
  - *Alternative: Box2D restitution.* Rejected: the bounce would depend on the fall, and the generator could not size
    what comes after it.
- **Envelope:**
  - `trampolineHeight` (4.8 m) and `trampolineFlightTime` (2 s) fit the bounce's arc;
  - `trampolineDistance` (14 m) is how far a bounce taken at rest carries a ball that pushes in the air.

  The widest gap after a bounce is the speed carried through the air, or the push from rest, whichever is longer.
  Pushing from rest covers ground faster and faster, so its distance is scaled by the square of a shorter air time and
  only in proportion to a longer one, which stays within it either way.
- **Data:** `LevelData.trampolines`, each a position and a width.
- **Section:** `trampolineHops`: a jump onto an island two tiles wide that is the pad, and one to three bounces beyond
  a jump's reach onto the next island or the landing. The ball bounces where it lands, so each bounce's reach counts
  from the island's middle. After the play-test, hops weigh twice as much as before, so they come more often. Trampolines serve only pits: before a high ledge the jump boost
  does the job, and combined with a normal jump it climbs higher, so the two elements keep distinct roles (the
  author's play-test).

### D4. Surfaces act on the control, not through friction
Since the ball moves by a force on its body, friction alone changes little: ice would barely feel like ice.

- **Data:** each `FloorRun` carries a surface (`plain`, `conveyorForward`, `conveyorBackward`, `ice` or `mud`), and its
  `GroundSurface` exposes it to the ball.
- **Effects** while the ball stands on the surface:
  - **conveyor:** like the moving platforms, the damping acts relative to a belt speed of ±2.5 m/s, so a resting ball
    travels with the belt and its top speed shifts by the belt's;
  - **ice:** the push and the damping are both scaled by 0.35, so the top speed stays the same, but the ball speeds up
    and slows down about three times more slowly;
  - **mud:** the damping is multiplied by 2.5, which lowers the top speed to about 3.4 m/s, and the jump impulse is
    scaled by 0.8.
- **Envelope:**
  - `beltSpeed` (2.5 m/s);
  - `iceGrip` (0.33): the speed after `d` meters on ice is at least the speed after `0.33 d` on plain ground;
  - `mudTopSpeed` (3.3 m/s), `mudJumpHeight` (1.75 m) and `mudFlightTime` (1.2 s).

  `speedOn(surface, …)` reads each surface's speed curve:
  - ice stretches it;
  - mud caps it;
  - a backward belt takes its speed off the speed relative to it;
  - a forward belt only adds, so it is read as plain.

  Gaps and climbs from mud use the mud jump.
- **Sections:**
  - `conveyor`: three to five tiles of belt, forwards or backwards, before a gap;
  - `ice`: three to five tiles of ice before a gap;
  - `mud`: two or three tiles of mud before a gap or a climb.

  Belts run at 2.5 m/s, well under the 8.5 m/s a push reaches, so a backward belt can always be pushed against.
- **Seams:** a surfaced stretch is its own floor run, next to a run at the same height. At speed, a ball catches on the
  next box's corner and hops, as Box2D's ghost collisions do, and the same happens where a curve meets a run. So a run
  that touches another at its height, or a curve, has a chain along its top with level ghost ends, and its box stops
  3 cm below it.

### D5. The loop
- **Geometry:** a circle of radius 2 m on the run, with a speed boost 0.75 m before its left side and a tile of run
  after it. Its run ends there, so the boost belongs to the loop alone.
- **Physics:**
  - In 2D the way in and the way out cross at the loop's foot. So the track is two one-sided, frictionless arcs that
    take turns, switched through their collision filters:
    1. nearing the top, the falling half starts colliding;
    2. on the way down the left, the rising half stops, so the ball rolls out along the floor;
    3. the track resets once the ball has left.
  - A ball that falls back down the right, or lies low on the left heading back, finds the falling half off again. So
    it is never trapped inside, and heading back always takes it out of the entry, to try again with the boost.
  - While the ball rides the track, past a small angle from the foot, its push and damping are suspended: a horizontal
    push would brake it in the upper half.
- **Envelope:** `loopEntrySpeed` (12 m/s) is measured just before the foot. The boost taken from rest enters at about
  15 m/s, more than 1.2 times that.
- *Alternative: a loop drawn but traversed on rails.* Rejected: it would not be physics, and the ball would no longer
  react to the player.
- *Alternative: a push along the track inside the loop.* Rejected: since the push beats gravity, a ball would go around
  from any speed, and the loop would ask nothing of the player.

### D6. Introductions and placement
| Level | Introduces |
|---|---|
| 1 | hill, half-pipe (straight ramps lose half their weight) |
| 9 | trampoline hops |
| 11 | conveyor, ice, mud |
| 13 | loop |

The levels in between (10, 12, 14…) are kept for the next change's logic mechanics. `generatorVersion` becomes 4,
and the golden digests are recomputed.

Curves keep their height, so courses would travel less up and down. The share of obstacles that simply head for the
course's target height rises from 15 % to 25 %, and featured kinds from 70 % to 75 % of the rest, so each level keeps
its character.

### D7. Validator, clearance and falls
- **Validator:**
  - curves join their runs at their height, no steeper than a ramp, hills above the ground and half-pipes below it;
  - trampolines lie on a run and stand only before a gap, within their reach;
  - the speed along a run follows its surface, and gaps and climbs after mud use the mud jump;
  - a backward belt never runs faster than half the top speed;
  - loops stand on a run that reaches a tile past them, with their speed boost, and nothing else in their way.
- **Laser clearance:**
  - curves count as ground, with the flight off a crest;
  - a trampoline within the window raises the clearance to `trampolineHeight`, and extends the step from its run;
  - no barrier hangs within 20 m of a loop.
- **Fall detection:** curves count as ground columns at their lowest point. A ball inside a loop is above the loop's
  run, which is ground, so it is never taken for a fall.

### D8. Camera
While the ball rides through a loop, the view blends onto the loop's center and zooms out if needed to fit it with
2 m of room. The usual springs ease it in and out, so it does not follow each turn.

### D9. Bot
- **Curves:** it keeps pushing, reads their height, and steers to land after a crest.
- **Trampolines:** after a bounce, it chooses the ground beyond the pad's run and steers to it, as after a jump.
- **Mud:** it times its jumps with the weaker jump.
- **Loops:** it pushes through the boost, lands before it when coming from above, and lets the loop carry the ball.

The local stress run must pass. It covers:
- 17 levels: 1 to 11, 13, 15, 25, 45, 120 and 300;
- 20 seeds;
- 2 seed sets, for 680 levels.

## Risks / Trade-offs

- **[The loop's collision switching is fiddly]** → It is isolated in `LoopComponent`, covered by `flame_test` tests:
  - going around and out;
  - rolling back when slow;
  - never trapped after falling in;
  - a respawn resets it.
- **[Surfaces feel artificial]** → The coefficients are set by measuring and in the play-test.
- **[Exactness of curves]** → Polynomials only; the golden digests on the VM and in Chrome prove it.
- **[Frame time]** → Each curve is one chain and one cached path; surfaces add marks drawn only when on screen. The
  frame time is measured on the reference phone.

## Migration Plan

No data change. Savegames keep their level numbers, and their courses change with `generatorVersion` 4.
**Rollback:** revert the pull request.
