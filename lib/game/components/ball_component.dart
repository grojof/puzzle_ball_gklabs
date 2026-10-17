import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/floor_component.dart';
import 'package:puzzle_ball_gklabs/game/components/goal_component.dart';
import 'package:puzzle_ball_gklabs/game/components/ramp_component.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';

/// The player's ball: moves and jumps from the [MovementIntent], takes
/// boosts, and reports reaching the goal.
///
/// Boosts end on a game-time [Timer] owned by the ball, so they pause with the
/// game and disappear with the level (design D3).
class BallComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.intent,
    required this.audio,
    required this.initialPosition,
    required this.radius,
    required this.onGoalReached,
    this.textureImage,
  });

  static const density = 50.0;
  static const linearDamping = 1.5;

  /// Force for a full push.
  static const moveForce = 80.0;

  /// Upward impulse of a jump.
  static const jumpImpulse = 80.0;

  /// How long after leaving the ground a jump still works (player-controls).
  static const coyoteTime = 0.15;

  /// How long a boost lasts and blocks other boosts.
  static const boostDuration = 2.0;

  final MovementIntent intent;
  final AudioSink audio;
  final Vector2 initialPosition;
  final double radius;
  final VoidCallback onGoalReached;
  final Image? textureImage;

  int _groundContacts = 0;
  double _sinceGround = double.infinity;
  late final Timer _boostTimer = Timer(
    boostDuration,
    onTick: _endBoost,
    autoStart: false,
  );
  bool _reachedGoal = false;

  bool get isOnGround => _groundContacts > 0;

  /// Whether a boost is running.
  bool get isBoosted => _boostTimer.isRunning();

  @override
  Body createBody() {
    return world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: initialPosition,
        linearDamping: linearDamping,
      ),
    )..createShape(
      Circle(radius: radius),
      ShapeDef(
        density: density,
        // Friction: SurfaceMaterial's default, 0.6.
        enableContactEvents: true,
        enableSensorEvents: true,
        userData: this,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _boostTimer.update(dt);
    if (_reachedGoal) return;
    _sinceGround = isOnGround ? 0 : _sinceGround + dt;
    if (intent.horizontal != 0) {
      body.applyForce(Vector2(intent.horizontal * moveForce, 0));
    }
    if (intent.consumeJump() && _sinceGround <= coyoteTime) {
      body.applyLinearImpulse(Vector2(0, -jumpImpulse));
      _sinceGround = double.infinity;
      audio.play(GameSound.jump);
    }
  }

  void applyJumpBoost(double impulse) {
    if (!_startBoost(GameSound.boostJump)) return;
    body.applyLinearImpulse(Vector2(0, -impulse));
  }

  void applySpeedBoost(double impulse, Vector2 direction) {
    if (!_startBoost(GameSound.boostSpeed)) return;
    body.applyLinearImpulse(direction.normalized() * impulse);
  }

  void applyGravityBoost(double gravityScale) {
    if (!_startBoost(GameSound.boostGravity)) return;
    body.gravityScale = gravityScale;
  }

  /// Starts a boost unless one is running; it ends after [boostDuration].
  bool _startBoost(GameSound sound) {
    if (isBoosted) return false;
    audio.play(sound);
    _boostTimer.start();
    return true;
  }

  void _endBoost() {
    if (body.isValid) body.gravityScale = 1;
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is FloorComponent || other is RampComponent) {
      _groundContacts++;
    } else if (other is GoalComponent && !_reachedGoal) {
      _reachedGoal = true;
      onGoalReached();
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    if ((other is FloorComponent || other is RampComponent) &&
        _groundContacts > 0) {
      _groundContacts--;
    }
  }

  /// Freezes the ball once the goal sequence starts.
  void freeze() {
    body
      ..linearVelocity = Vector2.zero()
      ..isEnabled = false;
  }

  @override
  void render(Canvas canvas) {
    final scale = _depthScale(body.position.y);
    canvas
      ..save()
      ..scale(scale, scale);
    final texture = textureImage;
    final dst = Rect.fromCircle(center: Offset.zero, radius: radius);
    if (texture != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        texture.width.toDouble(),
        texture.height.toDouble(),
      );
      canvas
        ..save()
        ..clipPath(Path()..addOval(dst))
        ..drawImageRect(texture, src, dst, Paint())
        ..restore();
    } else {
      final gradient = Paint()
        ..shader = RadialGradient(
          colors: [paint.color, paint.color.withAlpha(180)],
          center: Alignment.topLeft,
          radius: 0.9,
        ).createShader(dst);
      canvas.drawCircle(Offset.zero, radius, gradient);
    }
    canvas.restore();
  }

  static double _depthScale(double y) => 0.6 + (y.clamp(0, 600) / 600) * 0.4;
}
