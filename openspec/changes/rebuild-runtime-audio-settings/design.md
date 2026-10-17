# Design

## Context

See proposal.md (Why) for the measurements. The current structure that matters here:

- `GamePage.build` creates `PuzzleBallGklabs` and a `FocusNode` on every build. Falling and completing a level call
  `context.go('/game?...')`, which builds a brand-new page, game and physics world each time.
- `Forge2DWorld` never destroys its native Box2D world. Box2D v3 caps simultaneous worlds (128), so leaked worlds end
  in a `StateError`.
- `BallComponent`:
  - reads `SettingsCubit` through `game.buildContext` every frame;
  - scans every body in the world each frame while airborne;
  - always subscribes to the accelerometer;
  - schedules boost endings with `Future.delayed`, which keeps the component alive after removal.
- `AppView.build` creates the `GoRouter`, so a locale change rebuilds it.
- `AudioCubit` creates an `AudioPlayer` per effect. `PreloadCubit` loads audio into a private
  `AudioCache(prefix: '')` that playback never uses. The Cubit is created lazily, so its "start music when settings
  load" listener misses the only emission.
- Persistence is direct `SharedPreferences` calls inside two Cubits (`savedGames` JSON list; `languageCode`,
  `soundEnabled`, `useSensorControl`, `currentLevel`).

Specs: `game-session`, `game-audio`, `player-settings`, `player-controls` in this change.

## Goals / Non-Goals

**Goals:**

- A game that can run for hours: constant memory, no world leak, nothing left running after a level ends.
- A clean boundary between the Flutter app (state, persistence, menus) and the Flame game (simulation, rendering).
- Data and theme code in packages that are tested in isolation at 100 %.

**Non-Goals:**

- Changing level generation, level data or the savegame model. The savegame entity moves to a package unchanged; the
  next change redesigns progression.
- Physics tuning (forces, damping, friction) and visual redesign.
- Haptics, accessibility options or key remapping in settings.

## Decisions

### D1. One game per session; levels swap in place

`GameScreen` (stateful) creates the game once in `initState` and owns its `FocusNode`. The game builds each level under
a single `LevelComponent` root holding terrain, sensors, ball and input. Restarting or advancing:

1. removes the `LevelComponent`, which destroys its bodies through `BodyComponent.onRemove`;
2. adds a new one built from the next `LevelData`.

The Forge2D world lives as long as the game; `GameScreen.dispose` calls `game.world.physicsWorld.destroy()` after the
game is detached.

- *Alternative: keep navigating per level but destroy the world in `onRemove`.* Rejected: it still rebuilds widgets,
  assets and the camera on every fall, and route churn is the likely retainer of old games.
- *Alternative: a new `Forge2DWorld` per level.* Rejected: costs more than clearing bodies, and it needs a camera
  rebind every time.

The acceptance check is the 30-load soak from the `game-session` spec.

**Heap evidence (task 1.1, 2026-10-17):** live instances after a forced GC, measured through the VM service:

| Class | After 1 load | After 10 loads |
|---|---|---|
| `PuzzleBallGklabs` | 1 | 10 |
| `Forge2DWorld` / native `World` | 1 | 10 |
| `Body` | 48 | 480 |
| `GamePage` | 1 | 10 |

Every old game stays alive. The retaining path runs from the accelerometer's broadcast stream, through
`BallComponent._accelSub`, to the ball, and from there to the whole game. The subscription is created even in joystick
mode. It is never cancelled, because disposing the `GameWidget` does not remove the game's components, so `onRemove`
never runs. The game in turn holds the `GamePage` through its callbacks' closures. Flame's debug-only `DevToolsService`
also keeps a reference to the latest game; that is one instance, not a leak.

Consequences for this design: D4 (sensor only in tilt mode, cancelled on removal) removes the retainer. D1 adds an
explicit teardown in `GameScreen.dispose`, which removes the level and destroys the world instead of relying on
`onRemove`.

### D2. The game knows nothing about Blocs

The game gets a `GameConfig` value (control mode) and an `AudioSink` interface (`play(GameSound)`). It reports
`onLevelCompleted(levelIndex)` and `onPauseRequested` through callbacks. `GameScreen` bridges these:

- it listens to `SettingsCubit` and pushes config changes with `game.applyConfig`;
- it updates the savegame through the repository;
- it shows overlays.

The pause menu is a `GameWidget` overlay (Flutter widgets). Pausing uses `pauseEngine`/`resumeEngine`, so physics and
game timers stop together. `AppLifecycleListener` pauses the game when the app is hidden.

### D3. Game-time timers and O(1) fall detection

Boost durations run on a Flame `Timer` owned by the ball and ticked in its `update`. It pauses with the engine and dies
with the level. A `TimerComponent` child was the first idea, but adding components from contact callbacks needs
lifecycle handling that a plain timer avoids.
Falling is "ball below the level's lowest terrain point by a margin". The `LevelComponent` computes that point once from
`LevelData`. This replaces the per-frame scan and the wall-clock "airborne for 2 s" rule; the player sees the same
behavior, a reset after falling off the course.

### D4. Inputs as removable components

- `TiltInput` subscribes to the accelerometer in `onMount` and cancels in `onRemove`. It exists only in tilt mode and
  only on Android, where `kIsWeb` is false.
- `KeyboardInput` and the joystick exist only in joystick mode.

`applyConfig` swaps them. The ball reads a single `MovementIntent` (a value from −1 to 1) and a jump request. The
proportional tilt curve and dead zone from the baseline are kept.

### D5. Router created once

The `GoRouter` lives in the `App` state, created in `initState`. `MaterialApp.router` rebuilds on locale changes with
the same router instance. `/settings` is a pushed route, so opening it from the paused game keeps `GameScreen` mounted
underneath.

