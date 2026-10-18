# Design

## Context

See proposal.md for the motivation. The server runs Coolify v4.4.6 on Ubuntu 24.04 (4 vCPU, 8 GB of RAM, 4 GB of
swap), behind its Traefik proxy, which issues certificates over HTTP-01 and enforces strict SNI. The panel is only
reachable over a VPN, so there is no webhook; updates are a manual Redeploy. The app builds for the web with
`flutter build web`; the localization files are generated during the build from `l10n.yaml`, and the asset code
(`lib/gen/`) is committed.

## Goals / Non-Goals

**Goals:**
- A Dockerfile that Coolify's Dockerfile build pack can build on the server from a clean clone.
- Good layer caching, so a code-only change rebuilds quickly.

**Non-Goals:**
- WebAssembly builds with threads (they would need COOP/COEP headers).
- A CDN, analytics, or a staging environment.

## Decisions

### D1. Flutter from its git repository, not a prebuilt image
The build stage clones `flutter/flutter` at tag 3.47.7 onto `debian:bookworm-20261005-slim`, pinned by digest, and
runs `flutter precache --web`. Flutter runs as an unprivileged user.

- *Alternative: `ghcr.io/cirruslabs/flutter`.* Rejected: it has no 3.47 tags (the latest is 3.44.0).

### D2. Layer order
SDK → `pubspec.yaml`, `pubspec.lock` and `packages/` (the path dependencies) → `flutter pub get --enforce-lockfile`
→ the rest → `flutter build web --release -t lib/main_production.dart`. A change to the app's code reuses the SDK and
dependency layers. `l10n.yaml` comes with the rest: with it, `pub get` would try to generate the translations before
the ARB files are copied.

### D3. Runtime on unprivileged nginx
`nginxinc/nginx-unprivileged:1.30.6-alpine-slim`, the current stable line, pinned by digest. It listens on 8080 as a
non-root user.

- **Routing:** `try_files $uri $uri/ /index.html` serves go_router's paths.
- **Caching:** `Cache-Control: no-cache` on everything, with ETags, because Flutter does not version `main.dart.js`
  or `flutter_bootstrap.js`.
- **Compression:** gzip for JS, CSS, JSON, wasm and SVG. nginx's `mime.types` already maps `.wasm` to
  `application/wasm`.
- **Headers:** the security headers live in one snippet, included in the server block. Any block that adds headers
  must include it again, because `add_header` in a block replaces the inherited ones.

### D4. Build context
`.dockerignore` keeps out VCS data, IDE settings, build outputs, tests, Android, docs and specs, so the context
is small and changes to those files do not invalidate the build layers.

## Risks / Trade-offs

- **[First build is slow and heavy: SDK clone, precache, dart2js]** → The layers cache on the server. The VPS has
  8 GB of RAM plus swap, enough for dart2js.
- **[Pinned digests age]** → Updating them is a deliberate change. The deployment guide lists where they are.
- **[No automatic deploys]** → Accepted: the panel is behind a VPN by design.

## Migration Plan

New deployment. **Rollback:** Coolify's own rollback to a previous image, or revert the pull request and Redeploy.
