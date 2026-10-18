import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/goal_component.dart';
import 'package:puzzle_ball_gklabs/game/components/ground_surface.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';

/// The player's ball: moves and jumps from the [MovementIntent], takes
/// boosts, and reports reaching the goal.
///
/// Boosts end on a game-time [Timer] owned by the ball, so they pause with the
/// game and disappear with the level (design D3).
class BallComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.intent,
    required this.audio,
    required this.haptics,
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

  /// After a jump, how long the ground is ignored: the contact lingers for a
  /// frame or two after take-off, which would allow a second jump.
  static const jumpLockout = 0.25;

  /// How long a boost lasts.
  static const boostDuration = 2.0;

  final MovementIntent intent;
  final AudioSink audio;
  final HapticsSink haptics;
  final Vector2 initialPosition;
  final double radius;
  final VoidCallback onGoalReached;
  final Image? textureImage;

  /// The floors and ramps the ball touches.
  final Set<GroundSurface> _touching = {};
  double _sinceGround = double.infinity;
  double _sinceJump = double.infinity;
  late final Timer _boostTimer = Timer(
    boostDuration,
    onTick: _endBoost,
    autoStart: false,
  );
  bool _reachedGoal = false;

  /// Whether the ball rests on the top of a floor or a ramp: it touches one
  /// and its center is above that surface. Touching the side of a ledge does
  /// not count (player-controls spec), and a contact that began on a corner
  /// counts once the ball is on top.
  bool get isOnGround {
    if (_touching.isEmpty || !isMounted) return false;
    final center = body.position;
    return _touching.any((surface) => surface.supports(center));
  }

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
    _sinceJump += dt;
    final grounded = isOnGround && _sinceJump > jumpLockout;
    _sinceGround = grounded ? 0 : _sinceGround + dt;
    if (intent.horizontal != 0) {
      body.applyForce(Vector2(intent.horizontal * moveForce, 0));
    }
    if (intent.consumeJump() && _sinceGround <= coyoteTime) {
      body.applyLinearImpulse(Vector2(0, -jumpImpulse));
      _sinceGround = double.infinity;
      _sinceJump = 0;
      audio.play(GameSound.jump);
      haptics.play(Haptic.jump);
    }
  }

  void applyJumpBoost(double impulse) {
    _startBoost(GameSound.boostJump);
    body.applyLinearImpulse(Vector2(0, -impulse));
  }

  void applySpeedBoost(double impulse, Vector2 direction) {
    _startBoost(GameSound.boostSpeed);
    body.applyLinearImpulse(direction.normalized() * impulse);
  }

  void applyGravityBoost(double gravityScale) {
    _startBoost(GameSound.boostGravity);
    body.gravityScale = gravityScale;
  }

  /// Starts a boost for [boostDuration], ending the one running, if any:
  /// every boost the ball passes takes effect, as the level generator
  /// expects.
  void _startBoost(GameSound sound) {
    if (isBoosted) _endBoost();
    audio.play(sound);
    haptics.play(Haptic.boost);
    _boostTimer.start();
  }

  void _endBoost() {
    if (body.isValid) body.gravityScale = 1;
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is GroundSurface) {
      _touching.add(other);
    } else if (other is GoalComponent && !_reachedGoal) {
      _reachedGoal = true;
      onGoalReached();
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other is GroundSurface) _touching.remove(other);
  }

  /// Puts the ball at rest at [position], cancelling any boost: a respawn at
  /// a checkpoint (game-session spec).
  void respawn(Vector2 position) {
    _boostTimer.stop();
    _endBoost();
    _sinceGround = double.infinity;
    body
      ..setTransform(position, const Rot.identity())
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0;
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
