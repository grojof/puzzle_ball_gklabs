---
type: decision
title: "ADR-0002: MIT license"
description: "Ball Odyssey is open source under the MIT license, with no usage restrictions."
tags: [license]
---

# ADR-0002: MIT license

**Date:** 2026-10-17 · **Status:** accepted

## Context

The README showed an MIT badge, but the repository had no `LICENSE` file. The author wants the game fully open
source, without restrictions.

## Decision

The project is licensed under the [MIT license](../../LICENSE). Bundled fonts keep their own licenses (SIL Open
Font License, registered with Flutter's `LicenseRegistry`).

## Consequences

- Dependencies must use licenses compatible with MIT redistribution. CI allows MIT, BSD-2-Clause, BSD-3-Clause and
  Apache-2.0; anything else needs an ADR.
