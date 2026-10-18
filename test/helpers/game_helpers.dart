import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/game_config.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// An image cache holding a 1×1 image for every asset the game draws.
Future<Images> testImages() async {
  final images = Images(prefix: '');
  for (final asset in Assets.images.values) {
    images.add(asset.path, await generateImage());
  }
  for (final asset in Assets.images.components.values) {
    images.add(asset.path, await generateImage());
  }
  for (final asset in Assets.images.parallax.values) {
    images.add(asset.path, await generateImage());
  }
  return images;
}

/// Records the sounds the game plays.
class RecordingAudioSink implements AudioSink {
  final List<GameSound> played = [];

  @override
  void play(GameSound sound) => played.add(sound);
}

/// Records the vibration events the game sends.
class RecordingHaptics implements HapticsSink {
  final List<Haptic> played = [];

  @override
  void play(Haptic haptic) => played.add(haptic);
}

/// A flat level: one run of [tiles] tiles at y = 4, the ball above its first
/// tile and the goal near its end; [checkpoints] at the given x positions.
LevelData flatLevel({
  int tiles = 12,
  List<Boost> boosts = const [],
  List<double> checkpoints = const [],
}) {
  const top = 4.0;
  final width = tiles * tileSize;
  return LevelData(
    seed: 'test',
    level: 1,
    ballStart: const Vec2(tileSize / 2, top - 1),
    goal: Vec2(width - tileSize / 2, top - 1.75),
    floors: [
      FloorRun(position: const Vec2(0, top), size: Vec2(width, tileSize)),
    ],
    ramps: const [],
    boosts: boosts,
    checkpoints: [for (final x in checkpoints) Checkpoint(Vec2(x, top))],
    sections: const [],
    estimatedDuration: 10,
  );
}

/// A game on flat levels with recorded audio and a controllable sensor.
BallOdysseyGame testGame({
  required Images images,
  LevelData Function(int level)? levelFor,
  int totalLevels = 3,
  int startLevel = 1,
  GameConfig config = const GameConfig(),
  RecordingAudioSink? audio,
  RecordingHaptics? haptics,
  StreamController<AccelerometerEvent>? sensor,
  void Function(int)? onLevelCompleted,
  void Function()? onSessionCompleted,
}) {
  return BallOdysseyGame(
    levelFor: levelFor ?? (_) => flatLevel(),
    startLevel: startLevel,
    totalLevels: totalLevels,
    audio: audio ?? RecordingAudioSink(),
    haptics: haptics ?? RecordingHaptics(),
    config: config,
    images: images,
    levelLabel: (n) => 'Level $n',
    levelTextStyle: const TextStyle(),
    onLevelCompleted: onLevelCompleted,
    onSessionCompleted: onSessionCompleted,
    accelerometer: sensor == null ? null : () => sensor.stream,
  );
}
