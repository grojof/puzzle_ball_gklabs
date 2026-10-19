# Proposal

## Why

After `add-curved-terrain-and-physics`, the author's play-tests on 2026-10-19 found:

- **Early levels:** better, but they still need a bit more difficulty, not more length, while they teach the rhythm.
- **Deep levels:** empty. Courses are long, with few boosts and elements.
- **Climbs:** repeated plain steps, simple slopes and easy wall climbs bore.
- **Weight:** the ball flies off slopes too easily.
- **Flow:** the author wants it as the heart of the game. Build speed and chain the route, stopping only where
  something must be done, with gaps that stay protagonists. Add a "break point" that catches a player who relaxes,
  and keep the traps that punish rushing.
- **Tension:** an "adrenaline rush", as the author named it, where the ball goes faster and responds more strongly.

This is the first of two changes. `add-dynamic-elements` follows, with fans, bumpers, pendulums and seesaws at levels
15, 17, 19 and 21, measured with the heavier ball.

## What Changes

- **A heavier ball:**
  - gravity rises by 20 %;
  - the jump, the jump boost and the trampoline keep their heights, with stronger impulses;
  - so the ball falls faster and leaves slopes and crests less, while jumps still reach about 2.7 m.

  The whole movement envelope is re-measured.
- **Flow and break points:**
  - **flow phrases:** levels alternate flow phrases and challenge phrases. A flow phrase is a run of sections taken
    without stopping (hills, half-pipes, slopes down, gaps onto long landings, drops, speed boosts, loops, trampolines,
    forward belts), each sized for the speed a player carries.
  - **break points:** as levels deepen, more flow phrases end in one, where carrying that speed fails. Examples are a
    short tread before a wall, spikes just past a landing, or a gap right after a crest. A player who stays alert
    brakes in time; the generator keeps every break point within what braking allows.
- **Denser deep levels:**
  - shorter rest stretches;
  - more obstacles per phrase;
  - boosts, orbs, trampolines, loops and surfaces weigh more as the level rises, plain gaps and climbs less.
- **Varied climbs:**
  - plain steps, staircases and towers weigh less as the level rises;
  - two plain climbs never follow each other;
  - deep towers mix in orb and jump-boost climbs.
- **Early levels:** a little more demanding from level 1 (higher starting intensity and obstacle share, gentler
  easing on introductions), without being longer.
- **The adrenaline rush (level 5):**
  - the generator marks tense phrases (spikes, crumbling islands, island hops, laser descents);
  - inside one, the ball's push is 25 % stronger: it speeds up faster and reaches a higher top speed, so precise
    landings need more skill;
  - gaps there are sized from that speed;
  - entering it tints the screen red with a pulse, plays a heartbeat sound and vibration, and shows a heart in the
    boost column; leaving it ends the effect.
- `generatorVersion` 5 with new golden digests. The local stress run must pass.

## Capabilities

### New Capabilities

### Modified Capabilities
- `level-generation`:
  - a slightly more demanding start;
  - stages: adrenaline at level 5;
  - flow phrases and break points;
  - density and climb variety that rise with the level;
  - adrenaline zones.
- `level-mechanics`: the adrenaline rush.
- `player-controls`: the ball's weight, with jumps of the same height.
- `game-visuals`: the adrenaline rush's look.
- `game-audio`: the heartbeat.
- `game-hud`: the heart in the boost column.

## Impact

- **Generator:** `packages/level_generator`, in its difficulty curve, phrases, new `AdrenalineZone` data, envelope,
  validator, laser clearance and tests.
- **Game:**
  - world gravity and impulses;
  - an `AdrenalineZoneComponent`;
  - the ball's push inside a zone;
  - a viewport overlay;
  - a haptic pattern;
  - the boost tray.
- **Tests:**
  - envelope re-measured;
  - mechanics tests;
  - the bot;
  - the local stress run.
- **Audio:** a heartbeat effect, synthesized with the project's audio tool, so no third-party asset.
- **Docs:** `docs/product.md`, `docs/glossary.md`, `docs/architecture.md`, and a new ADR-0015 that records the decisions.
- No new dependencies.
