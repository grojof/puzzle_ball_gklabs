# Proposal

## Why

The levels now play well, but they look the same from level 1 to level 1000, and the art does not read as one game:

- the boosts are flat icons, the goal is a cartoon stone portal, and the floor and backdrop are painted;
- there is one floor and one backdrop, so a long climb never feels like a journey.

The author wants a simple system that looks high quality, can produce new floors and whole biomes, and keeps the
painted night-forest backdrop they like. The next change adds new mechanics (moving platforms, hazards, switches,
memory elements and portals), so the visual system must give those a consistent look from the start.

## What Changes

- **Biomes:** levels are grouped in worlds of ten, and each world has a biome from a fixed cycle:
  1. night forest, with the current painted backdrop;
  2. desert dusk;
  3. snowy peaks;
  4. crystal caves;
  5. volcano.

  After the cycle, worlds repeat the biomes with variations drawn from the seed (palette, time of day, backdrop
  layers), so no two consecutive worlds look alike. A new world announces its name when it starts.
- **Generated terrain:** floors and ramps are drawn from the biome's surface material (grass, sand, snow, crystal,
  basalt) on top of a textured body. The textures are generated once per biome and variant when a level loads, and
  replace the single floor image, including under ledges.
- **Layered backdrops:** each biome has a backdrop of depth layers: a sky gradient, silhouette layers (hills, dunes,
  mountains, stalactites, cones) and ambient particles (fireflies, sand, snow, sparkles, embers), all generated in
  code. The night forest keeps the painted layers, with seeded variations.
- **Gameplay elements drawn in code:** boosts, checkpoints and the goal are vector shapes with animation, the same in
  every biome, with a fixed color and icon per type that stand out against every biome:
  - boosts pulse, each with its own color and icon;
  - a checkpoint flag waves, and turns gold with a burst when activated;
  - the goal is an animated portal.

  One boost component replaces the three near-duplicate classes. The element palette leaves room for the next
  change's hazards and logic elements.
- **Cleanup:** the boost, goal and floor images are removed from the assets and the preload; the ball, the icons and
  the painted parallax stay.

## Capabilities

### New Capabilities

- `game-visuals`: how levels look: the biome of each world and its variations, terrain, backdrop, the look and
  animation of gameplay elements, and the world announcement.

### Modified Capabilities

None. Level generation, physics and gameplay rules do not change, and the biome is derived from the seed and level
number outside the generator.

## Impact

- **Code:**
  - new `lib/game/visuals/`: the biome catalogue and selection, palettes, texture generation, the backdrop builder and
    element painters;
  - `FloorComponent` and `RampComponent` draw generated textures;
  - one `BoostComponent` replaces the three classes;
  - `CheckPointComponent` and `GoalComponent` are redrawn;
  - `BallOdysseyGame` rebuilds the backdrop when the world changes;
  - the level label shows the world name.
- **Assets and l10n:** fewer images; biome names in English, Spanish and Catalan.
- **Performance:** textures are generated once per biome and variant and cached; backdrop layers and particles have
  fixed budgets. Frame time is measured on the author's phone against the current build.
- **Tests:**
  - deterministic biome selection;
  - palette contrast checks for element colors against every biome;
  - texture generation;
  - rendering smoke tests for every biome and element;
  - the existing gameplay, envelope and bot tests unchanged.
- **Docs:** product, architecture and glossary (world, biome), and an ADR for the visual system.
