import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show tileSize;

/// A floor run: one static body for a whole run of ground (design D4).
///
/// The top row is drawn with the tile sprite, repeated; the rest of the run's
/// height, under ledges, with the earth part of the tile. Only the tiles
/// inside the camera's view are drawn.
class FloorComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.position,
    required this.size,
    required this.sprite,
    this.friction = 0.8,
  }) : super(renderBody: false);

  /// Top-left corner, in meters.
  @override
  final Vector2 position;

  /// Width and height, in meters.
  final Vector2 size;
  final Sprite sprite;
  final double friction;

  /// The part of the tile below the grass.
  static const _earthFraction = 0.75;

  /// The tile's earth, for the fill under ledges.
  late final Sprite _earth = Sprite(
    sprite.image,
    srcPosition: Vector2(0, sprite.srcSize.y * (1 - _earthFraction)),
    srcSize: Vector2(sprite.srcSize.x, sprite.srcSize.y * _earthFraction),
  );

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
    // Draw only the columns the camera can see.
    final view = game.camera.visibleWorldRect;
    final first = math.max(0, ((view.left - position.x) / tileSize).floor());
    final last = math.min(
      (size.x / tileSize).ceil() - 1,
      ((view.right - position.x) / tileSize).floor(),
    );
    if (last < first) return;
    canvas
      ..save()
      ..clipRect(Rect.fromLTWH(left, top, size.x, size.y));
    final tileVector = Vector2.all(tileSize);
    final earthVector = Vector2(tileSize, tileSize * _earthFraction);
    for (var column = first; column <= last; column++) {
      final x = left + column * tileSize;
      sprite.render(canvas, position: Vector2(x, top), size: tileVector);
      for (var y = top + tileSize; y < top + size.y; y += earthVector.y) {
        _earth.render(canvas, position: Vector2(x, y), size: earthVector);
      }
    }
    canvas.restore();
  }
}
