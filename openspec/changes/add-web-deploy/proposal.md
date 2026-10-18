# Proposal

## Why

The web build exists but is not published anywhere. The author wants Ball Odyssey playable on the web at
`https://ball-odyssey.games.guillermousk.com`, served from their own VPS by Coolify, without any image registry or
deploy pipeline in GitHub.

## What Changes

- **A Dockerfile at the repository root:**
  - a build stage with Flutter 3.47.7 cloned from the official repository on a pinned Debian slim image, which
    builds the production web release;
  - a runtime stage with unprivileged nginx (pinned by digest) on port 8080, serving the build.
- **nginx configuration** (`deploy/web/`):
  - single-page app routing and revalidation of every file, since Flutter does not version its bundles;
  - gzip and security headers on every response.
- **`.dockerignore`:** only what the web build needs goes into the build context.
- **Deployment guide** (`docs/deployment.md`) for Coolify, and **ADR-0012** recording the self-hosted approach.
- Nothing is pushed to a registry and no GitHub Actions deploy. Coolify clones `main`, builds the Dockerfile on the
  server and serves it; updates are a manual Redeploy.

## Capabilities

### New Capabilities
- `web-deployment`: how the web game is built, packaged and served: the container image, its web server behavior,
  and what may and may not be built into it.

### Modified Capabilities

## Impact

- New files only: `Dockerfile`, `.dockerignore`, `deploy/web/nginx.conf`, `deploy/web/security-headers.conf`,
  `docs/deployment.md`, `docs/decisions/0012-self-hosted-web-on-coolify.md`, and the README index.
- No app code changes and no new Dart dependencies. CI is unchanged.
