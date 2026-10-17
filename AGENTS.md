# AGENTS.md

Ball Odyssey is a Flutter + Flame/Forge2D physics game (Android and web) where a ball rolls, jumps and boosts
through infinite, procedurally generated levels whose difficulty keeps rising. Start with the [README](README.md);
the product vision is in [docs/product.md](docs/product.md).

## Project map

| Path | What it holds |
|---|---|
| `lib/`, `test/` | App code (Very Good Core layout, Flame game under `lib/game/`) and its tests, mirrored |
| `packages/` | Local packages: pure Dart domain and data (level generation, repositories) and `app_ui` |
| `android/`, `web/` | The only platform shells |
| `assets/` | Images, audio and licenses; `lib/gen/assets.gen.dart` is generated from it |
| `docs/` | Project docs, indexed from the README; front matter `type`/`title`/`description` on every page |
| `docs/decisions/` | ADRs, numbered `NNNN-slug.md`, immutable once accepted |
| `openspec/` | Spec-first changes (`changes/`) and living specs (`specs/`) |
| `.claude/` | Shared agent settings, OpenSpec commands and skills |
| `.github/` | CI workflows, cspell config, Dependabot, issue and PR templates |

## Conventions

- **Language:** code, identifiers, commits, docs, ADRs and specs in English. Game strings in English, Spanish and
  Catalan ([ADR-0004](docs/decisions/0004-languages.md)).
- **Very Good conventions:** Bloc/Cubit for app state, one folder per feature, `very_good_analysis` and `bloc_lint`
  with zero issues. Packages keep 100 % coverage; the app's CI threshold rises as the rebuild lands
  ([ADR-0005](docs/decisions/0005-layered-architecture.md)). Commands are in
  [docs/development.md](docs/development.md).
- **Platforms:** Android and web only ([ADR-0001](docs/decisions/0001-flame-game-android-web.md)). Every dependency
  must work on both, or sit behind an abstraction with one implementation per platform.
- **Game vs app state:** the Flame game reads inputs and settings that are passed in; it does not reach into Blocs
  through `game.buildContext`. Level generation is pure Dart and deterministic for a seed, so it is tested without
  Flutter.
- **Material comes from `material_ui`:** import `package:material_ui/material_ui.dart`, never
  `package:flutter/material.dart`. Localization delegates come from `lib/l10n/l10n.dart`
  ([ADR-0008](docs/decisions/0008-material-ui.md)).
- **Physics:** Forge2D 0.15 (Box2D v3) through `flame_forge2d`
  ([ADR-0006](docs/decisions/0006-box2d-v3-physics.md)). The world is in meters; moving bodies stay within
  0.1–10 m, and `metersToPixels` only affects rendering.
- **Commits:** Conventional Commits (the PR title is checked in CI). No AI co-author trailers in commits; AI
  assistance is disclosed only in the pull-request description (`Assisted-by: Claude`).

## How to work in this project

- **Ask before deciding.** Gameplay, architecture or product questions go to the author before implementation; the
  answer is recorded as an ADR in `docs/decisions/`.
- **Spec-first.** Non-trivial changes start with a proposal, design and tasks, and end with the specs updated.
  (The OpenSpec `/opsx:*` flow automates this; see [ADR-0003](docs/decisions/0003-spec-first-with-openspec.md).)
- **Build for the vision, not for the legacy.** The current code is a baseline; rebuild parts to fit the product
  vision and good practices instead of preserving how they work today.
- **Versions from official sources only.** Before adding or changing a package, plugin, SDK or tool, check its
  official documentation, pub.dev page or vendor compatibility matrix, pick the version validated for normal use,
  and cite the source. Pin via the lockfile, check for known vulnerabilities, read the changelog, run the tests.
  (A dependency-upgrade capability covers this.)
- **CI green before pushing.** Run the local equivalent of every CI check before a push: format, analysis, bloc
  lint, tests with coverage, the Markdown spell check after editing `.md` files, and the license check after
  changing a `pubspec.yaml`. Commands: [docs/development.md](docs/development.md#before-pushing).
- **Verify on the real game.** Gameplay and UI changes are played on Android (emulator or device) and in a browser.
  Measure frame time when touching the game loop. Screenshots capture only the app or the emulator screen, never
  the desktop.
- **Keep docs honest.** When behavior changes, update the affected `docs/` page and the README index in the same
  change. (A living-docs refresh helps.)
- **Secure by default.** Validate input at boundaries (imported savegames, seeds typed by the player); signing keys
  and credentials never in code or logs. (A secure-coding capability covers this.)
- **Untrusted until vetted.** Third-party skills and tools are checked for provenance before adoption. (A
  skill-vetting capability automates this.)
- **Pause on the irreversible.** Force-push, history rewrites, branch deletion, secret access and version bumps
  need explicit confirmation. (Safe-controls hooks enforce this when installed.)
