import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart'
    show BoostType, FloorSurface;
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/goal_component.dart';
import 'package:puzzle_ball_gklabs/game/components/ground_surface.dart';
import 'package:puzzle_ball_gklabs/game/components/loop_component.dart';
import 'package:puzzle_ball_gklabs/game/components/moving_platform_component.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';

/// The player's ball: moves and jumps from the [MovementIntent], takes
/// boosts, and reports reaching the goal.
///
/// Boosts end on a game-time [Timer] owned by the ball, so they pause with the
/// game and disappear with the level (design D3).
///
/// The ground it stands on changes how it moves (design D4 of
/// add-curved-terrain-and-physics): on ice the push and the damping are both
/// weaker, so it speeds up and slows down slowly; mud damps it harder and
/// weakens the jump; a conveyor belt damps it relative to the belt, which
/// carries it. Inside a loop it rides on its speed alone.
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

  /// Upward impulse of a jump: about 2.75 m high under the world's gravity.
  static const jumpImpulse = 69.0;

  /// How long after leaving the ground a jump still works (player-controls).
  static const coyoteTime = 0.15;

  /// After a jump, how long the ground is ignored: the contact lingers for a
  /// frame or two after take-off, which would allow a second jump.
  static const jumpLockout = 0.25;

  /// How long a boost lasts.
  static const boostDuration = 2.0;

  /// The speed of a conveyor belt, in m/s.
  static const beltSpeed = 2.5;

  /// How much of the push and the damping act on ice.
  static const iceGrip = 0.35;

  /// How much harder mud damps, and how much of the jump it leaves.
  static const mudDamping = 2.5;
  static const mudJump = 0.8;

  /// How much stronger the push is during an adrenaline rush.
  static const rushGain = 1.25;

  /// The adrenaline zones the ball is in: a rush lasts while it is in one.
  int _rushes = 0;

  /// Whether an adrenaline rush is on (level-mechanics spec).
  bool get isRushing => _rushes > 0;

  /// The ball entered an adrenaline zone.
  void enterRush() {
    if (_rushes++ > 0) return;
    audio.play(GameSound.heartbeat);
    haptics.play(Haptic.heartbeat);
  }

  /// The ball left an adrenaline zone.
  void leaveRush() {
    if (_rushes > 0) _rushes--;
  }

  final MovementIntent intent;
  final AudioSink audio;
  final HapticsSink haptics;
  final Vector2 initialPosition;
  final double radius;
  final VoidCallback onGoalReached;
  final Image? textureImage;

  /// The floors, ramps and curves the ball touches, with how many of their
  /// shapes it touches: rolling along a curve, it touches the next segment
  /// before it leaves the last.
  final Map<GroundSurface, int> _touching = {};

  /// The loop tracks the ball touches, counted the same way.
  final Map<LoopArcComponent, int> _arcs = {};

  /// The surface last stood on, which a jump leaves from.
  FloorSurface _footing = FloorSurface.plain;

  /// The damping set on the body.
  double _damping = linearDamping;
  double _sinceGround = double.infinity;
  double _sinceJump = double.infinity;
  int _airJumps = 0;
  late final Timer _boostTimer = Timer(
    boostDuration,
    onTick: _endBoost,
    autoStart: false,
  );
  bool _reachedGoal = false;
  BoostType? _activeBoost;

  /// Whether the ball rests on the top of a floor or a ramp: it touches one
  /// and its center is above that surface. Touching the side of a ledge does
  /// not count (player-controls spec), and a contact that began on a corner
  /// counts once the ball is on top.
  bool get isOnGround => _standingOn() != null;

  /// The surface the ball stands on, if any.
  GroundSurface? _standingOn() {
    if (_touching.isEmpty || !isMounted) return null;
    final center = body.position;
    for (final surface in _touching.keys) {
      if (surface.supports(center)) return surface;
    }
    return null;
  }

  /// Whether the ball rides a loop's track (level-mechanics spec).
  bool get isInLoop =>
      _arcs.keys.any((arc) => arc.isActive && arc.holds(body.position));

  static void _enter<T>(Map<T, int> touching, T other) =>
      touching[other] = (touching[other] ?? 0) + 1;

  static void _leave<T>(Map<T, int> touching, T other) {
    final count = (touching[other] ?? 0) - 1;
    if (count > 0) {
      touching[other] = count;
    } else {
      touching.remove(other);
    }
  }

  /// Whether a boost is running.
  bool get isBoosted => _boostTimer.isRunning();

  /// The boost running, if any (game-hud spec).
  BoostType? get activeBoost => _activeBoost;

  /// The seconds left of the running boost; zero with none.
  double get boostLeft => isBoosted ? boostDuration - _boostTimer.current : 0;

  @override
  Body createBody() {
    return world.createBody(
      BodyDef(
        type: BodyType.dynamic,
        position: initialPosition,
        linearDamping: linearDamping,
        // A rolling ball spins fast: without this, Box2D caps its rotation
        // per step, which caps its rolling speed at about 9.3 m/s.
        allowFastRotation: true,
        // The ball is the only moving body: it never sleeps, so whatever
        // moves it acts at once.
        enableSleep: false,
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
    final standing = _standingOn();
    final grounded = standing != null && _sinceJump > jumpLockout;
    _sinceGround = grounded ? 0 : _sinceGround + dt;
    if (grounded) _footing = standing.floorSurface;
    if (isInLoop) {
      _rideLoop();
    } else {
      _move(grounded ? standing.floorSurface : FloorSurface.plain);
    }
    if (!intent.consumeJump()) return;
    if (_sinceGround <= coyoteTime) {
      _jump(_footing == FloorSurface.mud ? mudJump : 1);
    } else if (_airJumps > 0) {
      // An air jump rises the same whatever the timing: from rest.
      _airJumps--;
      body.linearVelocity = Vector2(body.linearVelocity.x, 0);
      _jump(1);
    }
  }

  /// In a loop the ball rides on its speed alone: a sideways push would
  /// brake it in the upper half, and nothing damps it.
  void _rideLoop() => _setDamping(0);

  /// Pushes and damps the ball as [surface] allows.
  void _move(FloorSurface surface) {
    final damping =
        linearDamping *
        switch (surface) {
          FloorSurface.ice => iceGrip,
          FloorSurface.mud => mudDamping,
          _ => 1.0,
        };
    _setDamping(damping);
    if (intent.horizontal != 0) {
      final grip =
          (surface == FloorSurface.ice ? iceGrip : 1.0) *
          (isRushing ? rushGain : 1.0);
      body.applyForce(Vector2(intent.horizontal * moveForce * grip, 0));
    }
    final belt = switch (surface) {
      FloorSurface.conveyorForward => beltSpeed,
      FloorSurface.conveyorBackward => -beltSpeed,
      _ => 0.0,
    };
    // The damping acts relative to the belt.
    if (belt != 0) body.applyForce(Vector2(belt * body.mass * damping, 0));
    _rideDeck();
  }

  void _setDamping(double damping) {
    if (damping == _damping) return;
    _damping = damping;
    body.linearDamping = damping;
  }

  /// On a moving platform, the damping acts relative to its deck, so the
  /// ball rests and rolls on it as on the ground instead of drifting off
  /// (level-mechanics spec).
  void _rideDeck() {
    final center = body.position;
    for (final surface in _touching.keys) {
      if (surface is MovingPlatformComponent && surface.supports(center)) {
        final deck = surface.body.linearVelocity;
        body.applyForce(deck * (body.mass * linearDamping));
        return;
      }
    }
  }

  void _jump(double scale) {
    body.applyLinearImpulse(Vector2(0, -jumpImpulse * scale));
    _sinceGround = double.infinity;
    _sinceJump = 0;
    audio.play(GameSound.jump);
    haptics.play(Haptic.jump);
  }

  /// Throws the ball up at [speed], keeping its horizontal speed: a
  /// trampoline (level-mechanics spec).
  void bounce(double speed) {
    body.linearVelocity = Vector2(body.linearVelocity.x, -speed);
    _sinceGround = double.infinity;
    _sinceJump = 0;
    audio.play(GameSound.boostJump);
    haptics.play(Haptic.jump);
  }

  /// Charges one jump the player can use in mid-air: a double-jump orb
  /// (level-mechanics spec).
  void chargeAirJump() {
    _airJumps = 1;
    audio.play(GameSound.boostJump);
    haptics.play(Haptic.boost);
  }

  /// Whether an air jump is charged.
  bool get hasAirJump => _airJumps > 0;

  /// Throws the ball up: a fall into the boost is stopped first, so it
  /// rises at least as high as from the ground, and a jump into it adds up.
  void applyJumpBoost(double impulse) {
    _startBoost(BoostType.jump, GameSound.boostJump);
    final velocity = body.linearVelocity;
    if (velocity.y > 0) body.linearVelocity = Vector2(velocity.x, 0);
    body.applyLinearImpulse(Vector2(0, -impulse));
  }

  void applySpeedBoost(double impulse, Vector2 direction) {
    _startBoost(BoostType.speed, GameSound.boostSpeed);
    body.applyLinearImpulse(direction.normalized() * impulse);
  }

  void applyGravityBoost(double gravityScale) {
    _startBoost(BoostType.gravity, GameSound.boostGravity);
    body.gravityScale = gravityScale;
  }

  /// Starts a boost for [boostDuration], ending the one running, if any:
  /// every boost the ball passes takes effect, as the level generator
  /// expects.
  void _startBoost(BoostType type, GameSound sound) {
    if (isBoosted) _endBoost();
    audio.play(sound);
    haptics.play(Haptic.boost);
    _boostTimer.start();
    _activeBoost = type;
  }

  void _endBoost() {
    _activeBoost = null;
    if (body.isValid) body.gravityScale = 1;
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is GroundSurface) {
      _enter(_touching, other);
    } else if (other is LoopArcComponent) {
      _enter(_arcs, other);
    } else if (other is GoalComponent && !_reachedGoal) {
      _reachedGoal = true;
      onGoalReached();
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other is GroundSurface) _leave(_touching, other);
    if (other is LoopArcComponent) _leave(_arcs, other);
  }

  /// Puts the ball at rest at [position], cancelling any boost: a respawn at
  /// a checkpoint (game-session spec).
  void respawn(Vector2 position) {
    _boostTimer.stop();
    _endBoost();
    _sinceGround = double.infinity;
    _airJumps = 0;
    _arcs.clear();
    _rushes = 0;
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
