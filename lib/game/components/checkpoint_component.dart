import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';

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

  static final _idle = Paint()..color = const Color(0xFF43A047);
  static final _active = Paint()..color = const Color(0xFFFFC107);

  bool _activated = false;

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
      onActivated(this);
    }
  }

  @override
  void render(Canvas canvas) {
    // A post with a flag that turns gold once activated.
    final paint = _activated ? _active : _idle;
    canvas
      ..drawRect(
        Rect.fromLTWH(-0.05, size.y / 2 - postHeight, 0.1, postHeight),
        paint,
      )
      ..drawRect(
        Rect.fromLTWH(0.05, size.y / 2 - postHeight, 0.5, 0.35),
        paint,
      );
  }
}
