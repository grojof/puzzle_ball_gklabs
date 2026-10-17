---
type: decision
title: "ADR-0006: Box2D v3 physics through flame_forge2d 0.20"
description: "Move from the pure-Dart Forge2D 0.14 to the native Box2D v3 bindings of Forge2D 0.15."
tags: [physics, flame, dependencies]
---

# ADR-0006: Box2D v3 physics through flame_forge2d 0.20

**Date:** 2026-10-17 · **Status:** accepted

## Context

The game used `flame_forge2d` 0.19 (pure-Dart Forge2D 0.14). `flame_forge2d` 0.20.0 is the release that adapts to
Flutter 3.47 and migrates to Forge2D 0.15, which binds the native Box2D v3 library: compiled from source with the
platform toolchain on Android (NDK) and run as WebAssembly on the web
([changelog](https://pub.dev/packages/flame_forge2d/changelog),
[migration guide](https://docs.flame-engine.org/main/bridge_packages/flame_forge2d/migration.html)).

## Decision

Use `flame_forge2d` ^0.20.0. The world is laid out in meters with moving bodies between 0.1 and 10 m (the ball is
0.2 m in radius, tiles 1.5 m). `metersToPixels` (40) only scales rendering; camera zoom is relative to it.

## Consequences

- Fixtures become shapes (`ShapeDef`, `SurfaceMaterial`); contact and sensor events are opt-in per shape.
- `gravityScale` is a scalar; `body.isEnabled` replaces `setActive`; destroyed bodies are checked with `isValid`.
- Physics feel changes slightly (Box2D v3 solver, speculative contacts) and is re-tuned during the rebuild.
- Host tests that create a physics world need a C toolchain (Visual Studio on Windows, clang/gcc on Linux CI).
