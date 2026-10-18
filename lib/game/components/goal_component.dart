import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// The goal: a sensor at the end of the level, drawn as an arched portal
/// with an animated swirl (game-visuals spec).
class GoalComponent extends BodyComponent with ContactCallbacks {
  new({required this.position, required this.size}) : super(renderBody: false);

  /// Centre of the sensor, in meters.
  @override
  final Vector2 position;
  final Vector2 size;

  /// How fast the swirl turns, in radians per second.
  static const spin = 1.6;

  double _time = 0;

  /// The swirl's current angle.
  double get swirlAngle => _time * spin;

  @override
  Body createBody() {
    return world.createBody(BodyDef(position: position))..createShape(
      Polygon.box(size.x / 2, size.y / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  @override
  void render(Canvas canvas) {
    // The arch is wider than the sensor, for presence.
    final width = size.x * 1.5;
    final bottom = size.y / 2;
    final top = -size.y / 2;
    final outer = _arch(-width / 2, top, width / 2, bottom);
    final inner = _arch(
      -width / 2 + 0.16,
      top + 0.16,
      width / 2 - 0.16,
      bottom,
    );
    final bounds = outer.getBounds();
    final glow = bounds.inflate(0.5);
    canvas
      ..drawOval(
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: [
              ElementPalette.portal.withValues(alpha: 0.35),
              ElementPalette.portal.withValues(alpha: 0),
            ],
          ).createShader(glow),
      )
      ..drawPath(
        outer,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE6EBF5), Color(0xFF8C96B4), Color(0xFF4A5170)],
          ).createShader(bounds),
      )
      ..drawPath(
        inner,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, 0.1),
            colors: [
              const Color(0xFFFFFFFF),
              ElementPalette.portal,
              Color.lerp(ElementPalette.portal, ElementPalette.outline, 0.6)!,
            ],
            stops: const [0, 0.35, 1],
          ).createShader(inner.getBounds()),
      )
      ..save()
      ..clipPath(inner);
    _swirl(canvas, inner.getBounds());
    canvas.restore();
    ElementPainter.outline(canvas, outer, 0.05);
    ElementPainter.outline(canvas, inner, 0.035);
  }

  /// Counter-rotating rings of light inside the portal.
  void _swirl(Canvas canvas, Rect bounds) {
    final center = bounds.center;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.06;
    for (var ring = 0; ring < 3; ring++) {
      final radius = bounds.width * (0.18 + ring * 0.13);
      final direction = ring.isEven ? 1 : -1;
      paint.color = const Color(0xFFFFFFFF)
          .withValues(alpha: 0.75 - ring * 0.2);
      for (var arc = 0; arc < 2; arc++) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          swirlAngle * direction * (1 + ring * 0.3) + arc * math.pi,
          math.pi * 0.55,
          false,
          paint,
        );
      }
    }
  }

  /// A doorway from [left], [top] to [right], [bottom], round at the top.
  static Path _arch(double left, double top, double right, double bottom) {
    final radius = (right - left) / 2;
    return Path()
      ..moveTo(left, bottom)
      ..lineTo(left, top + radius)
      ..arcToPoint(Offset(right, top + radius), radius: Radius.circular(radius))
      ..lineTo(right, bottom)
      ..close();
  }
}
