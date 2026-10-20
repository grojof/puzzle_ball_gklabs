import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart'
    show Bumper, climbBumperRadius;
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A pinball bumper: touching it throws the ball straight away from it at
/// [speed], whatever speed it hit at, keeping its speed along the surface.
/// A climb's bumper that leans throws a ball landing on its top up and
/// towards its side at [speed] instead, wherever it lands (level-mechanics
/// spec, design D2 of add-dynamic-elements).
///
/// Drawn with a bright cap and a chrome ring, with an arrow when it leans,
/// it lights up and swells when it throws the ball (game-visuals spec).
class BumperComponent extends BodyComponent with ContactCallbacks {
  new({required this.bumper}) : super(renderBody: false);

  final Bumper bumper;

  /// The speed a bumper throws the ball at, in m/s.
  static const speed = 11.0;

  /// How far a leaning bumper's throw slants per meter it rises.
  static const leanSlope = 0.45;

  /// How long a bumper flashes after a throw, in seconds.
  static const flashTime = 0.2;

  double _sinceThrow = double.infinity;

  /// Whether the bumper is flashing from a recent throw.
  bool get isFlashing => _sinceThrow < flashTime;

  @override
  Body createBody() {
    return world.createBody(
      BodyDef(position: Vector2(bumper.center.x, bumper.center.y)),
    )..createShape(
      Circle(radius: bumper.radius),
      ShapeDef(enableContactEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is! BallComponent) return;
    final away = other.body.position - body.position;
    if (away.length2 == 0) return;
    if (bumper.radius == climbBumperRadius && away.y < 0) {
      // Landed on a climb's bumper: thrown up, leaning to its side.
      final direction = Vector2(bumper.lean * leanSlope, -1)..normalize();
      other.bump(direction, speed, keepAlong: false);
    } else {
      other.bump(away.normalized(), speed);
    }
    _sinceThrow = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sinceThrow += dt;
  }

  static final _shadow = Paint()..color = const Color(0x55000000);
  static final _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.07;
  static final _outline = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035
    ..color = ElementPalette.outline;
  late final _cap = Paint()
    ..shader = RadialGradient(
      center: const Alignment(-0.35, -0.45),
      colors: [
        Color.lerp(ElementPalette.bumper, const Color(0xFFFFFFFF), 0.5)!,
        ElementPalette.bumper,
        Color.lerp(ElementPalette.bumper, ElementPalette.outline, 0.45)!,
      ],
      stops: const [0, 0.55, 1],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: bumper.radius));
  late final Shader _chrome = const SweepGradient(
    colors: [
      Color(0xFFF4F7FA),
      Color(0xFF8C98A4),
      Color(0xFFE8ECF2),
      Color(0xFF6B7783),
      Color(0xFFF4F7FA),
    ],
  ).createShader(Rect.fromCircle(center: Offset.zero, radius: bumper.radius));

  @override
  void render(Canvas canvas) {
    // Swells and glows while flashing.
    final flash = isFlashing
        ? math.sin(math.pi * _sinceThrow / flashTime)
        : 0.0;
    final r = bumper.radius;
    final scale = 1 + 0.15 * flash;
    canvas
      ..save()
      ..scale(scale)
      ..drawCircle(const Offset(0.04, 0.06), r, _shadow)
      ..drawCircle(
        Offset.zero,
        r * (1.5 + 0.5 * flash),
        Paint()
          ..shader = RadialGradient(
            colors: [
              ElementPalette.bumper.withValues(alpha: 0.35 + 0.5 * flash),
              ElementPalette.bumper.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: Offset.zero, radius: r * 2)),
      )
      ..drawCircle(Offset.zero, r, _cap)
      ..drawCircle(Offset.zero, r - 0.035, _ring..shader = _chrome)
      ..drawCircle(Offset.zero, r * 0.45, _ring..shader = _chrome)
      ..drawCircle(Offset.zero, r, _outline);
    if (bumper.lean != 0) {
      // An arrow on the cap, up and to its side.
      final side = bumper.lean.toDouble();
      canvas.drawPath(
        Path()
          ..moveTo(side * r * 0.5, -r * 0.55)
          ..lineTo(-side * r * 0.25, -r * 0.45)
          ..lineTo(side * r * 0.05, -r * 0.1)
          ..close(),
        Paint()..color = const Color(0xFFFFFFFF),
      );
    }
    if (flash > 0) {
      canvas.drawCircle(
        Offset.zero,
        r * 0.45,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: flash),
      );
    }
    canvas.restore();
  }
}
