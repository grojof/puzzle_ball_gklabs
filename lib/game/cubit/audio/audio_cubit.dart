import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';
import 'package:flame_audio/bgm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';

part 'audio_state.dart';

class AudioCubit extends Cubit<AudioState> {
  AudioCubit({required AudioCache audioCache})
      : effectPlayer = AudioPlayer()..audioCache = audioCache,
        bgm = Bgm(audioCache: audioCache),
        super(const AudioState());

  @visibleForTesting
  AudioCubit.test({
    required this.effectPlayer,
    required this.bgm,
    double volume = 1.0,
  }) : super(AudioState(volume: volume));

  final AudioPlayer effectPlayer;
  final Bgm bgm;

  Future<void> _changeVolume(double volume) async {
    await effectPlayer.setVolume(volume);
    await bgm.audioPlayer.setVolume(volume);
    emit(state.copyWith(volume: volume));
  }

  Future<void> toggleVolume() async {
    final newVolume = state.volume == 0 ? 1.0 : 0.0;
    await _changeVolume(newVolume);

    if (newVolume > 0 && bgm.audioPlayer.state != PlayerState.playing) {
      await bgm.play(Assets.audio.background);
    } else if (newVolume == 0) {
      await bgm.pause();
    }
  }

  Future<void> setVolume(double volume) async {
    await _changeVolume(volume);
  }

  Future<void> enableAndPlay() async {
    await _changeVolume(1);

    if (bgm.audioPlayer.state == PlayerState.playing) {
      await bgm.stop();
    }

    await bgm.play(Assets.audio.background);
  }

  Future<void> disable() async {
    await _changeVolume(0);
    await bgm.pause();
  }

  @override
  Future<void> close() {
    effectPlayer.dispose();
    bgm.dispose();
    return super.close();
  }
}
