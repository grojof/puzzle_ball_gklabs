import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';

/// Everything one level is made of, under a single root, so unloading the
/// level is removing this component (design D1).
///
/// It detects falls in constant time from the level's lowest terrain point
/// (design D3) and plays the goal sequence.
class LevelComponent extends Component with HasGameReference<Forge2DGame> {
  new({
    required this.data,
    required this.intent,
    required this.audio,
    required this.onFell,
    required this.onCompleted,
  }) : fallLine = lowestTerrainPoint(data) + fallMargin;

  /// How far below the lowest terrain the ball counts as fallen, in meters.
  static const fallMargin = 10.0;

  static const ballRadius = 0.2;

  final LevelData data;
  final MovementIntent intent;
  final AudioSink audio;

  /// The ball fell below [fallLine].
  final VoidCallback onFell;

  /// The goal sequence finished.
  final VoidCallback onCompleted;

  /// World y (downwards) past which the ball has fallen out of the level.
  final double fallLine;

  late final BallComponent ball;
  final List<Component> _overlays = [];
  bool _fell = false;

  /// The bottom of the lowest floor or ramp, in world y (downwards).
  static double lowestTerrainPoint(LevelData data) {
    var lowest = data.ballStart.y;
    for (final floor in data.floorData) {
      lowest = math.max(lowest, floor.position.y + floor.size.y);
    }
    for (final ramp in data.rampData) {
      lowest = math.max(lowest, ramp.position.y + ramp.size.y);
    }
    return lowest;
  }

  @override
  Future<void> onLoad() async {
    final images = game.images;
    Sprite sprite(String path) => Sprite(images.fromCache(path));
    final components = Assets.images.components;
    final floor = sprite(components.floor.path);

    ball = BallComponent(
      intent: intent,
      audio: audio,
      initialPosition: data.ballStart,
      radius: ballRadius,
      onGoalReached: _onGoalReached,
      textureImage: images.fromCache(components.ball.path),
    );

    await addAll([
      for (final f in data.floorData)
        FloorComponent(position: f.position, size: f.size, sprite: floor),
      for (final r in data.rampData)
        RampComponent(
          position: r.position,
          size: r.size,
          inverted: r.inverted,
          sprite: floor,
        ),
      for (final c in data.checkpointData)
        CheckPointComponent(position: c.position, size: Vector2.all(0.5)),
      for (final b in data.boostData)
        switch (b.type) {
          BoostType.jump => JumpBoostComponent(
            position: b.position,
            size: Vector2.all(1),
            sprite: sprite(components.jumpBoost.path),
          ),
          BoostType.speed => SpeedBoostComponent(
            position: b.position,
            size: Vector2.all(1),
            sprite: sprite(components.speedBoost.path),
          ),
          BoostType.gravity => GravityBoostComponent(
            position: b.position,
            size: Vector2.all(1),
            sprite: sprite(components.gravityBoost.path),
          ),
        },
      GoalComponent(
        position: data.goalPosition,
        size: Vector2(1, 3.5),
        sprite: sprite(components.goal.path),
      ),
      ball,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_fell && ball.isMounted && ball.body.position.y > fallLine) {
      _fell = true;
      onFell();
    }
  }

  void _onGoalReached() {
    // Contacts are reported after the physics step, so the body can change.
    ball.freeze();
    unawaited(_playGoalSequence());
  }

  /// Flashes blue, fades to black and then reports the level as completed.
  Future<void> _playGoalSequence() async {
    final viewport = game.camera.viewport;
    final flash = SequenceEffect([
      OpacityEffect.to(
        0.6,
        EffectController(duration: 0.4, curve: Curves.easeOut),
      ),
      OpacityEffect.to(
        0,
        EffectController(duration: 0.4, curve: Curves.easeIn),
      ),
    ]);
    final flashOverlay = _overlay(const Color(0xFF42A5F5), flash);
    await viewport.add(flashOverlay);
    await flash.completed;
    flashOverlay.removeFromParent();

    final fade = OpacityEffect.to(
      1,
      EffectController(duration: 0.4, curve: Curves.easeIn),
    );
    await viewport.add(_overlay(const Color(0xFF000000), fade));
    await fade.completed;
    if (isMounted) onCompleted();
  }

  RectangleComponent _overlay(Color color, Effect effect) {
    final overlay = RectangleComponent(
      size: game.size,
      paint: Paint()..color = color.withValues(alpha: 0),
      children: [effect],
      priority: 1000,
    );
    _overlays.add(overlay);
    return overlay;
  }

  @override
  void onRemove() {
    // Overlays live in the viewport, outside this subtree.
    for (final overlay in _overlays) {
      overlay.removeFromParent();
    }
    _overlays.clear();
    super.onRemove();
  }
}
