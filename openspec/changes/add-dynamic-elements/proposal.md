# Proposal

## Why

`flow-and-pacing` gave levels a rhythm, a heavier ball and the adrenaline rush. The author's play-tests still ask for
more life and more kinds of elements: deep levels should not feel like the same gaps and climbs again. ADR-0015 set the
next four elements and their levels: fans at 15, bumpers at 17, pendulums at 19 and seesaws at 21. On 2026-10-19 the
author chose how each one plays:

- **Fans:** blow upwards, always on.
- **Pendulums:** maces that physically push the ball.
- **Seesaws:** planks over a pit.

Unlike the static terrain, these elements move or push the ball, so each needs its timing or its force measured with
the heavier ball, like every other element.

## What Changes

- **Fans (level 15):** a fan blows a visible column of air upwards, always on. Inside it, the ball is lifted to a
  hover height and floats there, bobbing, while the player pushes it sideways.
  - **Fan gaps:** fans in a pit wider than any jump let the ball float across it.
  - **Fan climbs:** a fan in the floor at the foot of a wall higher than a jump boost reaches lifts the ball to the
    ledge.
  - **Skill:** a ball that flies in fast can overshoot the column and fall back, and one pushed beyond the column
    before the bank falls into the pit.
- **Bumpers (level 17):** pinball bumpers set in ceilings and walls. Touching one throws the ball away from it at a
  fixed, strong speed. They play as traps, but never send the ball back to a checkpoint by themselves.
  - **Bumper posts:** bumpers on short stands on the runs after a gap, a tile in, one at first and up to three
    deep. Each is jumped; landing long or rolling on runs into it, and it throws the ball back, often into the gap.
  - **Bumper risers:** from level 17, a break point's short tread can end in a riser lined with bumpers. A ball that
    overshoots the tread is kicked back into the gap.
- **Pendulums (level 19):** iron maces swinging on a rigid arm over a run, on a fixed rhythm like the lasers.
  - **Hits:** a mace that meets the ball throws it away hard, back down the run or off into the pit.
  - **Waiting spots:** the run has room outside the mace's reach to wait in.
  - **Crossing:** each mace leaves the lane clear long enough for a ball starting from rest at a waiting spot to cross.
  - **Deep levels:** two or three maces with their own phases hang over one run.
- **Seesaws (level 21):** a plank on a pivot over a pit, resting with its near end at the run's height.
  - **Tipping:** past the pivot, the ball's weight tips the plank forwards, and its far end drops.
  - **The jump:** the player rides it down and jumps from its far end to the far bank, sized from the speed the
    ball has there. A ball that stalls on the plank rolls off its low end into the pit.
- **Respawns and rhythm:**
  - a respawn puts every seesaw back at rest;
  - maces keep their rhythm, as lasers do;
  - fans and bumpers have no state.
- **Feedback:**
  - each element has its look, in the depth style of ADR-0010;
  - three synthesized effects: a bumper's ding, a mace's thud and an updraft's whoosh;
  - a sharp vibration when a bumper or a mace hits the ball.
- **Generator:** new data, sections and measured envelope values, with the validator, the laser clearance and the
  fall detection extended. The bot learns each element, and the stress run adds levels 17, 19 and 21.
- **Curves with obstacles** (after the first play-test): hills and half-pipes often carry spikes in a valley
  between two bumps, or a speed boost after them that launches the ball over a long gap, more often deep, so wavy
  stretches are not empty.
- `generatorVersion` 6 with new golden digests.

## Capabilities

### New Capabilities

### Modified Capabilities
- `level-generation`:
  - stages: fans at 15, bumpers at 17, pendulums at 19, seesaws at 21;
  - deep levels use the new elements too;
  - new requirements for fans, bumper posts, pendulums, seesaws, and obstacles on curves.
- `level-mechanics`:
  - fans, bumpers, pendulums and seesaws in play;
  - respawns reset the seesaws.
- `game-visuals`: readable dynamic elements.
- `game-audio`: the bumper, mace and updraft effects.
- `player-controls`: the vibration for a bumper or mace hit.

## Impact

- **Generator:** `packages/level_generator`:
  - data: `Fan`, `Bumper`, `Pendulum`, `Seesaw`;
  - section kinds: `fanGap`, `fanClimb`, `bumperPosts`, `pendulums`, `seesaw`;
  - difficulty curve, envelope, validator, laser clearance and tests.
- **Game:**
  - four components: a fan's sensor that lifts, static bumpers, kinematic pendulums, and a dynamic seesaw on a
    revolute joint;
  - the ball's bump response;
  - fall detection over fan pits;
  - respawn reset;
  - effects and haptics.
- **Tests:**
  - envelope measurements;
  - mechanics tests;
  - the bot;
  - the playthrough test;
  - a stress run of 800 levels.
- **Audio:** three effects synthesized with the project's audio tool, so no third-party asset.
- **Docs:** `docs/product.md`, `docs/glossary.md`, `docs/architecture.md`, and a new ADR-0016 that records how each
  element plays.
- No new dependencies. Forge2D 0.15 already provides kinematic bodies and revolute joints with limits.
