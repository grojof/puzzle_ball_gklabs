---
type: decision
title: "ADR-0001: Flame game on Very Good Core, Android and web only"
description: "Keep the Very Good Core app shell with a Flame/Forge2D game, and target Android and web exclusively."
tags: [platforms, template, flame]
---

# ADR-0001: Flame game on Very Good Core, Android and web only

**Date:** 2026-10-17 · **Status:** accepted

## Context

The project started in 2025 from Very Good CLI with a Flame game inside a Flutter app shell. The README claimed iOS
and Windows support, but only `android/` and `web/` were ever committed. The author plays on an Android phone and in
a browser.

## Decision

- Keep the Very Good Core shell: Bloc/Cubit, flavors `development` / `staging` / `production`
  (`lib/main_<flavor>.dart`), ARB localization, `very_good_analysis`, `bloc_lint`, Very Good CI workflows.
- The game runs on Flame with Forge2D physics ([ADR-0006](0006-box2d-v3-physics.md)).
- Target **Android and web only**. No iOS, macOS, Linux or Windows folders are kept.

## Consequences

- Every plugin must support Android and web, or come with a per-platform implementation behind an abstraction.
- Tilt control (`sensors_plus`) is Android-only in practice; web falls back to keyboard and on-screen controls.
- Flavors are configured on Android; on web they are selected by Dart entry point only.
