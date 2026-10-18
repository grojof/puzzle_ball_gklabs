# Design

## Context

See proposal.md for the motivation. Today, in `packages/level_generator`:

- **Intensity:** `DifficultyCurve` starts at 0.45 and rises as `0.45 + 0.55·(1 − e^(−(n−1)/60))`. At level 50 it is
  0.757, which gives a precision interval of 0.82–0.89.
- **Easing:** breathers (position 3 of each stage of five) use 0.65 of the intensity, and introduction levels 0.85.
- **Length:** the target is `35 + 115·(1 − e^(−(n−1)/60)) + 25·(1 − e^(−(n−1)/600))` seconds, and checkpoints are
  spaced 40 s apart, down to 35 s by level 100.
- **Vertical band:** climbs are removed below `start − 15` m and descents above `start + 6` m.
- **Honest speed:** the generator's speed model (landings, ramps, cascades, boosts, checkpoints) and the precision
  shares stay as they are.

In the game, `LevelComponent` detects a fall when the ball passes `lowestPoint + 10` m, the level's lowest ground.

## Goals / Non-Goals

**Goals:**
- Level 1 plays like today's level 50, without trivial breathers.
- Courses of 1.5 to 4 minutes, with large climbs and descents.
- Every current element introduced by level 8.

**Non-Goals:**
- New physics or logic mechanics (later changes).
- Changing the movement envelope or the precision constants.

## Decisions

### D1. Intensity
`intensity(n) = 0.76 + 0.24·(1 − e^(−(n−1)/100))`, quantized as today.

| Level | Intensity | Precision |
|---|---|---|
| 1 | 0.76 | 0.82–0.89 |
| 50 | 0.85 | 0.85–0.92 |
| 300 | 0.99 | 0.90–0.95 |

- The breather factor goes from 0.65 to 0.88, and the introduction factor from 0.85 to 0.92. Level 4, a breather,
  lands at about 0.67, like today's level 15: easier, never trivial.
- *Alternative: keep the old curve and add 49 to the level number.* Rejected: deep levels would saturate sooner, with
  the same shape. A new start and a slower scale keep room to grow.

### D2. Length and checkpoints
- The target duration becomes `90 + 150·(1 − e^(−(n−1)/80))` seconds: 90 s at level 1, about 160 s at level 50, and
  about 4 minutes deep.
- Checkpoints are spaced 35 s apart from level 1, so level 1 has two.

### D3. Introductions
`introductionLevel`:

| Level | Introduces |
|---|---|
| 1 | basics, spikes, staircase, cascade, valley, tower, descent |
| 2 | ferry |
| 3 | speed boost |
| 4 | crumbling hops |
| 5 | chained gaps (island hops) |
| 6 | jump boost |
| 7 | gravity boost |
| 8 | orb gap, orb climb |

- The guarantee stays: from level 2, the introduction level features the element and uses it.
- Weights double for five levels, so levels 2–12 each feature their newcomers.
- Level 9 is a breather that introduces nothing, and level 10 has everything.

### D4. Vertical band
- Climbs (rampUp, stepUp, jumpBoost, staircase, orbClimb, tower) are removed when the cursor is above `start − 40` m.
- Descents (rampDown, drop, cascade, descent) are removed when the cursor is below `start + 25` m.
- That is a 65 m band, so a long level can travel far up and down, while the band still turns it back before it
  becomes a tower or a pit.

### D5. Tower
- Four to six steps. Each step's height is `max(0.6, maxClimb(1)·share)`, with treads of one tile.
- Before each step after the first, with probability `0.2 + 0.3·intensity`, the tread is replaced by a gap that rises
  to the step's height: `_gap(rise)`, sized from the precision share against the rising reach.
- With step heights of about 2.2–2.4 m, a tower climbs about 9–14 m.
- The speed model already halves the speed at each step and sizes rising gaps from the speed available.

### D6. Descent
- Parts are drawn until the course has dropped `8 + 8·share` m, with at least three and at most five parts:
  - a drop of 1.5–3.5 m;
  - a ramp down;
  - or a falling gap (rise −1 to −2.5 m), with a one- or two-tile tread between parts.
- Each part uses its own honest landing cap, as single drops, ramps and gaps do.
- *Alternative: one cascade of many drops.* Rejected: mixing drops, ramps and gaps reads as a journey down, not a
  staircase.

### D7. Fall detection by reachable ground
A falling ball has bounded motion:

- its vertical speed tends to `g / damping` = 10 / 1.5 ≈ 6.7 m/s (much slower under a gravity boost);
- its horizontal speed is at most the top speed of 8.5 m/s, plus what a speed boost adds and decays (about 11 m).

