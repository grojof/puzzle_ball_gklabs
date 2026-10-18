import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/components/floor_component.dart';

/// A floor run that collapses: once the ball stands on it, it shakes for
/// [delay] seconds, then falls away and fades, until [restore] brings it
/// back (level-mechanics spec). Drawn as cracked ground (game-visuals
/// spec).
class CrumblingPlatformComponent extends FloorComponent {
  new({required super.position, required super.size, required super.terrain});

  /// How long the ball can stand on it before it collapses, in seconds.
  static const delay = 0.6;

  /// How long it takes to fade once collapsed, in seconds.
  static const fadeDuration = 0.35;

  /// How far it shakes, in meters.
  static const shakeAmount = 0.05;

  /// Seconds since the ball first stood on it; null before that.
  double? _standing;

  /// Seconds since it collapsed; null while it stands.
  double? _collapsed;

  /// Whether the ball has stood on it and it is about to fall.
  bool get isShaking => _standing != null && _collapsed == null;

  /// Whether it has fallen away.
  bool get isCollapsed => _collapsed != null;

  @override
  bool supports(Vector2 center) => !isCollapsed && super.supports(center);

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallComponent && _standing == null) {
      if (supports(other.body.position)) _standing = 0;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    final collapsed = _collapsed;
    if (collapsed != null) {
      _collapsed = collapsed + dt;
      return;
    }
    final standing = _standing;
    if (standing == null) return;
    _standing = standing + dt;
    if (_standing! >= delay) {
      _collapsed = 0;
      body.isEnabled = false;
    }
  }

  /// Brings it back as it was: after a respawn (level-mechanics spec).
  void restore() {
    _standing = null;
    _collapsed = null;
    body.isEnabled = true;
  }

  @override
  void render(Canvas canvas) {
    final collapsed = _collapsed;
    final opacity = collapsed == null
        ? 1.0
        : (1 - collapsed / fadeDuration).clamp(0.0, 1.0);
    if (opacity == 0) return;
    final standing = _standing;
    final shake = standing == null
        ? 0.0
        : shakeAmount * math.sin(standing * 70);
    // Falls away as it fades.
    final drop = collapsed == null ? 0.0 : collapsed * collapsed * 6;
    canvas
      ..save()
      ..translate(shake, drop);
    if (opacity < 1) {
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
    }
    super.render(canvas);
    _cracks(canvas);
    if (opacity < 1) canvas.restore();
    canvas.restore();
  }

  /// Dark cracks with light edges across the top, so it reads as fragile.
  void _cracks(Canvas canvas) {
    final left = -size.x / 2;
    final top = -size.y / 2;
    final crack = Path();
    for (var x = left + 0.35; x < -left - 0.2; x += 0.7) {
      crack
        ..moveTo(x, top)
        ..lineTo(x + 0.1, top + 0.25)
        ..lineTo(x - 0.05, top + 0.45)
        ..lineTo(x + 0.08, top + 0.7);
    }
    canvas
      ..drawPath(
        crack.shift(const Offset(0.025, 0)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.03
          ..color = const Color(0x55FFFFFF),
      )
      ..drawPath(
        crack,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.05
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xCC0E0B16),
      );
  }
}
