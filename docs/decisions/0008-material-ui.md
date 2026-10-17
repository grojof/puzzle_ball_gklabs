---
type: decision
title: "ADR-0008: Material from material_ui"
description: "Import Material widgets from the material_ui package, which replaces package:flutter/material.dart."
tags: [flutter, dependencies, ui]
---

# ADR-0008: Material from material_ui

**Date:** 2026-10-17 · **Status:** accepted

## Context

Material was decoupled from the Flutter framework into the [`material_ui`](https://pub.dev/packages/material_ui)
package. `go_router` 18.0 and `google_fonts` 9 already depend on it, and mixing its types with
`package:flutter/material.dart` fails to compile (for example `TextTheme`).

## Decision

Import `package:material_ui/material_ui.dart` everywhere. Localization delegates come from `lib/l10n/l10n.dart`,
which adds the `material_ui` Material delegates, not `AppLocalizations.localizationsDelegates`.

## Consequences

- Flame keeps using `package:flutter/widgets.dart` and `painting.dart` internally; only Material imports change.
