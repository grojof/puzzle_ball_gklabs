---
type: explanation
title: "Architecture"
description: "How Ball Odyssey is structured: the Flutter app, the Flame game session, audio, and the local packages."
tags: [architecture, flame, bloc]
audience: maintainer
---

# Architecture

Ball Odyssey is a Flutter app built on Very Good Core with a Flame game inside
([ADR-0001](decisions/0001-flame-game-android-web.md)). Flutter handles menus, settings, routing and persistence;
Flame and Forge2D run the game ([ADR-0006](decisions/0006-box2d-v3-physics.md)). Code is layered with dependencies
pointing inwards, and data and theme live in local packages ([ADR-0005](decisions/0005-layered-architecture.md)).

```mermaid
flowchart TB
  subgraph UI["UI and game · lib/"]
    APP["App<br/>router · providers · lifecycle"]
    MENUS["menus · settings screen"]
    GAME["GamePage → BallOdysseyGame<br/>one game per session"]
    AUDIO["AudioService<br/>effect pools · music"]
  end
  subgraph PKG["Local packages · packages/"]
    SET["settings_repository"]
    SAVE["savegame_repository"]
    KV["key_value_store"]
    UI_PKG["app_ui<br/>theme · Poppins"]
  end
  SP[("shared_preferences<br/>adapter in lib/")]
  APP --> MENUS & GAME & AUDIO
  MENUS --> SET & SAVE
  GAME -- "GameConfig in, callbacks out" --> APP
  GAME -- "AudioSink" --> AUDIO
  SET & SAVE --> KV
  KV -. implemented by .-> SP
  MENUS & GAME --> UI_PKG
```

## App shell

Three flavor entry points call `bootstrap(App.onDevice)`. `App` is stateful and creates, once for the app's lifetime:

- the `GoRouter` (so a language change never restarts navigation);
- the image cache and the `AudioService`;
- `SettingsCubit`, `SavegameCubit` and `PreloadCubit`;
- an `AppLifecycleListener` that pauses and resumes the music.

On start it loads settings and savegames, preloads images and audio, applies the volumes and starts the music. On the
web it retries the music at the first tap or key press, because browsers block audio until then.
`AudioSettingsListener` applies every settings change to the audio service.

| Route | Screen |
|---|---|
| `/loading` | Preload progress, then the menu (or a deep link's target) |
| `/menu` | Title screen: continue, savegames, settings |
| `/savegames`, `/levels` | Savegame list and level selector |
| `/game` | `GamePage`, one play session |
| `/settings` | Music and effects volume, control mode, language; pushed over its caller |

## Game session

`GamePage` creates one `BallOdysseyGame` per visit and owns its focus node:

- it pauses the game, showing the pause menu, when the app goes to the background;
- on dispose it calls `teardown`, which stops the sensor and destroys the native Box2D world. Box2D allows a limited
  number of worlds, so this is required.

The game receives settings as a `GameConfig` value and reports progress through callbacks; it never reads Blocs.

Each level is a single `LevelComponent` under the world, holding terrain, sensors, the goal and the ball:

- **Restart and advance:** replace that component in place. Body components destroy their bodies when removed.
- **Falling:** detected in constant time, by comparing the ball with the level's lowest terrain point.
- **The goal:** plays its flash-and-fade sequence on the camera viewport and then completes the level.

Input writes a `MovementIntent` (horizontal push and jump requests) that the ball reads:

- `TiltInput` exists only in tilt mode on Android, and subscribes to the accelerometer only while mounted.
- `ManualInput` handles the joystick and `A`/`D`/`Space`.
- `applyConfig` swaps the two when the setting changes.

Boosts end on a game-time `Timer` owned by the ball, so they pause with the game and vanish with the level.

## Audio

`AudioService` keeps three low-latency players per effect, used in turn, and one looping music player, through an
`AudioBackend` that tests replace with a fake. It computes volumes from the settings (music, effects, mute) and
preloads into the global `audioplayers` cache that playback reads. The shipped files are made reproducibly by
`tool/audio/process.sh` (see [Development](development.md#audio-assets)).

## Packages

| Package | Kind | Role |
|---|---|---|
| `key_value_store` | Dart | `KeyValueStore` interface and an in-memory implementation |
| `settings_repository` | Dart | `PlayerSettings` with per-field validation and legacy key migration |
| `savegame_repository` | Dart | `SavedGame` list in the stored JSON format; progress never goes back |
| `app_ui` | Flutter | `AppTheme.dark`, `AppColors`, bundled Poppins and its license |

The app's `SharedPreferencesKeyValueStore` uses the legacy `SharedPreferences` API on purpose, so data stored by
earlier versions stays readable on Android.

| Path | Role |
|---|---|
| `lib/app/` | `App`, `AppView`, `router.dart` (`AppRoutes`) |
| `lib/audio/` | `AudioService`, backend, settings listener |
| `lib/game/` | Game, level and ball components, inputs, camera helpers, `GamePage`, pause menu |
| `lib/settings/` | `SettingsCubit` and the settings screen |
| `lib/loading/`, `lib/title/` | Preload screen, menu, savegame and level selectors |
| `lib/shared/` | `SavegameCubit`, storage adapter, shared widgets |
| `lib/l10n/` | ARB files and the `context.l10n` extension; generated code in `lib/l10n/gen/` |
| `lib/gen/` | Asset paths generated by FlutterGen |

The level generator and its difficulty curve are still the baseline ones in `lib/game/levels/`; the next change moves
them into a pure Dart package and rebuilds them for infinite, scaling levels.
