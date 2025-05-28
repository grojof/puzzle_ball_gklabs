import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';

part 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  AudioCubit({required AudioCache audioCache})
      : _audioCache = audioCache,
        super(const AudioState()) {
    _configureGlobalAudioContext();
    _initMusicPlayer();
  }

  final AudioCache _audioCache;
  final AudioPlayer musicPlayer = AudioPlayer();
  final List<AudioPlayer> _activeEffects = [];

  void _configureGlobalAudioContext() {
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, // ✅ No interrumpe música
        ),
      ),
    );
  }

  Future<void> _initMusicPlayer() async {
    await musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
  }

  Future<void> _changeVolume(double volume) async {
    await musicPlayer.setVolume(volume);
    for (final p in _activeEffects) {
      await p.setVolume(volume);
    }
    emit(state.copyWith(volume: volume));
  }

  Future<void> playEffect(String assetPath) async {
    try {
      final effectPlayer = AudioPlayer();
      await effectPlayer.setPlayerMode(PlayerMode.lowLatency);
      await effectPlayer.setVolume(state.volume);

      final path = assetPath.replaceFirst('assets/', '');
      await effectPlayer.play(AssetSource(path));

      effectPlayer.onPlayerComplete.listen((_) {
        _activeEffects.remove(effectPlayer);
        effectPlayer.dispose();
      });

      _activeEffects.add(effectPlayer);
    } catch (e) {
      debugPrint('[AudioCubit] Error al reproducir efecto: $e');
    }
  }

  Future<void> enableAndPlay() async {
    try {
      await _changeVolume(1);
      await musicPlayer.stop();
      await musicPlayer.setReleaseMode(ReleaseMode.loop);
      final bgmPath = Assets.audio.background.replaceFirst('assets/', '');
      await musicPlayer.setSourceAsset(bgmPath);
      await musicPlayer.resume();
    } catch (e, stack) {
      debugPrint('[AudioCubit] Error en enableAndPlay: $e\n$stack');
    }
  }

  Future<void> disable() async {
    await _changeVolume(0);
    await musicPlayer.pause();
  }

  Future<void> toggleVolume() async {
    final newVolume = state.volume == 0 ? 1.0 : 0.0;
    await _changeVolume(newVolume);
    if (newVolume > 0) {
      await enableAndPlay();
    } else {
      await disable();
    }
  }

  Future<void> setVolume(double volume) async => _changeVolume(volume);

  @override
  Future<void> close() async {
    for (final p in _activeEffects) {
      await p.dispose();
    }
    await musicPlayer.dispose();
    return super.close();
  }
}
