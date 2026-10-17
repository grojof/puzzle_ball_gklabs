import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/audio/audio_backend.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';

class FakeEffect implements EffectPlayer {
  final List<double> plays = [];
  bool disposed = false;

  @override
  Future<void> play(double volume) async => plays.add(volume);

  @override
  Future<void> dispose() async => disposed = true;
}

class FakeMusic implements MusicPlayer {
  @override
  bool isPlaying = false;
  double volume = 1;
  int playCalls = 0;
  bool disposed = false;

  @override
  Future<void> setVolume(double volume) async => this.volume = volume;

  @override
  Future<void> play() async {
    playCalls++;
    isPlaying = true;
  }

  @override
  Future<void> pause() async => isPlaying = false;

  @override
  Future<void> dispose() async => disposed = true;
}

class FakeBackend implements AudioBackend {
  final Map<String, FakeEffect> effects = {};
  final Map<String, int> maxPlayers = {};
  final FakeMusic music = FakeMusic();
  int configured = 0;
  int musicCreated = 0;

  @override
  Future<void> configure() async => configured++;

  @override
  Future<EffectPlayer> createEffect(
    String asset, {
    required int maxPlayers,
  }) async {
    this.maxPlayers[asset] = maxPlayers;
    return effects[asset] = FakeEffect();
  }

  @override
  Future<MusicPlayer> createMusic(String asset) async {
    musicCreated++;
    return music;
  }
}

void main() {
  late FakeBackend backend;
  late AudioService audio;

  setUp(() async {
    backend = FakeBackend();
    audio = AudioService(backend: backend);
    await audio.preload();
  });

  group('preload', () {
    test('creates one pool per effect, bounded, and one music player', () {
      expect(backend.configured, 1);
      expect(backend.effects, hasLength(GameSound.values.length));
      expect(
        backend.maxPlayers.values,
        everyElement(AudioService.maxPlayersPerEffect),
      );
      expect(backend.musicCreated, 1);
    });

    test('is idempotent', () async {
      await audio.preload();
      expect(backend.musicCreated, 1);
    });
  });

  group('effects', () {
    test('rapid plays reuse the same pool', () {
      for (var i = 0; i < 100; i++) {
        audio.play(GameSound.jump);
      }

      expect(backend.effects[GameSound.jump.asset]!.plays, hasLength(100));
      expect(backend.effects, hasLength(GameSound.values.length));
    });

    test('play at the effects volume and stay silent when muted', () async {
      await audio.applySettings(
        musicVolume: 1,
        effectsVolume: 0.5,
        muted: false,
      );
      audio.play(GameSound.boostSpeed);
      await audio.applySettings(
        musicVolume: 1,
        effectsVolume: 0.5,
        muted: true,
      );
      audio.play(GameSound.boostSpeed);

      expect(backend.effects[GameSound.boostSpeed.asset]!.plays, [0.5]);
    });
  });

  group('music', () {
    test('starts only when asked, at the music volume', () async {
      await audio.applySettings(
        musicVolume: 0.3,
        effectsVolume: 1,
        muted: false,
      );
      expect(backend.music.isPlaying, isFalse);

      await audio.startMusic();

      expect(backend.music.isPlaying, isTrue);
      expect(backend.music.volume, 0.3);
    });

    test('a muted start stays silent until unmuted', () async {
      await audio.applySettings(musicVolume: 1, effectsVolume: 1, muted: true);
      await audio.startMusic();
      expect(backend.music.isPlaying, isFalse);

      await audio.applySettings(musicVolume: 1, effectsVolume: 1, muted: false);
      expect(backend.music.isPlaying, isTrue);
      expect(backend.music.volume, 1);
    });

    test('zero volume pauses the music', () async {
      await audio.startMusic();
      await audio.applySettings(musicVolume: 0, effectsVolume: 1, muted: false);

      expect(backend.music.isPlaying, isFalse);
    });

    test('pauses in the background and resumes on return', () async {
      await audio.startMusic();

      await audio.pause();
      expect(backend.music.isPlaying, isFalse);

      await audio.resume();
      expect(backend.music.isPlaying, isTrue);
    });

    test('unlock retries playback after the first interaction', () async {
      await audio.startMusic();
      final calls = backend.music.playCalls;

      await audio.unlock();

      expect(backend.music.playCalls, calls + 1);
    });

    test('does nothing before preload', () async {
      final idle = AudioService(backend: FakeBackend());
      await idle.startMusic();
      await idle.unlock();
      idle.play(GameSound.jump);
    });
  });

  test('dispose releases every player', () async {
    await audio.dispose();

    expect(backend.effects.values.every((e) => e.disposed), isTrue);
    expect(backend.music.disposed, isTrue);
  });
}
