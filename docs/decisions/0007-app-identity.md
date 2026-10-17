---
type: decision
title: "ADR-0007: App identity"
description: "The game is called Ball Odyssey, with application id com.grojof.ballodyssey."
tags: [branding, android]
---

# ADR-0007: App identity

**Date:** 2026-10-17 · **Status:** accepted

## Context

The repository is `puzzle_ball_gklabs`, the Android label was already "Ball Odyssey", and the application id was
the template's `com.example.verygoodcore.puzzle_ball_gklabs`, which Google Play rejects.

## Decision

| Flavor | Application id | Label |
|---|---|---|
| `production` | `com.grojof.ballodyssey` | Ball Odyssey |
| `staging` | `com.grojof.ballodyssey.stg` | [STG] Ball Odyssey |
| `development` | `com.grojof.ballodyssey.dev` | [DEV] Ball Odyssey |

The Dart package keeps the name `puzzle_ball_gklabs` to avoid churn in imports.

## Consequences

- Installs made with the old id are a different app; their local savegames are not carried over.
- The web title and manifest use "Ball Odyssey".
