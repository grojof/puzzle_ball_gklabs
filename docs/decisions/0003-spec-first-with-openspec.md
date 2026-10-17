---
type: decision
title: "ADR-0003: Spec-first changes with OpenSpec"
description: "Non-trivial changes go through an OpenSpec proposal, design and tasks before code."
tags: [process, openspec]
---

# ADR-0003: Spec-first changes with OpenSpec

**Date:** 2026-10-17 · **Status:** accepted

## Context

The game is about to be rebuilt around a clearer product vision (infinite procedural levels with rising
difficulty). Intent and reasoning need to survive beyond chat sessions and commit messages.

## Decision

Non-trivial changes (gameplay, level generation, architecture, persistence) start as an OpenSpec change under
`openspec/changes/` with a proposal, a design and tasks, and end with the living specs in `openspec/specs/` updated.
The `/opsx:*` commands in `.claude/` drive the flow (OpenSpec CLI 1.14.1).

## Consequences

- Small fixes and dependency bumps can skip the flow; anything that changes behavior players notice cannot.
- Product and architecture decisions found while specifying are recorded as ADRs here.
