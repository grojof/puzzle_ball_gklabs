# Proposal

## Why

Long play sessions slow the game down. Measured on 2026-10-17 (Android 16 emulator, debug build), every level load
leaks about 5 MB: memory grows from 393 MB to 545 MB over 30 loads, with no plateau. Every fall and every completed
level rebuilds the whole game through a route change, and the Box2D v3 world, the accelerometer subscription and
the boost timers outlive it. Box2D v3 also allows only a limited number of simultaneous physics worlds (128 by
default), and nothing frees them, so the current build crashes after roughly 128 level loads, falls included. Audio
also works poorly:

- the music only starts after toggling sound off and on;
- every effect creates a new native player;
- loudness differs by about 25 dB between effects;
- there is no way to adjust music and effects separately.

This has to be fixed before the level generator is rebuilt, because the generator work needs a stable game loop that
can be played for a long time.

## What Changes

- **Game session runtime**
  - One game instance lives for a whole play session.
  - Restarting after a fall and moving to the next level happen in place: the world is reset and the route does not
    change.
  - The physics world, subscriptions and timers are released when they are no longer used.
  - The router is created once, so changing the language does not restart navigation.
- **Game boundary**
  - The game receives settings as plain values and reports events (level completed, fell) through callbacks.
  - It no longer reads Blocs from `game.buildContext`.
  - Timers run on game time instead of `Future.delayed`.
  - Falling is detected without scanning every body each frame.
- **Controls**
  - The accelerometer is read only in tilt mode.
  - Tilt keeps its proportional response with a dead zone.
  - Joystick and keyboard behave as today.
- **Audio**
  - An audio service with one reusable player per effect, one looping music player, and separate music and effects
    volumes.
  - Music starts on launch when sound is enabled (on the web, at the first user interaction) and pauses while the app
    is in the background.
  - Effects are loudness-normalized, and the background track is re-encoded smaller.
  - Audio is preloaded into the cache that playback actually uses.
- **Settings**
  - A settings screen with music volume, effects volume, control mode and language, reachable from the title screen
    and from a new in-game pause menu.
  - The quick sound toggle stays as a mute that remembers the volumes.
- **Packages (ADR-0005)**
  - `key_value_store`: a tiny pure Dart interface with an in-memory implementation for tests. The
    `shared_preferences` adapter lives in the app.
  - `settings_repository` and `savegame_repository`: pure Dart, built on `key_value_store`.
  - `app_ui`: theme and bundled Poppins, replacing the runtime download through `google_fonts`.
  - Existing savegames and settings keep working: same storage keys and format.
- **Removals:** dead camera helpers and unused settings fields (`currentLevel` in settings, which savegames
  superseded).

## Capabilities

### New Capabilities

- `game-session`: the lifecycle of a play session: one game instance, in-place restart and level advance, resource
  release, stable memory over long sessions.
- `game-audio`: music and sound-effect playback: start, mute, separate volumes, app lifecycle, consistent loudness.
- `player-settings`: the player's persisted preferences (music volume, effects volume, control mode, language) and the
  settings screen that edits them.
- `player-controls`: how tilt, the on-screen joystick, the jump button and the keyboard move the ball, and when each
  input is active.

### Modified Capabilities

None. The project has no specs yet.

## Impact

- **Code:**
  - `lib/game/`: game class, ball and boost components, camera helpers, game page.
  - `lib/app/`: router and providers.
  - `lib/shared/`: settings and savegame Cubits, theme, sound toggle, control and language selectors.
  - `lib/title/`: title screen entry to settings.
  - New `lib/settings/` feature folder.
- **New packages:** `packages/key_value_store`, `packages/settings_repository`, `packages/savegame_repository` and
  `packages/app_ui`, each with its own CI job filtered by path.
- **Dependencies:**
  - `google_fonts` is removed; the Poppins font files (SIL OFL) are bundled in `app_ui`.
  - `shared_preferences` stays in the app only, behind the adapter.
  - No new third-party packages are expected.
- **Assets:** `assets/audio/*` re-encoded (normalized effects, smaller background track).
- **Data:** stored savegames (`savedGames`) and settings keys stay compatible. The new keys are `musicVolume` and
  `effectsVolume`, and the obsolete `currentLevel` key is ignored.
- **Out of scope:** level generator, difficulty curve, the infinite progression model, and physics tuning. Those are the
  next change.
