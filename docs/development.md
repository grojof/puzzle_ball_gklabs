---
type: how-to
title: "Development"
description: "Set up the toolchain, run each flavor, test, localize, regenerate assets, and understand CI and Android release signing."
tags: [development, toolchain, flavors, testing, ci, l10n]
audience: maintainer
---

# Development

## Toolchain

The versions the project is built and verified with. Every addition or change of a package, plugin, SDK or tool is
checked against its official documentation or compatibility matrix first (see [AGENTS.md](../AGENTS.md)).

| Tool | Version | Where it is set |
|---|---|---|
| Flutter / Dart | 3.47.x / 3.13.x (stable) | `pubspec.yaml` constraints; CI `flutter_version` |
| Android Gradle Plugin | 9.1.0 | `android/settings.gradle.kts` |
| Gradle | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` |
| Kotlin | 2.4.0 | `android/settings.gradle.kts` |
| Java target | 17 (JDK bundled with Android Studio) | `android/app/build.gradle.kts` |
| Android compile/target SDK, min SDK, NDK | Flutter defaults | `flutter.*` in `android/app/build.gradle.kts` |
| OpenSpec CLI | 1.14.1 | Developer machine ([ADR-0003](decisions/0003-spec-first-with-openspec.md)) |

The Android NDK is required: Forge2D compiles Box2D from source with it
([ADR-0006](decisions/0006-box2d-v3-physics.md)). Host tests that create a physics world also need a C compiler
(Visual Studio Build Tools on Windows).

## Run

| Flavor | Android app id | Android label |
|---|---|---|
| `development` | `com.grojof.ballodyssey.dev` | `[DEV] Ball Odyssey` |
| `staging` | `com.grojof.ballodyssey.stg` | `[STG] Ball Odyssey` |
| `production` | `com.grojof.ballodyssey` | `Ball Odyssey` |

```sh
# Android
flutter run --flavor development --target lib/main_development.dart
# Web
flutter run -d chrome --target lib/main_development.dart
```

VS Code (`.vscode/launch.json`) and Android Studio (`.idea/runConfigurations/`) ship one launch configuration per
flavor. Each Android flavor keeps its own data, so development never touches production savegames.

## Test and analyze

```sh
flutter test --coverage --test-randomize-ordering-seed random
flutter analyze
dart run bloc_tools:bloc lint .
```

- Packages under `packages/` keep **100 %** coverage and have their own CI workflows, which run only when the package
  changes. The app's threshold (`min_coverage` in `.github/workflows/main.yaml`, now 70 %) rises as the rebuild lands
  ([ADR-0005](decisions/0005-layered-architecture.md)).
- Analysis uses `very_good_analysis` plus `bloc_lint` and must report no issues.
- Tests mirror `lib/`. `test/helpers/pump_app.dart` pumps widgets with in-memory storage and fake audio;
  `test/helpers/game_helpers.dart` builds games on flat levels with 1×1 images.
- Game tests run real Box2D physics, compiled for the host: Visual Studio Build Tools on Windows, the default
  toolchain on Linux CI.

## Localization

Strings live in ARB files under `lib/l10n/arb/` ([ADR-0004](decisions/0004-languages.md)). `app_en.arb` is the
template.

1. Add the key, with an `@key` description, to `app_en.arb`.
2. Add the translation to `app_es.arb` and `app_ca.arb`.
3. Use it through `context.l10n.<key>`.

Code is generated on build into `lib/l10n/gen/` (git-ignored); run `flutter gen-l10n` to regenerate by hand. The
app passes `localizationsDelegates` and `supportedLocales` from `lib/l10n/l10n.dart`
([ADR-0008](decisions/0008-material-ui.md)).

## Generated assets

| Output | Generator | Command |
|---|---|---|
| `lib/gen/assets.gen.dart` (asset paths) | FlutterGen | `dart run build_runner build` |
| Launcher icons (Android, web) | `flutter_launcher_icons` | `dart run flutter_launcher_icons` |
| Native splash (Android, web) | `flutter_native_splash` | `dart run flutter_native_splash:create` |

The icon and splash generators read their settings from `pubspec.yaml`. Generated files are committed.

## Audio assets

The shipped files in `assets/audio/` are made from the original masters (kept in git history) with
`tool/audio/process.sh`, which uses ffmpeg's two-pass EBU R128 `loudnorm`:

```sh
mkdir -p /tmp/audio-src && git archive efd3d1f assets/audio | tar -x -C /tmp/audio-src
tool/audio/process.sh /tmp/audio-src/assets/audio
```

- Effects: mono, 44.1 kHz, normalized to −16 LUFS (true peak −1.5 dBTP), MP3 128 kbps.
- Background music: stereo, normalized to −20 LUFS so effects sit on top, MP3 128 kbps (about 4.7 MB; the
  web download must stay under 5 MB).

Override the targets with `EFFECTS_LUFS`, `MUSIC_LUFS` and `TRUE_PEAK`. Judge loudness on a real phone or in a
browser: the Android emulator's audio output crackles on Windows hosts.

## Memory soak test

`tool/soak/level_loads.sh` loads a level repeatedly on a device or emulator through `adb` taps and prints the app's
memory after every batch, to catch leaks between level loads (the `game-session` spec allows at most 10 % growth over
30 loads):

```sh
flutter run --flavor development --target lib/main_development.dart   # then open any level
tool/soak/level_loads.sh 30 10
```

The default taps fit a 1080×2400 screen; set `TAPS` (space-separated `x,y` pairs), `SERIAL`, `APP_ID` or
`TAP_DELAY` for other devices or flows. For retainers, connect to the VM service and compare live instance counts
before and after a batch (DevTools *Memory* view, or `getAllocationProfile` with `vm_service`).

## Continuous integration

GitHub Actions runs Very Good's reusable [workflows](https://workflows.vgv.dev/) on pull requests to `main` only.
CI minutes are limited, so every workflow is scoped tightly:

| Workflow | Job | What it checks | When |
|---|---|---|---|
| `pr_checks.yaml` | `semantic-pull-request` | PR title follows Conventional Commits | Every PR, including title edits |
| `pr_checks.yaml` | `spell-check` | Spelling of the changed Markdown files (`.github/cspell.json`) | Every PR |
| `main.yaml` | `build` | Format, analysis, bloc lint and tests with coverage (Flutter 3.47.x) | PRs that change more than docs |
| `license_check.yaml` | `license_check` | Dependency licenses are in the allowed list | PRs that change a `pubspec.yaml` |
| `<package>.yaml` | `build` | The package's analysis and tests at 100 % coverage, on the VM | PRs that change that package |
| `level_generator.yaml` | `web` | The generator's tests, golden digests included, in Chrome (no coverage) | PRs that change the generator |

Stale runs of the same branch are cancelled. Dependabot (`.github/dependabot.yaml`) proposes one grouped pub
update and one grouped GitHub Actions update per month.

The heavy jobs (app build, packages, license check) skip draft pull requests. Open a pull request as a **draft** while
iterating, run the local checks below, then mark it **ready for review**: the full suite runs once, and again only
for later pushes. Each package's workflow runs only when that package changes.

### Before pushing

Run the same checks locally, so CI is not used to iterate:

```sh
dart format --set-exit-if-changed lib test
flutter analyze
dart run bloc_tools:bloc lint .
flutter test --coverage --test-randomize-ordering-seed random
# each package (pure Dart ones with dart, app_ui with flutter)
for p in packages/*/; do (cd "$p" && rm -rf coverage && dart pub global run very_good_cli:very_good test --coverage --min-coverage 100); done
# the generator must give the same levels in a browser
(cd packages/level_generator && dart test --platform chrome)
npx --yes cspell@9 --config .github/cspell.json --no-progress "**/*.md"
# only when a pubspec.yaml changed:
very_good packages check licenses --dependency-type=direct-main --dependency-type=transitive --allowed="MIT,BSD-3-Clause,BSD-2-Clause,Apache-2.0" --skip-packages="pubspec_lock_parse"
```

- **Spelling:** a correctly spelled word that cspell does not know goes in the `words` list of
  `.github/cspell.json`. A real typo is fixed in the text.
- **PR title:** Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`, …).

## Android release signing

Release builds read the keystore from environment variables, falling back to `android/key.properties`
(git-ignored):

| Variable | `key.properties` key |
|---|---|
| `ANDROID_KEYSTORE_PATH` | `storeFile` |
| `ANDROID_KEYSTORE_ALIAS` | `keyAlias` |
| `ANDROID_KEYSTORE_PRIVATE_KEY_PASSWORD` | `keyPassword` |
| `ANDROID_KEYSTORE_PASSWORD` | `storePassword` |

Keystores and passwords are never committed.
