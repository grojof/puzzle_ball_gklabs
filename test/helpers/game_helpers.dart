import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/game_config.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
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

/// A flat level: [tiles] floor tiles at y = 4, the ball above the first one
/// and the goal far to the right.
LevelData flatLevel({int tiles = 6, List<BoostData> boosts = const []}) {
  const tile = 1.5;
  return LevelData(
    ballStart: Vector2(tile / 2, 4 - tile),
    goalPosition: Vector2(tile * (tiles + 4), 4 - tile),
    floorData: [
      for (var i = 0; i < tiles; i++)
        FloorData(position: Vector2(i * tile, 4), size: Vector2.all(tile)),
    ],
    rampData: const [],
    boostData: boosts,
    checkpointData: const [],
  );
}

/// A game on flat levels with recorded audio and a controllable sensor.
BallOdysseyGame testGame({
  required Images images,
  int totalLevels = 3,
  int startLevel = 1,
  GameConfig config = const GameConfig(),
  RecordingAudioSink? audio,
  StreamController<AccelerometerEvent>? sensor,
  void Function(int)? onLevelCompleted,
  void Function()? onSessionCompleted,
}) {
  return BallOdysseyGame(
    levelFor: (_) => flatLevel(),
    startLevel: startLevel,
    totalLevels: totalLevels,
    audio: audio ?? RecordingAudioSink(),
    config: config,
    images: images,
    levelLabel: (n) => 'Level $n',
    levelTextStyle: const TextStyle(),
    onLevelCompleted: onLevelCompleted,
    onSessionCompleted: onSessionCompleted,
    accelerometer: sensor == null ? null : () => sensor.stream,
  );
}
