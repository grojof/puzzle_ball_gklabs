import 'dart:async';

import 'package:puzzle_ball_gklabs/audio/audio_backend.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';

/// The sounds the game plays.
enum GameSound {
  jump,
  boostJump,
  boostSpeed,
  boostGravity;

  String get asset => switch (this) {
    jump => Assets.audio.jump,
    boostJump => Assets.audio.boostJump,
    boostSpeed => Assets.audio.boostSpeed,
    boostGravity => Assets.audio.boostGravity,
  };
}

/// Where the game sends its sounds; the game knows nothing else about audio.
abstract interface class AudioSink {
  void play(GameSound sound);
}

/// Background music and sound effects (game-audio spec).
///
/// A fixed set of players per effect and a single looping music player, so
/// audio never creates players per sound. Volumes come from the player
/// settings; muting keeps them.
class AudioService implements AudioSink {
  new({AudioBackend? backend}) : _backend = backend ?? AudioplayersBackend();

  /// Players each effect keeps, used in turn, so rapid repeats overlap.
  static const maxPlayersPerEffect = 3;

  final AudioBackend _backend;
  final Map<GameSound, EffectPlayer> _effects = {};
  MusicPlayer? _music;

  double _musicVolume = 1;
  double _effectsVolume = 1;
  bool _muted = false;

  /// Whether the music should be audible: started, not paused by the app
  /// lifecycle and with a volume above zero.
  bool _musicStarted = false;
  bool _inBackground = false;

  double get _effectiveMusicVolume => _muted ? 0 : _musicVolume;
  double get _effectiveEffectsVolume => _muted ? 0 : _effectsVolume;

  /// Loads every sound into the cache that playback reads from.
  Future<void> preload() async {
    await _backend.configure();
    for (final sound in GameSound.values) {
      _effects[sound] ??= await _backend.createEffect(
        sound.asset,
        maxPlayers: maxPlayersPerEffect,
      );
    }
    _music ??= await _backend.createMusic(Assets.audio.background);
  }

  /// Applies the player's volumes and mute state immediately.
  Future<void> applySettings({
    required double musicVolume,
    required double effectsVolume,
    required bool muted,
  }) async {
    _musicVolume = musicVolume;
    _effectsVolume = effectsVolume;
    _muted = muted;
    await _syncMusic();
  }

  /// Starts the background music once settings and assets are ready.
  Future<void> startMusic() async {
    _musicStarted = true;
    await _syncMusic();
  }

  /// Retries the music after the first user interaction on the web, where
  /// browsers block audio until then.
  Future<void> unlock() => _syncMusic(force: true);

  /// The app went to the background.
  Future<void> pause() async {
    _inBackground = true;
    await _music?.pause();
  }

  /// The app returned to the foreground.
  Future<void> resume() async {
    _inBackground = false;
    await _syncMusic();
  }

  @override
  void play(GameSound sound) {
    final volume = _effectiveEffectsVolume;
    if (volume == 0) return;
    unawaited(_effects[sound]?.play(volume));
  }

  Future<void> dispose() async {
    for (final effect in _effects.values) {
      await effect.dispose();
    }
    _effects.clear();
    await _music?.dispose();
    _music = null;
  }

  Future<void> _syncMusic({bool force = false}) async {
    final music = _music;
    if (music == null) return;
    final volume = _effectiveMusicVolume;
    await music.setVolume(volume);
    final audible = _musicStarted && !_inBackground && volume > 0;
    if (!audible) {
      await music.pause();
    } else if (force || !music.isPlaying) {
      await music.play();
    }
  }
}
