# Tasks

## 1. Worlds, biomes and palettes

- [x] 1.1 Export `Mulberry32` and `fnv1a32` from the `level_generator` barrel; verify the package stays at 100 % coverage on VM and Chrome
- [x] 1.2 Add `lib/game/visuals/` with the `Biome` cycle, `WorldLook` selection (world, biome, variant from the seed) and `BiomePalette` per biome with HSL variants and time of day (D1, D2); verify unit tests: worlds of ten, the cycle order, variant 0 in the first cycle, different variants for worlds 1 and 6, and determinism

## 2. Terrain

- [x] 2.1 Add `TerrainTextures.generate(look)` with the body and surface recipes for the five materials, cached by look (D3); verify tests that each material produces 256 × 256 and 256 × 64 images whose left and right edge columns match
- [x] 2.2 Draw floors (including under ledges) and ramps with the generated textures through image shaders anchored in world coordinates, and remove `floor.png`; verify the rendering test draws a level in every biome, and the existing game tests pass

## 3. Backdrop

- [x] 3.1 Add `BiomeBackdrop` (sky gradient, up to three cached silhouette layers with parallax factors, up to 48 particles) and the silhouette and particle recipes for the four generated biomes (D4); verify tests that each biome builds its layers within budget and renders, and that the far layers move slower than the near ones
- [x] 3.2 Keep the painted backdrop for the night forest, with variant color filters and fireflies, and swap backdrops when the world changes (D7); verify `flame_test` tests that entering world 2 shows the desert backdrop and world 1 the painted one

## 4. Gameplay elements

- [x] 4.1 Add `ElementPalette` with the element and reserved colors (D5); verify the contrast test (outline at least 3:1 against every biome's colors, boost hues at least 60° apart)
- [x] 4.2 Replace the three boost classes with one `BoostComponent(type)` drawn in code, with icons and a pulse, keeping the boost effects; delete the boost images; verify the boost tests, envelope test and bot test still pass, and a rendering test of each type
- [x] 4.3 Redraw the checkpoint (waving flag, gold with a particle burst on activation) and the goal (animated portal), and delete `goal.png`, cleaning the preload list; verify the checkpoint and goal tests and rendering tests

## 5. World announcement

- [x] 5.1 Show "World N · biome name" under the level label on the first level of each world, with biome names in English, Spanish and Catalan (D6); verify a widget or `flame_test` test for level 11 and none for level 12

## 6. Docs and verification

- [x] 6.1 Write ADR-0010 (the visual system: hybrid art, biomes as data, generated textures) and update `docs/product.md`, `docs/architecture.md`, `docs/glossary.md` (world, biome, variant) and the README ADR list; verify `docs-check` and the spell check pass
- [x] 6.2 Play every biome with the author on the phone and in Chrome (a test savegame or seed reaching each world), take screenshots of each, measure frame time against 4.9–5.1 ms average and 8.2 ms p99, and tune palettes and recipes from the feedback; ask whether the elements are understood without explanation (if not, decide with the author on first-encounter bubbles); verify no runtime errors and the feedback noted for the PR
- [ ] 6.3 Run the local CI checks (format, analyze, bloc lint, tests in random order with coverage, packages, licenses if a pubspec changed, spell check), open the PR as a draft and mark it ready once green locally; verify CI passes

## Workflow follow-up

- After merge, archive the change so `game-visuals` lands in `openspec/specs/`.
- Next change: new mechanics with the reserved palette: moving and crumbling platforms, hazards, color switches with
  blocks and doors, memory platforms and portals.
