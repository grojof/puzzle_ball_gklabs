---
type: decision
title: "ADR-0012: The web game is built and served by Coolify on our own server"
description: "Coolify clones the repository, builds a multi-stage Dockerfile (Flutter, then unprivileged nginx) on the VPS and serves it; no image registry and no deploy pipeline in GitHub."
tags: [deployment, web, docker]
---

# ADR-0012: The web game is built and served by Coolify on our own server

**Date:** 2026-10-18 · **Status:** accepted

## Context

Ball Odyssey targets Android and the web ([ADR-0001](0001-flame-game-android-web.md)), but the web build was not
published. The author runs a VPS with Coolify v4.4.6 behind Traefik, managed from a separate project. They decided
to host the game at `ball-odyssey.games.guillermousk.com`, without pushing images to any registry and without
deploy workflows in GitHub, keeping CI minutes low. The Coolify panel is reachable only over a VPN.

## Decision

- Coolify builds the repository's `Dockerfile` on the server, from the public repository's `main` branch, with its
  Dockerfile build pack.
- **Build stage:** Flutter 3.47.7 cloned from its official repository onto Debian slim, pinned by digest. The
  `cirruslabs` Flutter images stop at 3.44.
- **Runtime stage:** unprivileged nginx (stable line), pinned by digest, on port 8080. It serves the single-page
  app with revalidated caching and security headers.
- Updates are manual: merge to `main`, then Redeploy. Rollback uses Coolify's previous deployments.

## Consequences

- No registry credentials, no deploy workflow and no CI minutes for deployment.
- The server spends a few minutes of CPU on each build, and the first one fetches the Flutter SDK.
- Base image digests and the Flutter version are updated by hand, in a pull request, like other dependencies.
- Nothing secret may be built into the web bundle; [Deployment](../deployment.md) states it.
