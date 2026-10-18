---
type: how-to
title: "Deployment"
description: "Deploy the web game to the self-hosted Coolify server: application settings, updates, rollback, and what never goes into the public build."
tags: [deployment, web, coolify, docker, nginx]
audience: maintainer
---

# Deployment

The web game runs at **https://ball-odyssey.games.guillermousk.com**, on the author's VPS with Coolify
([ADR-0012](decisions/0012-self-hosted-web-on-coolify.md)). Coolify clones this public repository, builds the
`Dockerfile` at its root on the server, and serves the image behind its Traefik proxy. Nothing is pushed to an image
registry, and GitHub Actions do not deploy.

## What the image contains

| Stage | Base | Does |
|---|---|---|
| Build | `debian:bookworm-20261005-slim`, by digest | Clones Flutter 3.47.7, then `flutter build web --release -t lib/main_production.dart` |
| Runtime | `nginxinc/nginx-unprivileged:1.30.6-alpine-slim`, by digest | Serves `build/web` on port 8080 as a non-root user |

nginx's configuration lives in `deploy/web/`:

- `nginx.conf` routes unknown paths to `index.html` for go_router, and gzips text and wasm;
- every response carries `Cache-Control: no-cache`, because Flutter does not version `main.dart.js` or
  `flutter_bootstrap.js`; browsers revalidate with ETags and pick up a redeploy at once;
- `security-headers.conf` holds the security headers. Any `location` that adds a header must include this file
  again, since `add_header` in a block replaces the inherited ones.

Check the image locally with `docker build -t ball-odyssey-web .` and
`docker run --rm -p 8080:8080 ball-odyssey-web`, then open http://localhost:8080.

## Set up the application in Coolify

The panel is reachable only over the VPN.

1. **New → Public Repository**, with `https://github.com/grojof/puzzle_ball_gklabs`, branch `main`.
2. **Build pack:** Dockerfile. **Dockerfile location:** `/Dockerfile` (the default). **Port:** `8080`.
3. **Domain:** `https://ball-odyssey.games.guillermousk.com`. Traefik issues the certificate over HTTP-01.
4. **Deploy.** The first build clones the Flutter SDK and takes several minutes; later builds reuse the cached
   layers.

## Update and roll back

- **Update:** merge to `main`, then **Redeploy** in Coolify. There is no webhook, since the panel is behind the VPN.
- **Roll back:** pick a previous deployment in Coolify, or revert the pull request and Redeploy.

## Never in the build

Everything in the web build is public JavaScript:

- **No secrets through `--dart-define`.** Any value passed at build time is readable in the bundle.
- **No `--source-maps`.** They would publish the Dart source.

## Keeping it current

The Flutter version (`FLUTTER_VERSION`) and the two base images are pinned in the `Dockerfile`. Update them in a
pull request, like any dependency: check the official release, take the new digest with
`docker buildx imagetools inspect <image>:<tag>`, and build locally before merging.
