# Tasks

## 1. Baseline evidence and test spike

- [x] 1.1 Take a DevTools heap snapshot after 1 and after 10 level loads on the current build and record which objects retain old games (expected: `PuzzleBallGklabs`, `Forge2DWorld`, closures from timers and subscriptions) in a short note in `design.md` under D1; verify the note names the retainers found
- [x] 1.2 Add `tool/soak/level_loads.sh` (adb) that loads a level N times and prints total PSS and native heap per batch, document it in `docs/development.md`, and verify it reproduces the leak on the current build (+~5 MB per load)
- [ ] 1.3 Add a `flame_test` spike test that creates a `Forge2DGame`, steps the world once and destroys it; verify it passes with `flutter test` locally and in the CI `build` job

## 2. key_value_store package

- [x] 2.1 Create `packages/key_value_store` (pure Dart, very_good_analysis) with `KeyValueStore` and `InMemoryKeyValueStore`; verify `dart analyze` reports no issues and `dart test --coverage` reaches 100 %
- [ ] 2.2 Add `.github/workflows/key_value_store.yaml` (Very Good `dart_package`, `paths: packages/key_value_store/**`) and verify the workflow file lints with `actionlint` or a dry run in the PR

## 3. settings_repository package

- [x] 3.1 Create `packages/settings_repository` with `PlayerSettings`, `ControlMode`, defaults and per-field validation (player-settings: defaults, invalid values); verify tests for every field's fallback pass at 100 % coverage
- [x] 3.2 Implement the legacy mapping (`soundEnabled` → `muted`, keep `languageCode` and `useSensorControl`, drop `currentLevel`, keep `soundEnabled` in sync for rollback); verify the upgrade scenarios from the player-settings spec as tests
- [ ] 3.3 Add the package workflow with a path filter and verify it appears in the PR checks only when the package changes

## 4. savegame_repository package

- [x] 4.1 Create `packages/savegame_repository` with `SavedGame` (same JSON fields) and list, add, update (current level never decreases) and delete; verify tests including malformed stored entries being skipped, at 100 % coverage
- [ ] 4.2 Add the package workflow with a path filter and verify as in 3.3

## 5. App persistence wiring

- [x] 5.1 Add `SharedPreferencesKeyValueStore` (legacy `SharedPreferences` API) in `lib/` and test it with `SharedPreferences.setMockInitialValues`; verify that a store pre-filled with the old keys reads back through both repositories
- [x] 5.2 Rewrite `SettingsCubit` and `SavegameCubit` on the repositories (no direct storage, no Flutter imports), remove `currentLevel` from settings, and verify with `bloc_test` suites plus `bloc lint` at zero issues

## 6. app_ui package

- [x] 6.1 Create `packages/app_ui` with `AppColors`, `AppTheme` (dark) and bundled Poppins 400/500/600/700 from `google/fonts` at a pinned commit with its OFL license registered; verify a golden-free widget test renders text with the `Poppins` family and coverage is 100 %
- [x] 6.2 Switch the app to `app_ui`, remove `google_fonts` and `lib/shared/theme/`, and verify the app builds for Android and web and the license check passes
- [x] 6.3 Add the package workflow with a path filter

## 7. Router and settings screen

- [x] 7.1 Create the router once in `App` state and drive the locale from `SettingsCubit` (device language when unset, English fallback); verify a widget test that changes the language keeps the current route and the router instance
- [x] 7.2 Build `lib/settings/` (music volume, effects volume with a preview sound on release, control mode hidden on the web, language) as a pushed `/settings` route reachable from the title screen; verify widget tests in en/es/ca for every control and the return-to-caller scenario
- [x] 7.3 Add the new strings to all three ARB files and verify `flutter gen-l10n` and the tests in every locale pass

## 8. Audio

- [x] 8.1 Add `tool/audio/process.sh` (ffmpeg loudnorm, mono 44.1 kHz effects, 128 kbps background) and re-encode `assets/audio/*`; verify the background track is ≤ 5 MB and every effect measures within ±2 LU of the target, and record the commands in `docs/development.md`
- [x] 8.2 Implement `AudioService` (one `AudioPool` per effect, looping music player, global `AudioCache` preload, music × effects × mute volumes) behind a player factory for tests; verify unit tests that 100 rapid effect plays create no more than 3 players per effect and that volumes and mute apply immediately
- [x] 8.3 Start music after settings load, unlock on the first interaction on the web, pause and resume with the app lifecycle, and replace `AudioCubit`, `SoundToggleFab` wiring and the preload's private cache; verify widget tests for start, muted start, and lifecycle pause/resume
- [ ] 8.4 Listen on the Android emulator and in Chrome, and ask the author to confirm on a real phone that music starts on launch, is audible, has no distortion, and that effects sound even; record the result in the PR

## 9. Game runtime

- [x] 9.1 Introduce `GameConfig`, `AudioSink`, `MovementIntent` and the game callbacks, and remove every `game.buildContext` read from components; verify `flutter analyze` and a grep show no `buildContext` use under `lib/game/`
- [x] 9.2 Build levels under a `LevelComponent` with O(1) fall detection from the level's lowest terrain point, and make restart and advance swap it in place; verify `flame_test` tests that restart and advance keep the same game instance and leave no components from the previous level
- [x] 9.3 Replace boost `Future.delayed` with `TimerComponent`s on the ball and make the goal sequence part of the level; verify a test that unloading mid-boost leaves no timer and the next level's gravity scale is normal
- [x] 9.4 Split input into `TiltInput` (Android only, subscribes on mount, cancels on remove), joystick and keyboard components, swapped by `applyConfig`; verify tests that joystick mode holds no sensor subscription and that switching modes swaps the components
- [x] 9.5 Make `GameScreen` stateful (game and `FocusNode` created once, physics world destroyed on dispose), with a pause button, pause overlay (resume, restart, settings, levels) and pause on app background; verify widget tests for pause, settings-from-pause keeping the game mounted, and dispose destroying the world
- [x] 9.6 Remove dead code left by the rewrite (camera helper leftovers, `SettingsCubit.currentLevel` users, route-based restart) and verify `flutter analyze` and `bloc lint` report zero issues

## 10. Integration verification

- [x] 10.1 Run `tool/soak/level_loads.sh 30` on the emulator and verify total memory after 30 loads is within 10 % of the first load, and that 150 consecutive loads do not crash
- [x] 10.2 Play a 10-minute session on the emulator with DevTools attached and verify no sustained memory growth and no frame-time degradation; attach the numbers to the PR
- [x] 10.3 Raise `min_coverage` in `.github/workflows/main.yaml` to the coverage reached, update `docs/architecture.md` (target layering now partly real) and `docs/product.md` (gameplay today, known gaps), and verify `docs-check` and the spell check pass
- [x] 10.4 Run every local CI check from `docs/development.md#before-pushing` for the app and each package, and verify all pass before pushing

## Workflow follow-up

- Open the pull request with `Assisted-by: Claude` in the description and wait for CI.
- After merge, archive the change with `/opsx:archive` so the four specs land in `openspec/specs/`.
