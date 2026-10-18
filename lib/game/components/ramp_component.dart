import 'dart:math' as math;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_paint.dart';

/// A ramp: a static triangle joining two floor runs, drawn with the world's
/// terrain textures, its surface material following the slope.
class RampComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.position,
    required this.size,
    required this.terrain,
    this.inverted = false,
    this.friction = 0.6,
  }) : super(renderBody: false);

  /// Top-left corner of the ramp's box, in meters.
  @override
  final Vector2 position;
  final Vector2 size;
  final TerrainPaint terrain;

  /// High on its left (a descent) instead of its right.
  final bool inverted;
  final double friction;

  late final List<Vector2> vertices = inverted
      ? [
          Vector2(-size.x / 2, size.y / 2),
          Vector2(size.x / 2, size.y / 2),
          Vector2(-size.x / 2, -size.y / 2),
        ]
      : [
          Vector2(-size.x / 2, size.y / 2),
          Vector2(size.x / 2, size.y / 2),
          Vector2(size.x / 2, -size.y / 2),
        ];

  late final Path _triangle = Path()
    ..addPolygon([for (final v in vertices) Offset(v.x, v.y)], true);
  late final Rect _bounds = Rect.fromCenter(
    center: Offset.zero,
    width: size.x,
    height: size.y,
  );
  late final Paint _body = terrain.body(position + size / 2);
  late final Paint _depth = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x73000000)],
    ).createShader(_bounds);

  /// The slope, from its low end to its high end, as start, angle and
  /// length.
  late final Offset _slopeStart = inverted
      ? Offset(size.x / 2, size.y / 2)
      : Offset(-size.x / 2, size.y / 2);
  late final double _slopeAngle = inverted
      ? math.atan2(-size.y, -size.x)
      : math.atan2(-size.y, size.x);
  late final double _slopeLength = math.sqrt(size.x * size.x + size.y * size.y);
  late final Rect _strip = Rect.fromLTWH(
    0,
    -TerrainPaint.surfaceOverhang,
    _slopeLength,
    TerrainPaint.surfaceHeight,
  );
  late final Paint _surface = terrain.surface(left: 0, top: _strip.top);

  @override
  Body createBody() {
    return world.createBody(BodyDef(position: position + size / 2))
      ..createShape(
        Polygon(vertices),
        ShapeDef(
          material: SurfaceMaterial(friction: friction),
          enableContactEvents: true,
          userData: this,
        ),
      );
  }

  /// The drawn area in world coordinates, to skip drawing when off screen.
  late final Rect _worldBounds = _bounds
      .inflate(TerrainPaint.surfaceHeight)
      .shift(Offset(position.x + size.x / 2, position.y + size.y / 2));

  @override
  void render(Canvas canvas) {
    if (!game.camera.visibleWorldRect.overlaps(_worldBounds)) return;
    canvas
      ..save()
      ..clipPath(_triangle)
      ..drawRect(_bounds, _body)
      ..drawRect(_bounds, _depth)
      ..restore()
      ..save()
      ..translate(_slopeStart.dx, _slopeStart.dy)
      ..rotate(_slopeAngle);
    // Descending ramps draw the strip from their low end leftwards, so it
    // is flipped to keep the material's top up.
    if (inverted) canvas.scale(1, -1);
    canvas
      ..drawRect(_strip, _surface)
      ..restore();
  }
}
