import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A trampoline: a pad lying on the ground that throws the ball up at a
/// fixed speed, keeping its horizontal speed, so every bounce rises to the
/// same height whatever the fall (level-mechanics spec, design D3 of
/// add-curved-terrain-and-physics).
///
/// Drawn as a springy pad on coils that squashes when used (game-visuals
/// spec).
class TrampolineComponent extends BodyComponent with ContactCallbacks {
  new({required this.left, required this.ground, required this.width})
    : super(renderBody: false);

  /// The pad's left end and the ground under it, in meters.
  final double left;
  final double ground;

  /// The pad's length, in meters.
  final double width;

  /// The upward speed a bounce gives, in m/s: about 5 m high.
  static const launchSpeed = 17.0;

  /// The height of the pad's sensor above the ground, in meters.
  static const padHeight = 0.35;

  /// How long the pad stays squashed after a bounce, in seconds.
  static const squashTime = 0.25;

  /// Seconds since the last bounce.
  double _sinceBounce = double.infinity;

  /// Whether the pad is squashed by a recent bounce.
  bool get isSquashed => _sinceBounce < squashTime;

  @override
  Body createBody() {
    return world.createBody(
      BodyDef(position: Vector2(left + width / 2, ground - padHeight / 2)),
    )..createShape(
      Polygon.box(width / 2, padHeight / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    // A ball already flying up from it is not thrown again.
    if (other is! BallComponent ||
        other.body.linearVelocity.y < -launchSpeed / 2) {
      return;
    }
    other.bounce(launchSpeed);
    _sinceBounce = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sinceBounce += dt;
  }

  static final _coil = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.05
    ..strokeCap = StrokeCap.round
    ..color = ElementPalette.track;
  static final _outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04
    ..color = ElementPalette.outline;
  static final _shadow = Paint()..color = const Color(0x55000000);
  late final Paint _pad = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(ElementPalette.trampoline, const Color(0xFFFFFFFF), 0.45)!,
        ElementPalette.trampoline,
        Color.lerp(ElementPalette.trampoline, ElementPalette.outline, 0.4)!,
      ],
    ).createShader(Rect.fromLTWH(-width / 2, -padHeight / 2, width, 0.12));

  @override
  void render(Canvas canvas) {
    // Local origin at the sensor's centre; the ground is padHeight / 2 down.
    const floor = padHeight / 2;
    final squash = isSquashed
        ? math.sin(math.pi * _sinceBounce / squashTime) * 0.12
        : 0.0;
    final top = -padHeight / 2 + squash;
    canvas.drawOval(
      Rect.fromCenter(
        center: const Offset(0, floor),
        width: width,
        height: 0.1,
      ),
      _shadow,
    );
    // Coils from the ground up to the pad.
    final coils = math.max(2, (width / 0.5).floor());
    for (var i = 0; i < coils; i++) {
      final x = -width / 2 + width * (i + 0.5) / coils;
      final path = Path()..moveTo(x, floor);
      const turns = 3;
      for (var t = 1; t <= turns * 2; t++) {
        final y = floor - (floor - top - 0.08) * t / (turns * 2);
        path.lineTo(x + (t.isOdd ? 0.08 : -0.08), y);
      }
      canvas.drawPath(path, _coil);
    }
    final pad = RRect.fromRectAndRadius(
      Rect.fromLTWH(-width / 2, top, width, 0.12),
      const Radius.circular(0.06),
    );
    canvas
      ..drawRRect(pad, _pad)
      ..drawRRect(pad, _outline);
  }
}
