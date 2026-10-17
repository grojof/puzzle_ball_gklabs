---
type: decision
title: "ADR-0005: Layered architecture with key local packages"
description: "UI and game in lib/, with level generation, persistence and theme extracted into local packages."
tags: [architecture, packages, testing]
---

# ADR-0005: Layered architecture with key local packages

**Date:** 2026-10-17 · **Status:** accepted

## Context

All code lived in `lib/`: the level generator imported Forge2D types, Cubits wrote to `shared_preferences`
directly, and the Flame components read Blocs through `game.buildContext`. Nothing was tested. The generator is the
heart of the game and has to be deterministic and well tested before it can be improved.

## Decision

Layers with dependencies pointing inwards only (UI and game → repositories → data clients), following Flutter's
[app architecture guide](https://docs.flutter.dev/app-architecture). For now only the packages that clearly pay off
are extracted:

| Package | Kind | Role |
|---|---|---|
| `level_generator` | Dart | Seeded, deterministic level generation and the difficulty curve; no Flutter or Forge2D |
| `savegame_repository` | Dart | Savegames and progress behind an interface over a key-value store |
| `settings_repository` | Dart | Player settings (language, sound, control mode) behind an interface |
| `app_ui` | Flutter | Theme, colors and bundled fonts |

Audio and other platform services stay in `lib/` until a second implementation or a test need justifies a package.

## Consequences

- Packages keep 100 % coverage with their own CI jobs. The app's CI threshold starts at 0 and rises as each part of
  the rebuild lands with tests.
- The game receives level data and settings as plain values, which makes it testable with `flame_test`.
