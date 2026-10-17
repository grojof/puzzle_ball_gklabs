import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';

part 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  new() : super(const AudioState()) {
    unawaited(_init());
  }

  final AudioPlayer _musicPlayer = AudioPlayer();
  final List<AudioPlayer> _activeEffects = [];

  Future<void> _init() async {
    await _configureGlobalAudioContext();
    await _initMusicPlayer();
  }

  Future<void> _configureGlobalAudioContext() async {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        // Media volume and routing: speakerphone mode would switch Android to
        // the (much quieter) call volume.
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.game,
          audioFocus: AndroidAudioFocus.none, // ✅ No interrumpe música
        ),
      ),
    );
  }

  Future<void> _initMusicPlayer() async {
    await _musicPlayer.setPlayerMode(PlayerMode.mediaPlayer);
  }

  Future<void> _changeVolume(double volume) async {
    await _musicPlayer.setVolume(volume);
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
        unawaited(effectPlayer.dispose());
      });

      _activeEffects.add(effectPlayer);
    } on Exception catch (e) {
      debugPrint('[AudioCubit] Error al reproducir efecto: $e');
    }
  }

  Future<void> enableAndPlay() async {
    try {
      await _changeVolume(1);
      await _musicPlayer.stop();
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      final bgmPath = Assets.audio.background.replaceFirst('assets/', '');
      await _musicPlayer.setSourceAsset(bgmPath);
      await _musicPlayer.resume();
    } on Exception catch (e, stack) {
      debugPrint('[AudioCubit] Error en enableAndPlay: $e\n$stack');
    }
  }

  Future<void> disable() async {
    await _changeVolume(0);
    await _musicPlayer.pause();
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

  Future<void> setVolume(double volume) => _changeVolume(volume);

  @override
  Future<void> close() async {
    for (final p in _activeEffects) {
      await p.dispose();
    }
    await _musicPlayer.dispose();
    await super.close();
  }
}
