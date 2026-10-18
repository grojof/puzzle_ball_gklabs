---
type: decision
title: "ADR-0010: A hybrid visual system with biomes as data"
description: "Gameplay elements are drawn in code, terrain and backdrops are generated from per-biome palettes, and the painted forest backdrop stays; worlds of ten levels cycle through five biomes."
tags: [visuals, biomes, rendering]
---

# ADR-0010: A hybrid visual system with biomes as data

**Date:** 2026-10-18 · **Status:** accepted

## Context

After the level generator and camera rebuilds, every level looked the same, and the art mixed styles: flat boost
icons, a cartoon stone portal, a painted floor tile and a painted backdrop. The author wanted a simple system that
looks high quality, can produce new floors and whole biomes, and keeps the painted night-forest backdrop. The next
change adds mechanics (moving platforms, hazards, switches, memory elements, portals) that need a consistent look.
The author chose the hybrid option, a biome per world of ten levels, and elements that are never flat colors.

## Decision

- **Worlds and biomes:** levels are grouped in worlds of ten. Each world takes the next biome of a cycle (night
  forest, desert dusk, snowy peaks, crystal caves, volcano). Repeats vary in palette, time of day and backdrop
  layers, drawn from the seed and world number with the generator's exact PRNG. The look is derived outside the
  level generator, so courses and digests do not change.
- **Biomes are data:** a palette and the recipes for the textures, silhouettes and particles. Adding a biome means
  adding an entry, not new image files.
- **Generated terrain:** body and surface textures are drawn into images once per world, when a level loads, and
  painted with repeating image shaders anchored in world coordinates: no seams, no per-tile drawing.
- **Generated backdrops:** a sky gradient, up to three cached silhouette layers with parallax, and up to 48 ambient
  particles. The night forest keeps the painted layers, adding fireflies and a tint on its variants.
- **Gameplay elements drawn in code with depth:**
  - a shadow, a glow and a lit gradient body, with a specular arc;
  - a dark outline with a light rim, so the fill, the outline or the rim contrasts with every biome;
  - a white icon that suggests the effect.

  Colors are fixed per type, and colors are reserved for the next change's elements.

## Consequences

- The app ships fewer images: the boost, goal and floor images are gone.
- Load time includes generating two textures per new world. They are cached, so most level loads pay nothing.
- The look is tuned by editing palettes and recipes, and judged on screenshots and in play, not by pixel snapshots,
  which differ between platforms.
- If players do not understand an element from its look, a first-encounter explanation bubble is the planned
  follow-up, most likely with the mechanics change.
