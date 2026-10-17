---
type: decision
title: "ADR-0004: Languages"
description: "Code and docs in English; game strings in English, Spanish and Catalan."
tags: [l10n, conventions]
---

# ADR-0004: Languages

**Date:** 2026-10-17 · **Status:** accepted

## Context

The game already ships ARB files for English, Spanish and Catalan, while comments and identifiers mix Spanish and
English.

## Decision

- Code, identifiers, comments, commits, docs, ADRs and specs are written in English.
- Game strings are localized in English (template), Spanish and Catalan, through ARB files in `lib/l10n/arb/`.
- Generated localization code goes to `lib/l10n/gen/` and is not committed.

## Consequences

- Spanish comments in the legacy code are translated when that code is rebuilt.
- Every new string needs its three translations; UI tests run in every supported locale.
