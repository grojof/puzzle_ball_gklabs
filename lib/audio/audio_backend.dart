import 'package:audioplayers/audioplayers.dart';

/// A pooled sound effect.
abstract interface class EffectPlayer {
  Future<void> play(double volume);
  Future<void> dispose();
}

/// The looping background music.
abstract interface class MusicPlayer {
  bool get isPlaying;
  Future<void> setVolume(double volume);
  Future<void> play();
  Future<void> pause();
  Future<void> dispose();
}

/// Creates the platform players; swapped for a fake in tests.
abstract interface class AudioBackend {
  /// Sets the platform audio session up once, before any player is created.
  Future<void> configure();
  Future<EffectPlayer> createEffect(String asset, {required int maxPlayers});
  Future<MusicPlayer> createMusic(String asset);
}

/// [AudioBackend] on `audioplayers`, sharing its global asset cache.
class AudioplayersBackend implements AudioBackend {
  @override
  Future<void> configure() => AudioPlayer.global.setAudioContext(
    AudioContext(
      // Media volume and routing: speakerphone mode would switch Android to
      // the much quieter call volume. No focus request, so the game does not
      // stop music the player is listening to elsewhere.
      android: const AudioContextAndroid(
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
    ),
  );

  @override
  Future<EffectPlayer> createEffect(
    String asset, {
    required int maxPlayers,
  }) async {
    final players = <AudioPlayer>[];
    for (var i = 0; i < maxPlayers; i++) {
      final player = AudioPlayer();
      await player.setPlayerMode(PlayerMode.lowLatency);
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setSource(AssetSource(_relative(asset)));
      players.add(player);
    }
    return _RoundRobinEffect(players);
  }

  @override
  Future<MusicPlayer> createMusic(String asset) async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setSource(AssetSource(_relative(asset)));
    return _LoopingMusic(player);
  }

  /// Asset sources are relative to the cache prefix, `assets/`.
  static String _relative(String asset) => asset.replaceFirst('assets/', '');
}

/// A fixed set of players for one effect, used in turn.
///
/// Not `AudioPool`: it returns a player only when playback reports completion,
/// which low-latency (SoundPool) players never do on Android, so every play
/// created a new player that was never released. Stopping before each play
/// also matters: SoundPool otherwise resumes the finished stream silently.
class _RoundRobinEffect implements EffectPlayer {
  new(this._players);

  final List<AudioPlayer> _players;
  int _next = 0;

  @override
  Future<void> play(double volume) async {
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    await player.stop();
    await player.setVolume(volume);
    await player.resume();
  }

  @override
  Future<void> dispose() async {
    for (final player in _players) {
      await player.dispose();
    }
  }
}

class _LoopingMusic implements MusicPlayer {
  new(this._player);

  final AudioPlayer _player;

  @override
  bool get isPlaying => _player.state == PlayerState.playing;

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> play() => _player.resume();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> dispose() => _player.dispose();
}