So while it falls by Δh it can travel at most about `1.3·Δh + 20` m sideways, with margin, and the low gravity of a
gravity boost is covered.

- `LevelComponent` computes once, at load, the highest ground (top) of each 2 m column, from floors, ramps and moving
  platforms' paths.
- Each frame it checks whether any column lies below the ball by Δh > 0, within `1.3·Δh + 20` m of it horizontally.
  A level has a few hundred columns, a cheap loop. If none does, the ball can no longer land anywhere, and it is sent
  back.
- A long jump or drop that can reach real ground is never cut short, as the author asked. A pit far above the rest of
  the level is detected about a second in, instead of after the ball reaches the level's lowest point.
- *Alternative: the lowest ground within a fixed window around the ball.* Rejected after the author's review: it
  would cut legitimate long drops onto distant ground.

### D9. Laser barriers
- **Data:** `LevelData.lasers`, each with an x, a top and a bottom (world y), and a rhythm: `on` 1.4 s, `off` 1.0 s
  and a phase. Consecutive barriers are offset by half a cycle, so they alternate.
- **Placement:**
  - over the lower half of each descent: one or two barriers;
  - after each tower's top, where the route turns back down: one barrier;
  - each beam hangs from 10 m above its bottom end.
- **Clearance:** the bottom end sits above the route by more than any jump of the route can reach. Let `high` be the
  highest ground (smallest y) within 18 m either side; the bottom is at `high − (clearance + 1.0)` m.
  - The window is wider than any gap, so a jump from higher ground across a long falling gap counts.
  - The margin covers the ball's diameter and the envelope's rounding down.
  - The stress run found both: the first values, 10 m and 0.5 m, let a route jump graze a barrier.
  - `clearance` is the plain jump's height (2.65 m).
  - Where a jump boost or an orb serves within those 18 m, it is the boosted height (6.4 m) or the double jump's
    (5.3 m).
- **Validator:** checks the clearance against the same window, and that no barrier crosses a floor, ramp or platform
  path.
- **Component:** a thin sensor (0.12 m wide) between two small emitters.
  - When on, a red core beam with a glow; when off, a faint dashed line.
  - In the last 0.3 s before switching on, it flickers.
  - Touching it while on calls `LevelComponent.sendBack()`, like spikes.
  - The rhythm runs on the level's clock, so a respawn does not reset it.
- **Introduction:** barriers come with towers and descents from level 1, since shortcuts exist from there.
- **Bot:** it follows the route, under the barriers, so it needs nothing new. The stress run proves the clearance.

### D10. Refinements found by the stress run
- **Crumbling islands:** only time the ball spends on top counts towards the 0.6 s. Grazing the corner on landing
  and bouncing off no longer uses up the delay, which is what "when the ball stands on it" means.
- **Towers:** a rising gap always takes off from a tread of its own. A step up followed at once by a gap left a
  zero-length floor on the riser, and the validator now rejects floor runs shorter than a tile.
- **Fall detection:** each column keeps its lowest ground, the last place a falling ball could land. Keeping the
  highest hid a low tread between two higher floors.

### D8. Version, tests and stress
- `generatorVersion` becomes 3, and the golden digests are recomputed on the VM and in Chrome.
- The playthrough test runs levels 1–8 (one per introduction), 45, 120 and 300.
- The local stress run covers levels 1–8, 10, 15, 25, 45, 120 and 300, with 20 seeds on each of two seed sets (`bot`
  and `fresh`): 15 levels per seed, 600 levels in all. It must pass before merging.

## Risks / Trade-offs

- **[Level 1 is too hard for new players]** → The author's decision. Breathers still ease, and the precision ceiling
  stays at 0.95. The play-test on the phone checks levels 1–10.
- **[Longer levels make the bot tests slower]** → The playthrough list stays short, and the stress run is local only.
- **[Large heights and the camera]** → The camera follows the ground and zooms out on high jumps; the backdrop is
  drawn in screen space, so height does not matter to it. The play-test checks towers and descents.
- **[Fall detection near tall walls]** → A ball sliding down a riser still has the ground at its foot below it, which
  it can reach, so it is not taken for a fall.
- **[Barriers that feel unfair]** → They never touch the intended route (validator and stress run). The warning
  flicker and the alternating rhythm make a shortcut a readable gamble. The play-test tunes the rhythm.

## Migration Plan

No data change. Savegames keep their level numbers, and their courses change with `generatorVersion` 3.
**Rollback:** revert the pull request.
