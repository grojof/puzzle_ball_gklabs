import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/game/components/floor_component.dart';
import 'package:puzzle_ball_gklabs/game/components/goal_component.dart';
import 'package:puzzle_ball_gklabs/game/components/keyboard_joystick_controller.dart';
import 'package:puzzle_ball_gklabs/game/components/ramp_component.dart';
import 'package:puzzle_ball_gklabs/game/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/game/levels/levels.dart';
import 'package:puzzle_ball_gklabs/game/puzzle_ball_gklabs.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';
import 'package:sensors_plus/sensors_plus.dart';

class BallComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.audioCubit,
    required this.initialPosition,
    required this.radius,
    this.textureImage,
    this.onFall,
  });

  final AudioCubit audioCubit;
  final Vector2 initialPosition;
  final double radius;
  final VoidCallback? onFall;
  final Image? textureImage;
  bool _portalActivated = false;

  // 🎯 Configuración física ajustable
  static double density = 50; // Masa (más alto = más pesada)
  static double friction = 0.6; // Rozamiento con el suelo
  static double restitution = 0; // Rebote al chocar

  static double linearDamping = 1.5; // Frenado natural
  static double baseForce = 80; // Fuerza para moverse
  static double jumpForce = 80; // Impulso del salto (vertical)
  // static double fallThresholdY = 60; // Y para reiniciar al caer

  // Parámetros ajustables para caída libre
  static double fallCheckTime = 2; // segundos
  static double fallCheckDistance = 20; // unidades
  static double fallCheckRadius = 20; // radio de búsqueda de suelo/rampa

  JoystickComponent? joystick;
  KeyboardJoystickController? keyboardController;

  Vector2 sensorVelocity = Vector2.zero();
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _lastZ = 0;

  bool canJump = false;
  int _canJumpUntil = 0;

  // Variables para caída libre
  // double _lastGroundY = 0;
  int _lastGroundTime = 0;
  bool _onGround = false;

  // --- BOOST STATE ---
  void Function(BoostType type)? onBoostActivated;
  void Function()? onBoostDeactivated;
  bool _boostActive = false;
  double jumpBoostForce = jumpForce;
  double speedBoostForce = baseForce;
  Vector2 speedBoostDirection = Vector2(1, 0);
  double gravityBoostScale = 0.1; // Por defecto, gravedad lunar
  double? _originalGravityScaleY;

  // Métodos para boost externos
  void applyJumpBoost([double? force]) {
    body.applyLinearImpulse(Vector2(0, -(force ?? jumpBoostForce)));
    _triggerBoost(BoostType.jump);
  }

  void applySpeedBoost({double? force, Vector2? direction}) {
    body.applyLinearImpulse(
      (direction ?? speedBoostDirection).normalized() *
          (force ?? speedBoostForce),
    );
    _triggerBoost(BoostType.speed);
  }

  void applyGravityBoost({double? gravityScale, double? duration}) {
    // Guarda el valor original solo la primera vez
    _originalGravityScaleY ??= body.gravityScale;
    body.gravityScale = gravityScale ?? gravityBoostScale;
    _triggerBoost(BoostType.gravity, duration: duration);
    Future.delayed(
      Duration(milliseconds: ((duration ?? 2.0) * 1000).toInt()),
      () {
        if (body.isValid && _originalGravityScaleY != null) {
          body.gravityScale = _originalGravityScaleY!;
          _originalGravityScaleY = null;
        }
      },
    );
  }

  void _triggerBoost(BoostType type, {double? duration}) {
    if (_boostActive) return;
    switch (type) {
      case BoostType.jump:
        unawaited(audioCubit.playEffect(Assets.audio.boostJump));
      case BoostType.speed:
        unawaited(audioCubit.playEffect(Assets.audio.boostSpeed));
      case BoostType.gravity:
        unawaited(audioCubit.playEffect(Assets.audio.boostGravity));
    }

    _boostActive = true;
    onBoostActivated?.call(type);
    Future.delayed(
      Duration(milliseconds: ((duration ?? 2.0) * 1000).toInt()),
      () {
        _boostActive = false;
        onBoostDeactivated?.call();
      },
    );
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    if (!kIsWeb) {
      _accelSub = accelerometerEventStream().listen((event) {
        sensorVelocity = Vector2(-event.x, event.y);
        final zDiff = (event.z - _lastZ).abs();
        if (zDiff.isFinite && zDiff > 15) jump();
        _lastZ = event.z;
      });
    }
  }

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
        material: SurfaceMaterial(friction: friction, restitution: restitution),
        enableContactEvents: true,
        enableSensorEvents: true,
        userData: this,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final dir = _getInputDirection();

    if (dir.x != 0) {
      body.applyForce(dir * baseForce);
    }

    // Lógica avanzada de caída libre
    if (!_onGround) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final timeFalling = (now - _lastGroundTime) / 1000.0;
      final ballPos = body.position;
      double? minDist;
      // Buscar el suelo/rampa más cercano por debajo
      final bodies = game.world.children.whereType<BodyComponent>();
      for (final b in bodies) {
        if (b is FloorComponent || b is RampComponent) {
          final compPos = b.body.position;
          final dx = (compPos.x - ballPos.x).abs();
          final dy = compPos.y - ballPos.y;
          if (dy > 0 && dx < fallCheckRadius) {
            if (minDist == null || dy < minDist) minDist = dy;
          }
        }
      }
      if (timeFalling > fallCheckTime &&
          (minDist == null || minDist > fallCheckDistance)) {
        onFall?.call();
      }
    }
  }

  Vector2 _getInputDirection() {
    final useSensor =
        game.buildContext?.read<SettingsCubit>().state.useSensorControl ??
        false;

    if (useSensor) {
      // Tilt is proportional: a full push needs about 30° of tilt, and small
      // tilts inside the dead zone do nothing.
      final tilt = (sensorVelocity.x / 5).clamp(-1.0, 1.0);
      return Vector2(tilt.abs() < 0.08 ? 0 : tilt, 0);
    }

    var direction = Vector2.zero();

    if (!useSensor && keyboardController!.keyboardDelta.length > 0.1) {
      direction = keyboardController!.keyboardDelta;
    } else if (!useSensor && joystick!.delta.length > 0.1) {
      direction = joystick!.delta;
    }

    // Keyboard and joystick push at full force; movement is horizontal only.
    return direction.x == 0 ? Vector2.zero() : Vector2(direction.x.sign, 0);
  }

  void jump() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (canJump || now < _canJumpUntil) {
      body.applyLinearImpulse(Vector2(0, -jumpForce));
      canJump = false;

      // 🔊 Reproducir sonido de salto
      unawaited(audioCubit.playEffect(Assets.audio.jump));
    }
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is GoalComponent && !_portalActivated) {
      _portalActivated = true;

      // Stop the ball after the physics step that reported the contact.
      unawaited(
        Future.microtask(() {
          body
            ..linearVelocity = Vector2.zero()
            ..isEnabled = false;
        }),
      );
      unawaited(_playGoalSequence(game as PuzzleBallGklabs));
    } else {
      canJump = true;
      _canJumpUntil = DateTime.now().millisecondsSinceEpoch + 150;
      _onGround = true;
      _lastGroundTime = DateTime.now().millisecondsSinceEpoch;
    }
  }

  /// Flashes blue, fades to black and then completes the level.
  Future<void> _playGoalSequence(PuzzleBallGklabs gameRef) async {
    final screenSize = gameRef.size;

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
    final flashOverlay = RectangleComponent(
      size: screenSize,
      paint: Paint()..color = const Color(0xFF42A5F5).withValues(alpha: 0),
      children: [flash],
    );
    await gameRef.camera.viewport.add(flashOverlay);
    await flash.completed;
    flashOverlay.removeFromParent();

    final fade = OpacityEffect.to(
      1,
      EffectController(duration: 0.4, curve: Curves.easeIn),
    );
    final blackoutOverlay = RectangleComponent(
      size: screenSize,
      paint: Paint()..color = const Color(0xFF000000).withValues(alpha: 0),
      children: [fade],
    );
    await gameRef.camera.viewport.add(blackoutOverlay);
    await fade.completed;
    gameRef.onLevelCompleted?.call();
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other is! GoalComponent) {
      final now = DateTime.now().millisecondsSinceEpoch;
      canJump = now < _canJumpUntil;
      // Si deja de tocar suelo/rampa, empieza caída libre
      _onGround = false;
    }
  }

  @override
  void onRemove() {
    unawaited(_accelSub?.cancel());
    super.onRemove();
  }

  @override
  void render(Canvas canvas) {
    final scale = _calculateDepthScale(body.position.y);

    canvas
      ..save()
      ..scale(scale, scale);

    if (textureImage != null) {
      final dst = Rect.fromCircle(center: Offset.zero, radius: radius);
      final src = Rect.fromLTWH(
        0,
        0,
        textureImage!.width.toDouble(),
        textureImage!.height.toDouble(),
      );

      canvas
        ..save()
        ..clipPath(Path()..addOval(dst))
        ..drawImageRect(textureImage!, src, dst, Paint())
        ..restore();
    } else {
      // Fallback al degradado si no se ha cargado la textura
      final gradientPaint = Paint()
        ..shader = RadialGradient(
          colors: [paint.color, paint.color.withAlpha(180)],
          center: Alignment.topLeft,
          radius: 0.9,
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: radius));

      canvas.drawCircle(Offset.zero, radius, gradientPaint);
    }
    canvas.restore();
  }

  double _calculateDepthScale(double y) {
    const minY = 0.0;
    const maxY = 600.0;
    return 0.6 + ((y - minY).clamp(0, maxY) / maxY) * 0.4;
  }
}
