# Ball Odyssey for the web: Flutter builds the app, nginx serves it.
# Built on the server by Coolify from this repository (docs/deployment.md).

# --- Build: Flutter web release -------------------------------------------
# Debian 12 (bookworm) slim, 2026-10-05 snapshot, pinned by digest.
FROM debian:bookworm-20261005-slim@sha256:7c7b2c966bc9ee8cedfeef67e0e279108992c77681fa595db4a9d65c06ccc587 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git unzip xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Flutter never runs as root.
RUN useradd --create-home --uid 10001 builder \
    && mkdir -p /opt/flutter /app \
    && chown builder:builder /opt/flutter /app
USER builder

# The SDK the project is developed and tested with (pubspec, CI).
ARG FLUTTER_VERSION=3.47.7
RUN git clone --depth 1 --branch "${FLUTTER_VERSION}" \
        https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"
RUN flutter config --no-analytics --no-cli-animations \
    && flutter precache --web

WORKDIR /app

# Dependencies first, so code changes reuse this layer: the app's pubspec
# and lockfile, and the local packages it depends on by path. l10n.yaml
# comes with the code: with it, pub get would generate the translations
# before their sources are here.
COPY --chown=builder:builder pubspec.yaml pubspec.lock ./
COPY --chown=builder:builder packages/ packages/
RUN flutter pub get --enforce-lockfile

COPY --chown=builder:builder . .
# No --source-maps and no --dart-define with secrets: everything built here
# ends up in public JavaScript.
RUN flutter build web --release -t lib/main_production.dart

# --- Runtime: unprivileged nginx on port 8080 -----------------------------
# nginx 1.30.6 (stable), Alpine slim, unprivileged, pinned by digest.
FROM nginxinc/nginx-unprivileged:1.30.6-alpine-slim@sha256:4ac59c85c8c46d9e91eaabd2122cda4923ba380cf11f4138e389f069bcdc77a3

COPY deploy/web/nginx.conf /etc/nginx/conf.d/default.conf
COPY deploy/web/security-headers.conf /etc/nginx/snippets/security-headers.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080