### D6. Audio service instead of an audio Cubit

`AudioService` is a plain Dart class in `lib/audio/`, provided with `RepositoryProvider`:

- three low-latency players per effect, created at preload and used in turn (stop, set volume, resume), so rapid
  jumps overlap without creating players. The first version used `audioplayers`' `AudioPool`, but the 10-minute
  session counted 32 live players. `AudioPool` reclaims a player only on a completion event, which Android's
  SoundPool-backed low-latency players never send;
- one looping music `AudioPlayer` in media-player mode;
- the global `AudioCache.instance`, preloaded during loading, which is the cache playback actually reads;
- volumes computed as `musicVolume × (muted ? 0 : 1)` and `effectsVolume × (muted ? 0 : 1)`.

`App` calls `audio.start()` after settings load. That replaces the lost-emission bug, because the service is created
eagerly and told explicitly. On the web, a root `Listener` calls `audio.unlock()` on the first pointer or key event,
since browsers block autoplay. `AppLifecycleListener` pauses and resumes the music. `GameScreen` adapts the service to
the game's `AudioSink`.

- *Alternative: keep an `AudioCubit`.* Rejected: audio has no UI state of its own. Volumes and mute are settings, so they
  belong to `SettingsCubit`.
- *Alternative: `flame_audio`.* Rejected: it is a thin wrapper over the same `audioplayers` API and adds a dependency for
  `Bgm`, which a single looping player already covers.

### D7. Audio assets processed reproducibly

`tool/audio/process.sh` (ffmpeg) re-creates the shipped files:

- **Effects:** mono, 44.1 kHz, loudness-normalized with `loudnorm` to the same integrated target (about −16 LUFS,
  true peak −1.5 dBTP), MP3 at 128 kbps.
- **Background:** normalized lower (about −20 LUFS, so effects sit on top), stereo MP3 at 128 kbps. That is about
  4.7 MB for 4:53.

MP3 stays because it plays on every Android version and browser in scope. The originals stay in git history; the
script documents how the shipped files were made.

### D8. Persistence packages over a key-value interface

- `key_value_store` (pure Dart): `KeyValueStore` with typed get/set/remove for `String`, `bool`, `double`, `int` and
  `List<String>`, plus `InMemoryKeyValueStore`.
- `settings_repository`: `PlayerSettings` (`musicVolume`, `effectsVolume`, `muted`, `controlMode`, `languageCode?`,
  where `null` means the device language). It validates every stored value and falls back per field. It maps the legacy
  `soundEnabled` to `muted` once.
- `savegame_repository`: `SavedGame` and the same `savedGames` JSON format; malformed entries are skipped, not fatal.
- App adapter `SharedPreferencesKeyValueStore` uses the legacy `SharedPreferences` API on purpose: on Android,
  `SharedPreferencesAsync` and `SharedPreferencesWithCache` default to a different backend (DataStore), which would hide
  existing saves.

Cubits (`SettingsCubit`, `SavegameCubit`) depend on the repositories, not on storage.

### D9. `app_ui` with bundled Poppins

The theme, colors and text theme move to `packages/app_ui`. It bundles the Poppins weights the theme uses (400, 500, 600,
700) from the `google/fonts` repository at a pinned commit, under SIL OFL, registered with `LicenseRegistry`.
`google_fonts` is removed, so the first launch no longer needs the network and the web doesn't fetch fonts at runtime.

### D10. Tests and CI

- Packages run `dart test` / `flutter test` at 100 %.
- App tests cover the Cubits, the settings screen in all three locales, `AudioService` with a fake player factory, and
  game lifecycle with `flame_test`: restart and advance keep one game, the level's components are removed, and the
  world is destroyed on dispose. Physics tests need Box2D compiled for the host. The CI Linux runners have a C
  toolchain; locally, Windows needs Visual Studio Build Tools.
- Each package gets its own workflow with a `paths` filter, so a package's CI runs only when it changes.
- The app's `min_coverage` rises to the coverage reached at the end of this change.

## Risks / Trade-offs

- **[Native Box2D in host tests fails to build on CI]** → A spike test in task 1 runs one physics step under
  `flutter test` locally and on CI before the rest depends on it. Fallback: tag physics tests and run them only locally,
  and test the lifecycle without stepping.
- **[A heap retainer other than routing and timers]** → D1 removes the route churn regardless. The heap snapshot in task
  1 and the soak in the final task prove it before merging.
- **[Loudness targets sound wrong on a real device]** → The targets are script parameters. The author listens on the
  phone and in the browser before merging.
- **[Emulator audio distortion is mistaken for a bug]** → Audio quality is judged on a real device or browser, not the
  emulator.
- **[Legacy `SharedPreferences` API is deprecated later]** → It is isolated in one adapter, and a later storage migration
  touches only that class.
- **[The savegame model changes again next change]** → The repository keeps the stored format versioned implicitly by
  its fields. The next change adds a migration in the repository, not in the UI.

## Migration Plan

- On first launch after the update, `settings_repository` reads the legacy keys. `soundEnabled == false` becomes
  `muted = true`; the stored `languageCode` and `useSensorControl` are kept as they are; `currentLevel` is ignored and
  removed.
- Savegames are read from the same key and format, so nothing migrates.
- **Rollback:** revert the pull request. The new keys (`musicVolume`, `effectsVolume`, `muted`) are ignored by the old
  build, and `soundEnabled` is kept in sync while it exists, so a downgrade still sees the mute choice.

## Open Questions

- The exact LUFS targets are fixed by ear on a device during the audio task. The script takes them as parameters.
