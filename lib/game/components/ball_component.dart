import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/game/components/goal_component.dart';
import 'package:puzzle_ball_gklabs/game/components/keyboard_joystick_controller.dart';
import 'package:puzzle_ball_gklabs/game/puzzle_ball_gklabs.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';
import 'package:sensors_plus/sensors_plus.dart';

class BallComponent extends BodyComponent with ContactCallbacks {
  BallComponent({
    required this.initialPosition,
    required this.radius,
    required Paint paint,
    this.onFall,
  }) {
    _customPaint = paint;
  }

  static const double baseForce = 300;
  static const double keyboardForceMultiplier = 100;
  static const double jumpImpulse = 300;
  static const double dampingFactor = 0.98;
  static const double fallThresholdY = 100;
  static const double shakeJumpThreshold = 15;

  static const double density = 5;
  static const double friction = 0.9;
  static const double restitution = 0.05;

  final Vector2 initialPosition;
  final double radius;
  final VoidCallback? onFall;

  late final Paint _customPaint;

  @override
  Paint get paint => _customPaint;

  JoystickComponent? joystick;
  KeyboardJoystickController? keyboardController;

  Vector2 velocity = Vector2.zero();
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _lastZ = 0;

  bool canJump = false;
  int _canJumpUntil = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (!kIsWeb) {
      _accelSub = accelerometerEventStream().listen((event) {
        velocity = Vector2(-event.x, event.y);

        final zDiff = (event.z - _lastZ).abs();
        if (zDiff.isFinite && zDiff > shakeJumpThreshold) {
          jump();
        }
        _lastZ = event.z;
      });
    }
  }

  @override
  Body createBody() {
    final shape = CircleShape()..radius = radius;
    final fixtureDef = FixtureDef(shape)
      ..density = density
      ..friction = friction
      ..restitution = restitution;
    final bodyDef = BodyDef()
      ..type = BodyType.dynamic
      ..position = initialPosition;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final useSensor =
        game.buildContext?.read<SettingsCubit>().state.useSensorControl ??
            false;

    var inputDirection = Vector2.zero();

    if (useSensor && velocity.length > 0.1) {
      inputDirection = velocity;
      if (inputDirection.length2 > 1.0) {
        inputDirection.normalize();
      }
    } else if (!useSensor && keyboardController!.keyboardDelta.length > 0.1) {
      inputDirection = keyboardController!.keyboardDelta;
    } else if (!useSensor && joystick != null && joystick!.delta.length > 0.1) {
      inputDirection = joystick!.delta;
    }

    final isKeyboard = keyboardController!.keyboardDelta.length > 0.1;
    final force = isKeyboard ? baseForce * keyboardForceMultiplier : baseForce;
    body.applyForce(inputDirection * force);

    if (inputDirection.length < 0.01) {
      body.linearVelocity *= dampingFactor;
    }

    if (body.position.y > fallThresholdY) {
      onFall?.call();
    }
  }

  void jump() {
    final now = DateTime.now().millisecondsSinceEpoch;
    debugPrint(
        '[Jump] Intentando saltar: canJump=$canJump, restante=${_canJumpUntil - now}');
    if (canJump || now < _canJumpUntil) {
      body.applyLinearImpulse(Vector2(0, -jumpImpulse));
      canJump = false;
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is GoalComponent) {
      (game as PuzzleBallGklabs).onLevelCompleted?.call();
    } else {
      canJump = true;
      _canJumpUntil = DateTime.now().millisecondsSinceEpoch + 150;
      debugPrint('[Jump] Contacto iniciado, canJump = true');
    }
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other is! GoalComponent) {
      final now = DateTime.now().millisecondsSinceEpoch;
      canJump = now < _canJumpUntil;
    }
  }

  @override
  void onRemove() {
    _accelSub?.cancel();
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final scale = _calculateDepthScale(body.position.y);

    canvas
      ..save()
      ..scale(scale, scale)
      ..drawCircle(Offset.zero, radius, paint)
      ..restore();
  }

  double _calculateDepthScale(double y) {
    const minY = 0.0;
    const maxY = 600.0;
    return 0.6 + ((y - minY).clamp(0, maxY) / maxY) * 0.4;
  }
}
