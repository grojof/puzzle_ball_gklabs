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
import 'package:puzzle_ball_gklabs/game/visuals/terrain_paint.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';

/// Everything one level is made of, under a single root, so unloading the
/// level is removing this component (design D1).
///
/// It detects falls in constant time from the level's lowest terrain point,
/// sends the ball back after a fall or spikes, restoring the course, and
/// plays the goal sequence.
class LevelComponent extends Component with HasGameReference<Forge2DGame> {
  new({
    required this.data,
    required this.intent,
    required this.audio,
    required this.haptics,
    required this.terrain,
    required this.onFell,
    required this.onCompleted,
    this.onRespawned,
    this.onPickup,
  }) : fallLine = data.lowestPoint + fallMargin;

  /// How far below the lowest terrain the ball counts as fallen, in meters.
  static const fallMargin = 10.0;

  static const ballRadius = 0.2;

  final LevelData data;
  final MovementIntent intent;
  final AudioSink audio;
  final HapticsSink haptics;

  /// The world's terrain paints.
  final TerrainPaint terrain;

  /// The ball fell below [fallLine] with no active checkpoint.
  final VoidCallback onFell;

  /// The goal sequence finished.
  final VoidCallback onCompleted;

  /// The ball respawned at a checkpoint.
  final VoidCallback? onRespawned;

  /// The ball collected an orb or reached a checkpoint (game-hud spec).
  final void Function(HudMessage message)? onPickup;

  /// World y (downwards) past which the ball has fallen out of the level.
  final double fallLine;

  late final BallComponent ball;
  late final List<CheckPointComponent> _checkpoints;
  final List<Component> _overlays = [];
  CheckPointComponent? _activeCheckpoint;
  bool _fell = false;
  bool _sendBack = false;

  /// Whether each checkpoint, in course order, has been reached.
  List<bool> get checkpointsReached => isLoaded
      ? [for (final checkpoint in _checkpoints) checkpoint.isActivated]
      : const [];

  /// Whether the ball holds a double-jump charge.
  bool get hasAirJump => isLoaded && ball.hasAirJump;

  /// The last checkpoint the ball passed, if any.
  CheckPointComponent? get activeCheckpoint => _activeCheckpoint;

  static Vector2 _vector(Vec2 v) => Vector2(v.x, v.y);

  @override
  Future<void> onLoad() async {
    final images = game.images;
    final components = Assets.images.components;

    ball = BallComponent(
      intent: intent,
      audio: audio,
      haptics: haptics,
      initialPosition: _vector(data.ballStart),
      radius: ballRadius,
      onGoalReached: _onGoalReached,
      textureImage: images.fromCache(components.ball.path),
    );

    _checkpoints = [
      for (final checkpoint in data.checkpoints)
        CheckPointComponent(
          ground: _vector(checkpoint.position),
          onActivated: (component) {
            _activeCheckpoint = component;
            haptics.play(Haptic.checkpoint);
            onPickup?.call(HudMessage.checkpoint);
          },
        ),
    ];
    await addAll([
      for (final run in data.floors)
        if (run.crumbling)
          CrumblingPlatformComponent(
            position: _vector(run.position),
            size: _vector(run.size),
            terrain: terrain,
          )
        else
          FloorComponent(
            position: _vector(run.position),
            size: _vector(run.size),
            terrain: terrain,
          ),
      for (final platform in data.platforms)
        MovingPlatformComponent(
          start: _vector(platform.start),
          end: _vector(platform.end),
          size: _vector(platform.size),
          speed: platform.speed,
          pause: platform.pause,
        ),
      for (final strip in data.hazards)
        SpikeComponent(
          left: strip.left,
          ground: strip.top,
          width: strip.width,
          onTouched: () => _sendBack = true,
        ),
      for (final ramp in data.ramps)
        RampComponent(
          position: _vector(ramp.position),
          size: _vector(ramp.size),
          // A ramp component "inverted" is high on its left.
          inverted: !ramp.ascending,
          terrain: terrain,
        ),
      ..._checkpoints,
      for (final boost in data.boosts)
        BoostComponent(
          type: boost.type,
          position: _vector(boost.position),
          onCollected: () => onPickup?.call(HudMessage.doubleJump),
        ),
      GoalComponent(position: _vector(data.goal), size: Vector2(1, 3.5)),
      ball,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_fell || !ball.isMounted) return;
    if (_sendBack || ball.body.position.y > fallLine) sendBack();
  }

  /// Sends the ball back after a fall or spikes: it respawns at the last
  /// active checkpoint with the course restored, or the level restarts
  /// when none is active (level-mechanics spec).
  void sendBack() {
    _sendBack = false;
    final checkpoint = _activeCheckpoint;
    if (checkpoint != null) {
      ball.respawn(checkpoint.respawnPoint);
      intent.reset();
      for (final child in children) {
        if (child is CrumblingPlatformComponent) child.restore();
        if (child is BoostComponent) child.restore();
      }
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
