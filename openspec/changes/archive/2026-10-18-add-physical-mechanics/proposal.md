# Proposal

## Why

The levels play and look well, but the early ones (up to around level 30) are mostly running and jumping. The author
wants new mechanics from early on, to make levels more varied and add the extra difficulty they still lack. This is
the first of two changes and covers the physical mechanics; logic and memory mechanics (switches, doors, memory
platforms, portals) follow.

The author also wants:

- the double jump, which existed only as a bug (fixed in #10), back as a deliberate reward for high levels;
- a joystick and jump button that match the game's look;
- jumps that are no longer too easy. The jump is strong (3.7 m high, 13.5 m at a run), and the generator sizes gaps
  with a lot of slack: a level-1 gap uses 20–45 % of the reach, a deep one at most about 85 %. Players skip whole
  sections. Jumps should be "just enough", with precision rising over the levels until the player must take off from
  the very edge at full speed, and boosts should follow the same logic where a jump is not enough.

## What Changes

- **Spikes:** strips of spikes on the ground. Touching them sends the ball back like a fall: to the last checkpoint,
  or the level's start if none is active. They appear from level 1.
- **Moving platforms (ferries):** a platform that shuttles back and forth across a gap too wide to jump. The player
  boards it at one edge, rides and gets off at the other. They appear from level 3.
- **Crumbling platforms:** islands that collapse shortly after the ball stands on them, so the player has to keep
  moving. They appear from level 6.
- **Double-jump orb:** a single-use pickup placed before a section that needs it (a gap or a climb beyond one
  jump). It grants one jump in mid-air, and the jump button shows when it is charged. It appears from world 3
  (level 21).
- **A weaker base jump:** about 2.7 m high instead of 3.7 m, with the movement envelope re-measured with the real
  physics.
- **Precision instead of slack:** each gap and climb uses a fraction of the reach available at its point that grows
  with the level, from about 70 % on the first levels to about 95 % deep. Boosted gaps and climbs (speed, gravity,
  jump boosts and the orb) are sized close to their boosted reach in the same way. The generator's speed estimate is
  calibrated against the real acceleration curve, so "the reach available" is honest.
- Pacing: each mechanic is featured in the levels right after it appears, before mixing with the rest. A respawn
  restores crumbled platforms and orbs from the checkpoint onwards.
- **Generator:**
  - new elements in `LevelData`;
  - envelope numbers for the double jump, measured with the real physics and guarded by the envelope test;
  - validator rules for every new element;
  - stages that introduce elements by level number;
  - a new generator version.
- **Look:** spikes, platforms and the orb follow the visual system: drawn with depth, with the reserved hazard red for
  spikes. The joystick and the jump button are redrawn in the same style.
- **Bot:** the playthrough bot learns to jump spikes, wait for ferries, cross crumbling islands and use the orb,
  and takes off at the very edge, as precision demands.
- **Deferred:** permanent abilities (such as a stronger jump) belong to the progression change, with modes, lives and
  savegames.

## Capabilities

### New Capabilities

- `level-mechanics`: how the new elements behave in play: spikes, moving platforms, crumbling platforms and
  double-jump orbs, including what a respawn restores.

### Modified Capabilities

- `level-generation`: the new elements, when they appear, the reachability rules they must respect, and the
  precision curve that replaces the generous sizing.
- `player-controls`: the air jump from an orb, and the redesigned on-screen controls with the charged indicator.
- `game-visuals`: the look of the new elements.

## Impact

- **`packages/level_generator`:**
  - new element types, section kinds and curve introductions by level;
  - the envelope's double-jump numbers;
  - validator rules;
  - property tests;
  - a new golden and `generatorVersion` 2.
- **Game:**
  - new components: spikes, moving platform, crumbling platform, orb;
  - the ball's air jump;
  - `LevelComponent` respawn restores;
  - the HUD restyle;
  - the envelope and bot tests.
- **Docs:** product, architecture and glossary.
- **Existing savegames** play different courses: progress (the level number) is kept, as in earlier generator changes.
