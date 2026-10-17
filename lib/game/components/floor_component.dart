import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show tileSize;

/// A floor run: one static body for a whole run of ground (design D4).
///
/// The top row is drawn with the tile sprite, repeated; the rest of the run's
/// height, under ledges, is filled with earth. Only the tiles inside the
/// camera's view are drawn.
class FloorComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.position,
    required this.size,
    this.sprite,
    this.friction = 0.8,
  }) : super(renderBody: false);

  /// Top-left corner, in meters.
  @override
  final Vector2 position;

  /// Width and height, in meters.
  final Vector2 size;
  final Sprite? sprite;
  final double friction;

  static final _earth = Paint()..color = const Color(0xFF4E342E);
  static final _plain = Paint()..color = const Color(0xFFE0E0E0);

  @override
  Body createBody() {
    return world.createBody(BodyDef(position: position + size / 2))
      ..createShape(
        Polygon.box(size.x / 2, size.y / 2),
        ShapeDef(
          material: SurfaceMaterial(friction: friction),
          enableContactEvents: true,
          userData: this,
        ),
      );
  }

  @override
  void render(Canvas canvas) {
    final left = -size.x / 2;
    final top = -size.y / 2;
    if (size.y > tileSize) {
      canvas.drawRect(
        Rect.fromLTWH(left, top + tileSize, size.x, size.y - tileSize),
        _earth,
      );
    }
    final tile = sprite;
    if (tile == null) {
      canvas.drawRect(Rect.fromLTWH(left, top, size.x, tileSize), _plain);
      return;
    }
    // Draw only the columns the camera can see.
    final view = game.camera.visibleWorldRect;
    final first = math.max(0, ((view.left - position.x) / tileSize).floor());
    final last = math.min(
      (size.x / tileSize).ceil() - 1,
      ((view.right - position.x) / tileSize).floor(),
    );
    final tileVector = Vector2.all(tileSize);
    for (var column = first; column <= last; column++) {
      final width = math.min(tileSize, size.x - column * tileSize);
      tile.render(
        canvas,
        position: Vector2(left + column * tileSize, top),
        size: width < tileSize ? Vector2(width, tileSize) : tileVector,
      );
    }
  }
}
