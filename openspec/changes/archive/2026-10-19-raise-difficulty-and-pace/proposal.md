# Proposal

## Why

After the physical mechanics and the HUD, the author's play-test found the levels still too easy and repetitive. Only
levels 50 to 60 felt right, so a player goes through about thirty levels with barely any challenge. The courses are
also short and flat: today they stay within a narrow band of heights.

The author decided, on 2026-10-18:

- level 1 starts as hard as the current level 50 and keeps rising;
- courses last about 1.5 minutes at first, growing to about 4;
- every current element appears before level 10, so the logic and memory mechanics can start from level 10;
- climbs and descents get much bigger.

This is the first of three changes. New physics (curved terrain, loops, trampolines, conveyors and ice or mud) and
the logic mechanics follow.

## What Changes

- **Demanding from level 1:** the difficulty curve starts where level 50 is today, at intensity 0.76. Gaps and climbs
  use 82–90 % of the reach on level 1, and the curve keeps rising towards 90–95 % with no ceiling. Breather and
  introduction levels ease off less, so no level falls back to trivial.
- **Longer courses:** about 90 seconds at level 1, growing to about 4 minutes deep, with a checkpoint about every 35
  seconds.
- **Every element before level 10:**

  | Level | Introduces |
  |---|---|
  | 1 | ramps, gaps, drops, steps, spikes, and the staircase, cascade, valley, tower and descent set pieces |
  | 2 | ferries |
  | 3 | speed boosts |
  | 4 | crumbling islands |
  | 5 | island hops |
  | 6 | jump boosts |
  | 7 | gravity boosts |
  | 8 | double-jump orbs |

  Levels from 10 on are reserved for the logic mechanics of a later change.
- **Vertical variety:**
  - the course may wander over about 65 m of height instead of 21 m;
  - two new set pieces: towers (a climb of 8–14 m by four to six tall steps, some with gaps between them) and descents
    (a long way down, of 8–16 m, by drops, ramps and gaps);
  - a fall is detected as soon as no ground is left that the ball could still land on, instead of when it passes the
    level's lowest point. Long jumps and drops that land on real ground stay possible, and a hopeless fall from high
    up does not leave the player waiting.
- **Laser barriers against shortcuts:** with large heights, a player can try long jumps and drops to skip parts of
  the course. That freedom stays, but it costs:
  - curtains of laser hang in the air over descents and below high sections, and disintegrate the ball (sending it
    back like a fall);
  - they switch on and off in turn, so a shortcut needs timing;
  - their lower end always stays above what a normal jump from the course reaches, so the intended route never
    touches them.
- **Generator:** a new version, so existing savegames get new courses (the level number is kept), and new golden
  digests. The bot learns the new set pieces, and the 640-level stress run must pass.
- **ADR-0013** records the new pacing.

## Capabilities

### New Capabilities

### Modified Capabilities
- `level-generation`: the demanding start, the introductions by level, the set pieces, level length, checkpoint
  spacing, the precision of the first levels, and a new requirement for vertical variety.
- `game-session`: a new requirement that falls are detected as soon as no ground can be reached, and never while a
  landing is still possible.
- `level-mechanics`: a new requirement for laser barriers.
- `level-generation`: also a new requirement placing laser barriers in the shortcut space.

## Impact

- **Generator:** `packages/level_generator`, in its difficulty curve, generator, validator, tests and golden digests.
- **Game:** fall detection in `LevelComponent`, and a new laser barrier component with its visuals.
- **Data:** `LevelData` gains laser barriers.
- **Tests:** the playthrough bot (`test/helpers/level_bot.dart`) and the playthrough test levels.
- **Docs:** ADR-0013, `docs/product.md`, `docs/glossary.md` and the README index.
- No new dependencies, no data migration. Savegames keep their level number; the courses change.
