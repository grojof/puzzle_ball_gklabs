import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show BoostType;
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A boost: a sensor that changes the ball's motion when it passes through,
/// drawn as a glowing orb with its type's color and icon, pulsing gently
/// (game-visuals spec). A double-jump orb charges an air jump and
/// disappears until [restore] (level-mechanics spec).
class BoostComponent extends BodyComponent with ContactCallbacks {
  new({required this.type, required this.position}) : super(renderBody: false);

  /// The upward impulse of a jump boost.
  static const jumpImpulse = 120.0;

  /// The forward impulse of a speed boost.
  static const speedImpulse = 100.0;

  /// The gravity scale during a gravity boost.
  static const gravityScale = 0.1;

  /// The side of the square sensor, in meters.
  static const size = 1.0;

  /// The orb's radius, in meters.
  static const radius = 0.42;

  /// How fast the orb pulses, in cycles per second, and by how much.
  static const pulseRate = 1.2;
  static const pulseAmount = 0.06;

  final BoostType type;

  /// Centre of the sensor, in meters.
  @override
  final Vector2 position;

  double _time = 0;
  bool _collected = false;

  /// Whether this double-jump orb has been collected.
  bool get isCollected => _collected;

  @override
  Body createBody() {
    return world.createBody(BodyDef(position: position))..createShape(
      Polygon.box(size / 2, size / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is! BallComponent || _collected) return;
    switch (type) {
      case BoostType.jump:
        other.applyJumpBoost(jumpImpulse);
      case BoostType.speed:
        other.applySpeedBoost(speedImpulse, Vector2(1, 0));
      case BoostType.gravity:
        other.applyGravityBoost(gravityScale);
      case BoostType.doubleJump:
        other.chargeAirJump();
        _collected = true;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  /// Each type's orb and icon, recorded once and replayed every frame.
  static final Map<BoostType, Picture> _art = {};

  static Picture _record(BoostType type) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    ElementPainter.orb(canvas, radius, ElementPalette.boost(type));
    ElementPainter.boostIcon(canvas, type, radius);
    return recorder.endRecording();
  }

  /// The orb's current scale, pulsing around 1.
  double get pulse =>
      1 + pulseAmount * math.sin(2 * math.pi * pulseRate * _time);

  /// Shows a collected orb again: after a respawn.
  void restore() => _collected = false;

  @override
  void render(Canvas canvas) {
    if (_collected) return;
    canvas
      ..save()
      ..scale(pulse)
      ..drawPicture(_art[type] ??= _record(type))
      ..restore();
  }
}
