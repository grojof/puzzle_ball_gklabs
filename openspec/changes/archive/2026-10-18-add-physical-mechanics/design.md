# Design

## Context

See proposal.md (Why). The current state that shapes the approach:

- **Ball and boosts:** jump impulse 80 (3.72 m standing jump, 1.71 s air time), move force 80, damping 1.5, top speed
  7.94 m/s. Boost impulses: 120 up for jump, 100 forward for speed, gravity scale 0.1 for 2 s. A new boost replaces
  the running one (#10).
- **Envelope:** `ballEnvelope` holds 3.6 m, 1.65 s, 7.8 m/s, 2.4 s to top speed, jump-boost height 6.4 m,
  speed-boost jump 23 m and gravity-boost jump 29 m. `movement_envelope_test.dart` proves the physics reaches them.
- **Speed model:** `speedAfter(d, startSpeed)` is uniform acceleration capped at top speed. It underestimates the
  real start, which is quick and then saturates, so gaps sized from it are easier than intended.
- **Sizing:** gaps use `allowed × U(0.25 + 0.2i, 0.45 + 0.55i)`, where `allowed = maxGap(speed, rise, margin)`,
  `margin = 0.45 + 0.4i`, and intensity `i` goes from 0.45 at level 1 towards 1. That is 21–44 % of the reach at
  level 1 and at most about 85 % deep. Climbs and boosted gaps are similarly generous.
- **Curve:** elements appear by stage of five (`introductionStage`). The introducing stage doubles the weight.
- **Ground:** detected each frame from geometry (`GroundSurface.supports`). Floors and ramps are static bodies.
- **Respawn:** `LevelComponent.update` sends the ball to the active checkpoint, or calls `onFell`, below the fall
  line.
- **The bot:** jumps with a lead of `max(0.25, 0.08·v)` m before an edge, steers in the air, and passes a 280-level
  stress run.

## Goals / Non-Goals

**Goals:**

- Jumps that are "just enough": precision rising with the level, on an honest reach.
- Four new mechanics, each generated with a purpose, validated, playable by the bot and readable.
- No loss of determinism: the generator stays exact arithmetic on integers and doubles, with no transcendental
  functions.

**Non-Goals:**

- Logic and memory mechanics (the next change). Permanent abilities (the progression change).
- Vertical lifts or platforms with paths other than a straight shuttle.

## Decisions

### D1. A weaker jump, re-measured

The jump impulse drops from 80 to about 68, a standing jump of about 2.7 m. The exact value is chosen by measuring
heights in `flame_test` and is tuned in the play-test. Every envelope number is measured again with the real physics,
rounded down, and written to `ballEnvelope`:

- jump height and air time;
- top speed and its acceleration;
- jump-boost height;
- speed-boost and gravity-boost jump distances.

Two numbers are new:

- **double-jump height:** jump, then jump again at the apex;
- **double-jump distance:** a running jump at top speed with a second jump at the apex.

The envelope test asserts the physics reaches all of them.

### D2. A measured speed curve instead of uniform acceleration

`MovementEnvelope` gets a `speedCurve`: the speed after pushing from rest, measured every 0.75 m up to 30 m with the
real ball and rounded down to 0.01 m/s.

- **From rest:** `speedAfter(d, startSpeed)` interpolates linearly on that table.
- **From a start speed:** first find the distance `d₀` at which the curve reaches the start speed (inverse
  interpolation), then read the curve at `d₀ + d`.

Interpolation uses only additions, multiplications and divisions, which are exact and the same on every platform. The
measured table is checked by the envelope test: the real ball is at least that fast at each distance.

- *Alternative: a fitted exponential.* Rejected: `exp` is not guaranteed bit-identical across platforms (design D2 of
  the generator change).

Tight gaps need the estimated speed to be honest, not only the curve. The stress run showed where the old estimate ran
ahead of the ball:

- **Ramps down:** a ball faster than the slope flies off the top as off a ledge. The landing after the ramp caps the
  speed as a drop's landing does.
- **Capped landings:** a player who brakes in the air to stay on a landing comes down at its far end, with only the
  last tile left to speed up. Braking against the ball's damping also leaves it at about half the capped average
  speed, as measured with the bot.
- **Cascades:** a player may fly from any ledge to the final landing, if the flight clears the treads in between. The
  fastest such flight caps the speed, instead of assuming the whole cascade is flown in one fall.
- **Speed boosts:** the boost adds `speedBoostGain` (15.9 m/s measured, 15.5 kept) to the speed it finds. The reach
  of a speed-boost gap scales the measured jump by `(v + gain) / (top + gain)`, where `v` is the speed at the boost.
  The envelope test checks a boost picked up from rest.

### D3. Precision as an interval that grows with intensity

`LevelParameters.precision` is an interval `[low, high]` of the reach to use:

- `low = 0.55 + 0.35·i`: 0.71 at level 1, about 0.9 deep;
- `high = 0.72 + 0.23·i`: 0.82 at level 1, about 0.95 deep.

Widths and heights are drawn from `reach × U(low, high)`, where the reach is the full envelope (margin 1) at the speed
available (D2). The validator checks every gap and climb against `reach × high`, so `margin` becomes the upper bound
of precision. Breathers scale the interval down as they scale intensity.

Boosted sections draw from the same interval against their boosted reach, and must also exceed the unboosted reach
by at least 5 %, so a boost is always needed where it is placed.

Island hops, staircases and cascades use the same interval for each part.

### D4. New data and section kinds

`LevelData` gains:

- `hazards`: spike strips, each with left, top and width, lying on a floor run;
- `platforms`: moving platforms, each with a path start and end (top-left positions), a size, a speed and a pause at
  each end;
- `FloorRun.crumbling`, a flag for islands that collapse.

Orbs are boosts of type `BoostType.doubleJump`: they are sensors on the approach that serve the section after them,
like the other boosts.

New section kinds:

- **`spikes`:** a run-up, a strip whose width comes from the precision interval of the jump reach at the speed
  available, then a landing.
- **`ferry`:**
  - a gap wider than a running jump (1.2 to 2.5 times the reach);
  - a platform 2 tiles wide moving at 2.2 m/s between 0.15 m from the near edge and 0.15 m from the far edge;
  - a pause of 0.8 s at each end.
- **`crumblingHops`:** island hops whose islands are crumbling runs of 1 to 2 tiles.
- **`orbGap`** and **`orbClimb`:** an orb on the approach, then a gap or climb beyond one jump and within the double
  jump's reach, sized by D3.

### D5. Introductions by level

`DifficultyCurve.introductionLevel` replaces `introductionStage`:

| Level | Elements |
|---|---|
| 1 | basics, spikes, set pieces |
| 3 | ferry |
| 6 | speed boost, crumbling hops |
| 11 | jump boost, island hops |
| 16 | gravity boost |
| 21 | orb gap, orb climb |

Weights double for the five levels from an element's introduction. From level 2 on, the introduction level always
features the elements it introduces and uses each at the first obstacle that allows it, so the player meets them
there (the play-test found level 21 without an orb). `generatorVersion` becomes 2, and the golden digests are
recomputed.

### D6. Validator rules

- **Spikes:**
  - they lie on a run, at least one tile from its ends;
  - their width is within the jump reach at the speed available times `high`;
  - they are not under a boost or checkpoint, and not on the start or goal runs.
- **Ferries:**
  - the end positions lie within 0.3 m of their edges, at the same height;
  - nothing else overlaps the path;
  - the speed is between 1.5 and 3 m/s.
- **Crumbling islands:** they are validated like islands, and each is at least one tile long.
- **Orbs:** the next section exceeds one jump's reach and stays within the double jump's reach times `high`.

### D7. Game components

- **Spikes:** a `SpikeComponent` is a static sensor along the strip. On contact with the ball,
  `LevelComponent.sendBack()` runs the same respawn-or-restart logic as a fall.
- **Moving platforms:**
  - a `MovingPlatformComponent` is a kinematic body. Each frame it sets the velocity towards the current end, or
    zero while pausing;
  - friction alone does not carry a ball: an instant start spins it, and the linear damping, which acts against
    world velocity, slows it until the deck slides out from under it. So when the platform starts or stops, it
    changes the velocity of the ball on its deck by as much as its own, and while the ball stands on the deck its
    damping acts relative to the deck. The ball then rests and rolls on the deck as on the ground. Rolling
    resistance was tried and rejected: enough to carry the ball, it also stopped it rolling under a push;
  - it implements `GroundSurface` against its moving top;
  - the bot and the player board when it is near.
- **Crumbling platforms:**
  - a `CrumblingPlatformComponent` is a static floor that implements `GroundSurface`;
  - when the ball stands on it, a 0.6 s timer starts while it shakes; then its body is disabled and it fades;
  - `restore()` brings it back.
- **The orb:** `BoostComponent` with `BoostType.doubleJump` calls `ball.chargeAirJump()` and hides. `restore()` shows
  it again.
- **The ball:** it holds `airJumps` (0 or 1). A jump request out of the coyote window spends the charge: the vertical
  speed is set to zero, then the jump impulse applies, so the air jump's height does not depend on the timing. A
  respawn or a new level clears the charge.
- **Respawn:** after a respawn, `LevelComponent` restores the crumbling platforms and orbs, all of them, which covers
  those after the checkpoint.

### D8. Restyled controls

- **Joystick:** a dark glass disc with a rim light and an inner shadow, and a glossy knob drawn with
  `ElementPainter.orb` in a neutral steel color.
- **Jump button:** a glossy steel orb with the arrow, lighter when pressed, matching the joystick's knob. While an
  orb charge is held, it takes the double-jump orb's sky blue, with a second stacked arrow and a ring in that color.
  The orb's hue sits between the jump and gravity boosts', at least 60° from every boost, so the neutral steel
  makes the charge stand out.
- **Static parts:** they are recorded once and replayed, as for the boosts.

### D9. The bot learns the mechanics

- **Spikes:** the start of a strip counts as an edge that needs a jump, and the landing target is the run beyond
  the strip.
- **Ferries:** at a ferry edge, the bot waits until the platform is within reach, rolls on, stops pushing while
  riding, and gets off when the platform is near the far edge.
- **Crumbling islands:** they are handled like islands, and the bot never stops on them.
- **Orb:** in the air with a charge, when the predicted landing falls short of the target, the bot jumps again near
  the apex.
- **Precision:**
  - Before a gap, the jump lead shrinks to `max(0.15, 0.04·v)`, so the bot takes off close to the edge.
  - Before a step up, the bot jumps early enough to clear the riser at its speed, by simulating the rise with
    damping. A step too tall for a plain jump is left to its jump boost.
  - In the air, the bot holds the steady push, found by bisection, that lands at the far end of the landing area,
    as a player holding a tilt does. It never brakes while still below a ledge it is climbing to.
  - Launched off a ledge, it aims past treads that end in another drop.
  - A gravity boost's low gravity counts from the pick-up.
  - The bot lives in `test/helpers/level_bot.dart`, shared by the playthrough test and local stress runs.

The 280-level stress run is repeated with the new mechanics.

## Risks / Trade-offs

- **[Tight gaps break the bot or players]** → `high` stays at 0.95 at most. The envelope and the speed curve are
  rounded down. The stress run must pass before merging, and the play-test tunes the interval.
- **[Kinematic platforms and the ball's ground detection]** → The platform implements `GroundSurface` with its current
  top. Tests cover riding, boarding and getting off.
- **[Courses change for existing savegames]** → Accepted, as before. The level number is kept.

## Migration Plan

No data change. `generatorVersion` 2 records the new courses. **Rollback:** revert the pull request.

## Open Questions

- The exact jump impulse and the precision bounds are set by measuring and in the play-test, within the ranges
  above.
