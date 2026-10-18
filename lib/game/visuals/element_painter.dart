import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show BoostType;
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// Draws gameplay elements with depth, never flat (design D5): a drop
/// shadow, a glow, a body lit from the top left, a specular arc, and a dark
/// outline with a light rim, so they read against any biome.
abstract final class ElementPainter {
  static const _white = Color(0xFFFFFFFF);

  /// An orb of [radius] in [color], centered at the origin.
  static void orb(Canvas canvas, double radius, Color color) {
    final bounds = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas
      // Drop shadow.
      ..drawOval(
        Rect.fromCenter(
          center: Offset(radius * 0.12, radius * 1.05),
          width: radius * 1.7,
          height: radius * 0.45,
        ),
        Paint()..color = const Color(0x55000000),
      )
      // Glow.
      ..drawCircle(
        Offset.zero,
        radius * 1.6,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  color.withValues(alpha: 0.45),
                  color.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: Offset.zero, radius: radius * 1.6),
              ),
      )
      // Body, lit from the top left.
      ..drawCircle(
        Offset.zero,
        radius,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.45),
            radius: 1.1,
            colors: [
              Color.lerp(color, _white, 0.45)!,
              color,
              Color.lerp(color, ElementPalette.outline, 0.45)!,
            ],
            stops: const [0, 0.55, 1],
          ).createShader(bounds),
      )
      // Specular arc.
      ..drawArc(
        bounds.deflate(radius * 0.18),
        math.pi * 1.05,
        math.pi * 0.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = radius * 0.12
          ..color = _white.withValues(alpha: 0.55),
      );
    outline(canvas, Path()..addOval(bounds), radius * 0.09);
  }

  /// A dark outline with a thin light rim inside it, around [shape].
  static void outline(Canvas canvas, Path shape, double width) {
    canvas
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..color = ElementPalette.outline,
      )
      ..save()
      ..clipPath(shape)
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 1.6
          ..color = ElementPalette.rim.withValues(alpha: 0.7),
      )
      ..restore();
  }

  /// The icon of a boost of [type], white with a soft shadow, fitting a
  /// circle of [radius].
  static void boostIcon(Canvas canvas, BoostType type, double radius) {
    final path = switch (type) {
      BoostType.jump => _chevrons(radius, up: true),
      BoostType.speed => _chevrons(radius, up: false),
      BoostType.gravity => _feather(radius),
      BoostType.doubleJump => _arrows(radius),
    };
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = radius * 0.16;
    canvas
      ..drawPath(
        path.shift(Offset(radius * 0.04, radius * 0.06)),
        stroke..color = const Color(0x66000000),
      )
      ..drawPath(path, stroke..color = _white);
  }

  /// Two chevrons pointing up or right.
  static Path _chevrons(double radius, {required bool up}) {
    final size = radius * 0.32;
    final path = Path();
    for (final offset in [-0.2, 0.2]) {
      final d = radius * offset;
      if (up) {
        path
          ..moveTo(-size, d + size * 0.5)
          ..lineTo(0, d - size * 0.5)
          ..lineTo(size, d + size * 0.5);
      } else {
        path
          ..moveTo(d - size * 0.5, -size)
          ..lineTo(d + size * 0.5, 0)
          ..lineTo(d - size * 0.5, size);
      }
    }
    return path;
  }

  /// Two arrows stacked upwards: a jump, then another.
  static Path _arrows(double radius) {
    final head = radius * 0.2;
    final path = Path();
    for (final top in [-0.46, -0.04]) {
      final y = radius * top;
      path
        ..moveTo(-head, y + head)
        ..lineTo(0, y)
        ..lineTo(head, y + head)
        ..moveTo(0, y)
        ..lineTo(0, y + radius * 0.4);
    }
    return path;
  }

  /// A feather, tilted: light as the ball under a gravity boost.
  static Path _feather(double radius) {
    final r = radius;
    final vane = Path()
      ..moveTo(0, -r * 0.5)
      ..quadraticBezierTo(r * 0.34, -r * 0.08, r * 0.04, r * 0.36)
      ..quadraticBezierTo(-r * 0.3, r * 0.02, 0, -r * 0.5)
      // The spine, down to the quill.
      ..moveTo(0, -r * 0.42)
      ..quadraticBezierTo(r * 0.04, r * 0.05, -r * 0.08, r * 0.5)
      // Two barbs on each side.
      ..moveTo(r * 0.01, -r * 0.16)
      ..lineTo(r * 0.17, -r * 0.24)
      ..moveTo(r * 0.02, r * 0.06)
      ..lineTo(r * 0.16, -r * 0.01)
      ..moveTo(r * 0.0, -r * 0.08)
      ..lineTo(-r * 0.14, -r * 0.15);
    // Tilted by 0.45 rad, as a 4 × 4 column-major rotation.
    const c = 0.9004471023526769; // cos(0.45)
    const s = 0.43496553411123023; // sin(0.45)
    return vane.transform(
      Float64List.fromList([c, s, 0, 0, -s, c, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
    );
  }
}
