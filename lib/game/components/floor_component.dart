import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_paint.dart';

/// A floor run: one static body for a whole run of ground (design D4 of the
/// level generator).
///
/// Drawn from the world's generated textures: the body below, darkening
/// with depth, and the surface material along the top (game-visuals spec).
class FloorComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.position,
    required this.size,
    required this.terrain,
    this.friction = 0.8,
  }) : super(renderBody: false);

  /// Top-left corner, in meters.
  @override
  final Vector2 position;

  /// Width and height, in meters.
  final Vector2 size;
  final TerrainPaint terrain;
  final double friction;

  late final Rect _rect = Rect.fromLTWH(
    -size.x / 2,
    -size.y / 2,
    size.x,
    size.y,
  );
  late final Paint _body = terrain.body(position + size / 2);
  late final Rect _strip = Rect.fromLTWH(
    _rect.left,
    _rect.top - TerrainPaint.surfaceOverhang,
    size.x,
    TerrainPaint.surfaceHeight,
  );
  late final Paint _surface = terrain.surface(
    left: _strip.left,
    top: _strip.top,
    originX: position.x + size.x / 2,
  );
  late final Paint _depth = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x73000000)],
    ).createShader(_rect);
  static final _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04
    ..color = const Color(0x59000000);

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

  /// The drawn area in world coordinates, to skip drawing when off screen.
  late final Rect _worldBounds = _strip
      .expandToInclude(_rect)
      .shift(Offset(position.x + size.x / 2, position.y + size.y / 2));

  @override
  void render(Canvas canvas) {
    if (!game.camera.visibleWorldRect.overlaps(_worldBounds)) return;
    canvas
      ..drawRect(_rect, _body)
      ..drawRect(_rect, _depth)
      ..drawLine(_rect.topLeft, _rect.bottomLeft, _edge)
      ..drawLine(_rect.topRight, _rect.bottomRight, _edge)
      ..drawRect(_strip, _surface);
  }
}
