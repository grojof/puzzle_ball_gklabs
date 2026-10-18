# game-visuals Specification

## Purpose
Defines how Ball Odyssey's levels look: the biome of each world and its variations, the terrain and backdrop it
produces, and how gameplay elements look and animate, so the climb feels like a journey and every element stays
readable.

## Requirements

### Requirement: A biome per world
Levels SHALL be grouped in worlds of ten consecutive levels. Every level of a world SHALL share one biome, taken from a
fixed cycle in this order: night forest, desert dusk, snowy peaks, crystal caves, volcano. The cycle SHALL then
repeat. For a given seed and level number, the biome and its variation SHALL be the same on every device and platform.

#### Scenario: Worlds and the cycle
- **WHEN** levels 1, 10, 11 and 51 are played
- **THEN** levels 1 and 10 are in the night forest, level 11 is in the desert dusk, and level 51 is in the night forest
  again

#### Scenario: Same seed, same look
- **WHEN** the same seed and level are played on Android and in a browser
- **THEN** both show the same biome and variation

### Requirement: Variations keep repeats fresh
When a biome comes back in a later cycle, its world SHALL vary from the earlier one in palette, time of day or
backdrop layers, drawn from the seed and the world number.

#### Scenario: Second night forest
- **WHEN** worlds 1 and 6 of a seed are compared
- **THEN** both are night forests, with different variations

### Requirement: World announcement
When a level is the first of its world, the level label SHALL also show the world number and biome name, in the
player's language.

#### Scenario: Entering a new world
- **WHEN** level 11 starts
- **THEN** the label shows the level number together with "World 2" and the desert dusk name

### Requirement: Terrain drawn from the biome
Floors and ramps SHALL show the biome's surface material on top and a textured body below, continuous along runs and
ramps and below ledges, without seams between tiles or bare flat-colored areas.

#### Scenario: Snowy ledge
- **WHEN** a step up appears in the snowy peaks
- **THEN** its top shows snow, and the body down to the ground below is textured rock, with no flat-colored patch

### Requirement: Layered backdrop per biome
Each biome SHALL have a backdrop with a sky and several layers that move at different speeds with the ball, plus
ambient particles. The night forest SHALL use the painted backdrop.

#### Scenario: Running through the desert
- **WHEN** the ball runs right in the desert dusk
- **THEN** the far layers move more slowly than the near ones, and drifting sand particles are visible

### Requirement: Readable gameplay elements
Each kind of boost SHALL have its own color and an icon that suggests its effect, the same in every biome. Boosts,
checkpoints and the goal SHALL be drawn with depth (shading, highlights and glow), not as flat color shapes, and
SHALL contrast with the terrain and the backdrop of every biome, so the player recognizes them at a glance.

#### Scenario: Speed boost in the volcano
- **WHEN** a speed boost appears in the volcano
- **THEN** it has the same color and icon as in the night forest, and stands out from the lava glow behind it

### Requirement: Animated feedback
Boosts SHALL pulse gently while available. A checkpoint flag SHALL wave, and turn gold with a short burst when it
activates. The goal SHALL show an animated portal.

#### Scenario: Activating a checkpoint
- **WHEN** the ball touches a checkpoint
- **THEN** its flag turns gold with a short burst of particles

### Requirement: Visuals keep the game smooth
Terrain textures SHALL be prepared when a level loads, not while playing. On the author's reference phone, the frame
time during play SHALL stay within a few milliseconds of the build before this change.

#### Scenario: Deep level in the crystal caves
- **WHEN** a deep level in the crystal caves is played on the reference phone
- **THEN** the frame time stays close to the earlier build's, with no stutter when the level starts
