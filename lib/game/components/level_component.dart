import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';

/// Everything one level is made of, under a single root, so unloading the
/// level is removing this component (design D1).
///
/// It detects falls in constant time from the level's lowest terrain point,
/// respawns the ball at the last active checkpoint, and plays the goal
/// sequence.
class LevelComponent extends Component with HasGameReference<Forge2DGame> {
  new({
    required this.data,
    required this.intent,
    required this.audio,
    required this.haptics,
    required this.onFell,
    required this.onCompleted,
    this.onRespawned,
  }) : fallLine = data.lowestPoint + fallMargin;

  /// How far below the lowest terrain the ball counts as fallen, in meters.
  static const fallMargin = 10.0;

  static const ballRadius = 0.2;

  final LevelData data;
  final MovementIntent intent;
  final AudioSink audio;
  final HapticsSink haptics;

  /// The ball fell below [fallLine] with no active checkpoint.
  final VoidCallback onFell;

  /// The goal sequence finished.
  final VoidCallback onCompleted;

  /// The ball respawned at a checkpoint.
  final VoidCallback? onRespawned;

  /// World y (downwards) past which the ball has fallen out of the level.
  final double fallLine;

  late final BallComponent ball;
  final List<Component> _overlays = [];
  CheckPointComponent? _activeCheckpoint;
  bool _fell = false;

  /// The last checkpoint the ball passed, if any.
  CheckPointComponent? get activeCheckpoint => _activeCheckpoint;

  static Vector2 _vector(Vec2 v) => Vector2(v.x, v.y);

  @override
  Future<void> onLoad() async {
    final images = game.images;
    Sprite sprite(String path) => Sprite(images.fromCache(path));
    final components = Assets.images.components;
    final floor = sprite(components.floor.path);

    ball = BallComponent(
      intent: intent,
      audio: audio,
      haptics: haptics,
      initialPosition: _vector(data.ballStart),
      radius: ballRadius,
      onGoalReached: _onGoalReached,
      textureImage: images.fromCache(components.ball.path),
    );

    await addAll([
      for (final run in data.floors)
        FloorComponent(
          position: _vector(run.position),
          size: _vector(run.size),
          sprite: floor,
        ),
      for (final ramp in data.ramps)
        RampComponent(
          position: _vector(ramp.position),
          size: _vector(ramp.size),
          // A ramp component "inverted" is high on its left.
          inverted: !ramp.ascending,
          sprite: floor,
        ),
      for (final checkpoint in data.checkpoints)
        CheckPointComponent(
          ground: _vector(checkpoint.position),
          onActivated: (component) {
            _activeCheckpoint = component;
            haptics.play(Haptic.checkpoint);
          },
        ),
      for (final boost in data.boosts) _boost(boost, sprite),
      GoalComponent(
        position: _vector(data.goal),
        size: Vector2(1, 3.5),
        sprite: sprite(components.goal.path),
      ),
      ball,
    ]);
  }

  static Component _boost(Boost boost, Sprite Function(String) sprite) {
    final components = Assets.images.components;
    final position = _vector(boost.position);
    final size = Vector2.all(1);
    return switch (boost.type) {
      BoostType.jump => JumpBoostComponent(
        position: position,
        size: size,
        sprite: sprite(components.jumpBoost.path),
      ),
      BoostType.speed => SpeedBoostComponent(
        position: position,
        size: size,
        sprite: sprite(components.speedBoost.path),
      ),
      BoostType.gravity => GravityBoostComponent(
        position: position,
        size: size,
        sprite: sprite(components.gravityBoost.path),
      ),
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_fell || !ball.isMounted || ball.body.position.y <= fallLine) return;
    final checkpoint = _activeCheckpoint;
    if (checkpoint != null) {
      ball.respawn(checkpoint.respawnPoint);
      intent.reset();
      onRespawned?.call();
      return;
    }
    _fell = true;
    onFell();
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
