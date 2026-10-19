# Proposal

## Why

After `raise-difficulty-and-pace`, the author finds the climbs and the terrain monotonous across levels 1 to 60: every
slope is a straight ramp, and every climb is a step or a ramp. This is the second of three changes, and it adds new
physics. The logic and memory mechanics follow, from level 10.

The author decided, on 2026-10-19:

- curved terrain from level 1;
- trampolines at level 9;
- conveyor belts and ice and mud surfaces at level 11;
- the loop at level 13.

These are interleaved with the logic mechanics, which the next change places at levels 10, 12, 14 and so on.

## What Changes

- **Curved terrain (level 1):**
  - hills, one to three bumps in a row, which slow the ball on the way up and give it back on the way down; a fast
    ball takes off from a crest;
  - half-pipes, a U-shaped dip the ball rolls through and climbs out of.
  - They replace part of the straight ramps, so slopes vary in shape.
- **Trampolines (level 9):** a pad that throws the ball up to a fixed height on every touch, whatever its fall. It
  serves islands across a pit, each a bounce from the next.
- **Surfaces (level 11):** floor runs can be:
  - a conveyor belt that carries the ball forwards or backwards;
  - ice, slow to speed up and slow to stop;
  - mud, slow, and it weakens the jump.
- **The loop (level 13):** a vertical loop the ball goes around, entered after a speed boost that guarantees the
  speed it needs.
- **Honest reach:**
  - each element enters the movement envelope, measured with the real physics: trampoline height, speeds and jumps
    on each surface, the loop's entry speed;
  - the generator's speed model accounts for each one;
  - the validator checks each one.
- **The rest of the game follows:**
  - the bot learns every element;
  - fall detection and the laser barriers' clearance cover curves, bounces and loops;
  - the camera keeps the loop in view;
  - each element is drawn in the visual system of ADR-0010.
- `generatorVersion` 4 with new golden digests. The 560-level stress run must pass.

## Capabilities

### New Capabilities

### Modified Capabilities
- `level-generation`: introductions by level, set pieces (hills, half-pipes, the loop), and new requirements for
  curved terrain, trampolines, surfaces and loops.
- `level-mechanics`: how trampolines, conveyor belts, ice, mud and loops act on the ball.
- `game-visuals`: readable new elements.
- `game-camera`: the loop stays in view.

## Impact

- **Generator:** `packages/level_generator`, in its data, envelope, generator, validator, laser clearance and tests.
- **Game:**
  - new components for curved terrain, trampolines and loops;
  - surfaces read by `BallComponent` through `GroundSurface`;
  - fall detection and the camera.
- **Tests:**
  - envelope measurements in `movement_envelope_test.dart`;
  - mechanics tests;
  - the bot (`test/helpers/level_bot.dart`);
  - the local stress run.
- **Docs:** `docs/product.md`, `docs/glossary.md` and `docs/architecture.md`.
- No new dependencies: Forge2D 0.15 provides chain shapes, restitution, tangent speed and friction.
