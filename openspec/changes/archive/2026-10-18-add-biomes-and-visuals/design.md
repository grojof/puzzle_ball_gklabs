# Design

## Context

See proposal.md (Why). The current state that shapes the approach:

- **Floors:** `FloorComponent` draws `floor.png` (a 1024 px tile: grass over earth) one tile per column, culled to the
  view, with the tile's earth part below ledges. `RampComponent` draws its own sprite.
- **Boosts and goal:** three near-identical boost classes (`JumpBoostComponent`, `SpeedBoostComponent`,
  `GravityBoostComponent`) add a `SpriteComponent` with a flat icon. The goal draws a stone portal image.
- **Checkpoints:** drawn in code, as a post and a rectangle flag, green and then gold.
- **Backdrop:** a `ParallaxComponent` in `camera.backdrop` with three painted layers. Its base velocity follows the
  ball's horizontal speed.
- **Level label:** `_showLevelIndicator` fades a `TextComponent` in and out with `levelLabel(n)`.
- **Determinism:** `level_generator` already has an exact 32-bit PRNG (`Mulberry32`) and `fnv1a32`, but its barrel
  exports neither.
- **Performance:** the camera change measured 4.9–5.1 ms average and 8.2 ms p99 per frame on the author's phone
  (profile build).

## Goals / Non-Goals

**Goals:**

- One visual language: vector gameplay elements and generated, textured terrain and backdrops, coherent per biome.
- Cheap per frame: textures prepared at load time and drawn with shaders, not per tile; fixed budgets for layers and
  particles.
- Biome art defined as data (palettes and parameters), so adding a biome means adding an entry and its silhouette
  and texture recipe, not new image files.

**Non-Goals:**

- New mechanics or hazards (next change). This change only reserves their colors and shapes.
- Biome effects on physics, such as ice friction.
- Restyling the menus.

## Decisions

### D1. Biome selection outside the generator

`lib/game/visuals/world_look.dart`:

- `world = (level - 1) ~/ 10`;
- `biome = cycle[world % 5]`;
- `variant` = a `Mulberry32` stream seeded with `fnv1a32('$seed/world/$world')`.

The variant picks a hue shift of up to ±12°, a lightness shift of up to ±6 %, a time of day (dusk, night or dawn,
where the biome allows it) and the silhouette and particle seeds. The values come from the integer PRNG and are
quantized, so they are the same on every platform. Worlds 0–4 use variant 0 (the reference look), so the first cycle
always looks as designed.

`level_generator` exports `Mulberry32` and `fnv1a32` from its barrel (already covered by its tests).

- *Alternative: a biome field in `LevelData`.* Rejected: the biome does not change the course, and keeping it out
  keeps the generator's digests and version untouched.

### D2. Palettes as data

`BiomePalette` holds, for each biome:

- the sky gradient (top and bottom);
- the surface colors (main and shade);
- the body colors (main, shade and detail);
- three silhouette depths;
- the accent and particle colors.

Variants derive from the base palette with `HSLColor` (hue and lightness), and the time of day shifts the sky.

| Biome | Material | Silhouettes | Particles |
|---|---|---|---|
| Night forest | grass over earth | painted layers | fireflies |
| Desert dusk | sand over sandstone | dunes and mesas | drifting sand |
| Snowy peaks | snow over granite | mountains and pines | snowflakes |
| Crystal caves | glowing moss over crystal rock | stalactites and columns | sparkles |
| Volcano | ash crust over basalt, glowing cracks | cones and smoke | embers |

### D3. Terrain textures generated once, drawn with image shaders

At level load, `TerrainTextures.generate(look)` draws two textures with a `PictureRecorder` and `toImage`:

- a seamless 256 × 256 px **body** texture: strata, pebbles or crystals from value noise that wraps;
- a 256 × 64 px **surface strip**, seamless horizontally: grass blades, sand ripples, a snow cap with icicles, moss, an
  ash crust.

Both use a seeded `Mulberry32`. They are cached by (biome, variant), keeping the last two looks.

- **Floors:** `FloorComponent` paints the body with an `ImageShader` (repeated, scaled so 256 px = 1.5 m and anchored
  in world coordinates, so neighboring runs line up), then the surface strip along the top. That is two `drawRect`s
  per run, with no per-tile loop.
- **Ramps:** the same body shader is clipped to the ramp's triangle, and the surface strip is drawn along the slope
  with a rotated shader matrix.

### D4. Backdrop built from cached layers and a particle budget

`BiomeBackdrop` replaces the `ParallaxComponent` for the generated biomes:

- **Sky:** a vertical gradient over the whole screen.
- **Silhouettes:** up to three layers, each a `Picture` generated once from noise at 1.5 screen widths, drawn twice
  side by side and offset by `cameraX × factor` (0.1, 0.25 and 0.45).
