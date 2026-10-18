import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A checkpoint: the ball activates it by touching any part of the flag, and
/// respawns above the last active one after a fall (game-session spec).
class CheckPointComponent extends BodyComponent with ContactCallbacks {
  new({required this.ground, required this.onActivated})
    : super(renderBody: false);

  /// Height of the post, in meters.
  static const postHeight = 1.6;

  /// The activation area: the whole flag, a little wider than drawn.
  static final Vector2 size = Vector2(1, postHeight + 0.2);

  /// Where the post stands on the ground, in meters.
  final Vector2 ground;

  /// Called once, when the ball first passes the checkpoint.
  final void Function(CheckPointComponent checkpoint) onActivated;

  /// How long the burst of an activation lasts, in seconds.
  static const burstDuration = 0.5;

  /// The flag's size, in meters.
  static const flagWidth = 0.6;
  static const flagHeight = 0.4;

  bool _activated = false;
  double _time = 0;

  /// Seconds since activation; infinite before it.
  double _sinceActivated = double.infinity;

  /// Whether the activation burst is showing.
  bool get isBursting => _sinceActivated < burstDuration;

  bool get isActivated => _activated;

  /// Where the ball reappears: at rest, a little above the ground.
  Vector2 get respawnPoint => Vector2(ground.x, ground.y - 1);

  @override
  Body createBody() {
    final centre = Vector2(ground.x, ground.y - size.y / 2);
    return world.createBody(BodyDef(position: centre))..createShape(
      Polygon.box(size.x / 2, size.y / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallComponent && !_activated) {
      _activated = true;
      _sinceActivated = 0;
      onActivated(this);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _sinceActivated += dt;
  }

  @override
  void render(Canvas canvas) {
    final base = size.y / 2;
    final top = base - postHeight;
    final color = _activated
        ? ElementPalette.checkpointActive
        : ElementPalette.checkpointIdle;
    _post(canvas, top, base);
    _flag(canvas, top + 0.08, color);
    canvas
      ..save()
      ..translate(0, top);
    ElementPainter.orb(canvas, 0.08, color);
    canvas.restore();
    if (isBursting) {
      _burst(canvas, Offset(flagWidth / 2, top + flagHeight / 2));
    }
  }

  /// A metal pole with a dark outline.
  void _post(Canvas canvas, double top, double base) {
    final pole = Rect.fromLTWH(-0.04, top, 0.08, base - top);
    canvas.drawRect(
      pole,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8A96A3), Color(0xFFE9EEF2), Color(0xFF5E6873)],
          stops: [0, 0.4, 1],
        ).createShader(pole),
    );
    ElementPainter.outline(canvas, Path()..addRect(pole), 0.025);
  }

  /// A flag waving from the pole, lit along its top edge.
  void _flag(Canvas canvas, double top, Color color) {
    // The wave grows towards the tip.
    double wave(double t) => math.sin(_time * 5 - t * 4) * 0.05 * t;
    const steps = 8;
    final path = Path()..moveTo(0.04, top);
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      path.lineTo(0.04 + t * flagWidth, top + wave(t));
    }
    for (var i = steps; i >= 0; i--) {
      final t = i / steps;
      path.lineTo(
        0.04 + t * flagWidth,
        top + flagHeight * (1 - 0.25 * t) + wave(t),
      );
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, const Color(0xFFFFFFFF), 0.4)!,
            color,
            Color.lerp(color, ElementPalette.outline, 0.35)!,
          ],
        ).createShader(path.getBounds()),
    );
    ElementPainter.outline(canvas, path, 0.025);
  }

  /// Sparks flying out from [center], fading over the burst.
  void _burst(Canvas canvas, Offset center) {
    final t = _sinceActivated / burstDuration;
    final paint = Paint()
      ..color = ElementPalette.checkpointActive.withValues(alpha: 1 - t);
    for (var i = 0; i < 10; i++) {
      final angle = i / 10 * 2 * math.pi;
      final distance = 0.15 + t * 0.6;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * distance,
        0.05 * (1 - t) + 0.015,
        paint,
      );
    }
  }
}
