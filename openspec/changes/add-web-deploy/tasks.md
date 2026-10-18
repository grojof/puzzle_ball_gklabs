# Tasks

## 1. Image

- [x] 1.1 Add the multi-stage `Dockerfile` (D1, D2, D3) and `.dockerignore` (D4); verify `docker build` succeeds from a clean checkout
- [x] 1.2 Add `deploy/web/nginx.conf` and `deploy/web/security-headers.conf`; verify against the running container that a deep link returns the entry page, every response has `Cache-Control: no-cache`, the security headers and no server version, JS is gzipped, `.wasm` is `application/wasm`, and nginx runs as a non-root user on 8080

## 2. Docs

- [x] 2.1 Write `docs/deployment.md` (Coolify setup, Redeploy, rollback, the `--dart-define` and source-map warning, where the pinned versions live), ADR-0012, and the README index; verify `docs-check` and the spell check

## 3. Delivery

- [ ] 3.1 Open the PR as ready; verify CI passes

## Workflow follow-up

- The author merges the PR, configures the application in Coolify and deploys; the selfhost-forge session checks the
  certificate, the HTTPS redirect and the proxy logs.
- After merge, archive the change so `web-deployment` lands in `openspec/specs/`.