- **Particles:** up to 48, with positions seeded, drifting with time, wrapped to the screen and drawn as small
  circles or flakes.
- **Calm by default:** after the play-test, where particles were too visible and busy and could tire the eyes,
  a biome shows 20 particles (the forest 12 fireflies), dim (about half brightness at most), drifting and twinkling
  slowly. All particles are drawn from one sprite in a single `drawAtlas` call.

The night forest keeps the painted `ParallaxComponent`. A variant only applies a light color filter (the time of
day) and adds the firefly particles.

### D5. Gameplay elements drawn in code, with their own palette

`ElementPalette` gives the elements fixed colors, the same in every biome. Every element is drawn with depth, never
as a flat color:

- a soft drop shadow;
- an outer glow (a radial gradient);
- a body with a radial gradient, light at the top left and darker at the rim;
- a specular highlight arc;
- a dark outline with a thin light rim inside it;
- a white icon with its own shadow.

The outline and the glow keep the element readable against any background. Terrain gets the same treatment: textures
with shades and highlights, plus a per-run overlay that darkens with depth and a light rim along the top edge.

| Element | Color | Icon or shape |
|---|---|---|
| Jump boost | green `#43D17A` | up chevrons |
| Speed boost | orange `#FF8F1F` | double right chevrons |
| Gravity boost | violet `#A66BFF` | a floating ring with dotted trails |
| Checkpoint, idle | silver `#C7D2DB` | a waving flag |
| Checkpoint, active | gold `#FFC531` | a waving flag |
| Goal | white rings with an animated cyan swirl | an arch portal |

Colors reserved for the next change:

| Next change's element | Color |
|---|---|
| Hazards | red `#FF3B3B` |
| Logic switches and blocks | cyan `#29D3F5` and magenta `#F54BD8` |
| Portals | pairs from that set |
| Memory platforms | translucent white |

- **One boost class:** a single `BoostComponent(type)` replaces the three classes. It keeps their sensors and
  effects (impulses and gravity scale unchanged) and pulses with a scale of 1 ± 0.06 at 1.2 Hz.
- **Checkpoint:** the flag's vertices follow a sine wave. On activation, 10 particles burst outward and fade over
  0.5 s.
- **Goal:** two counter-rotating arcs and a swirl, driven by time.

### D6. World announcement

When `(level - 1) % 10 == 0`, the level label adds a second line, "World N · biome name", with the biome names in the
ARB files in three languages. The game receives the line from `GamePage`, through `levelLabel`, which can now return
two lines, so it stays free of l10n.

### D7. Integration and load order

`_loadLevel` computes the `WorldLook` from the level data's seed and number. When it differs from the current one,
the game awaits the texture generation and swaps the backdrop, before adding the `LevelComponent`, so no texture is
generated during play. The `LevelComponent` receives the look and the textures. The image assets for the boosts, the
goal and the floor are deleted, and the preload list shrinks.

### D8. Tests without pixel snapshots

Pixel snapshots differ between platforms, so instead:

- unit tests for the selection, the variants and the palettes;
- a contrast test: for every element and every color of every biome (sky, silhouettes and terrain), the fill, the
  dark outline or the light rim reaches a ratio of at least 3:1; and boost hues are at least 60° apart;
- `toImage` generation tests for every material (sizes, and tiling: the left and right edge columns match);
- rendering smoke tests that draw a level and a backdrop in every biome.

The look is judged in the play-test, with screenshots of every biome on the phone and in Chrome.

## Risks / Trade-offs

- **[Generated art looks cheap]** → Layered detail (shades, highlights, noise) and an outline-and-glow style for the
  elements, then iteration on the play-test screenshots. Palettes and recipes are data, so tuning is cheap.
- **[`toImage` at load causes a hitch]** → It runs while the level label shows and the level is being built, and is
  cached per world, so most levels pay nothing. The time is measured on the phone.
- **[Texture filtering seams on the web]** → Seamless textures with matching edges, a shader anchored in world
  coordinates, and a check in Chrome.
- **[The painted forest no longer matches the generated biomes]** → The generated biomes use similar depth and
  saturation, and the forest gains generated particles. Judged in the play-test.

## Migration Plan

No data change. **Rollback:** revert the pull request.

## Open Questions

- **Explanatory bubbles:** whether players understand the elements from their look alone is judged in the play-test.
  If they do not, a short bubble shown the first time each element type appears (not on tap, which conflicts with the
  jump button and joystick) is added, in this change or, more likely, in the mechanics change, whose logic and memory
  elements need it most.
- The final biome names in Spanish and Catalan are proposed in the ARB files and confirmed by the author in the
  play-test.
