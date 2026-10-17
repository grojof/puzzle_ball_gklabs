import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';

/// A checkpoint: the ball activates it by passing through, and respawns
/// above the last active one after a fall (game-session spec).
class CheckPointComponent extends BodyComponent with ContactCallbacks {
  new({required this.position, required this.size, required this.onActivated})
    : super(renderBody: false);

  /// Centre of the sensor, in meters.
  @override
  final Vector2 position;
  final Vector2 size;

  /// Called once, when the ball first passes the checkpoint.
  final void Function(CheckPointComponent checkpoint) onActivated;

  static final _idle = Paint()..color = const Color(0xFF43A047);
  static final _active = Paint()..color = const Color(0xFFFFC107);

  bool _activated = false;

  bool get isActivated => _activated;

  /// Where the ball reappears: at rest, a little above the checkpoint.
  Vector2 get respawnPoint => Vector2(position.x, position.y - 0.75);

  @override
  Body createBody() {
    return world.createBody(BodyDef(position: position))..createShape(
      Polygon.box(size.x / 2, size.y / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallComponent && !_activated) {
      _activated = true;
      onActivated(this);
    }
  }

  @override
  void render(Canvas canvas) {
    // A post with a flag that turns gold once activated.
    final paint = _activated ? _active : _idle;
    canvas
      ..drawRect(Rect.fromLTWH(-0.05, size.y / 2 - 1.6, 0.1, 1.6), paint)
      ..drawRect(Rect.fromLTWH(0.05, size.y / 2 - 1.6, 0.5, 0.35), paint);
  }
}
