import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' show VertexMode, Vertices;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart'
    show CurvedRun, FloorSurface;
import 'package:puzzle_ball_gklabs/game/components/ground_surface.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_paint.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_textures.dart';

/// A hill or a half-pipe: one static chain through the curve's points, so
/// the ball rolls over it without catching on a seam (design D1 of
/// add-curved-terrain-and-physics).
///
/// Drawn like the floor runs around it: the terrain body down to [bottom],
/// darkening with depth, and the surface material bent along the curve
/// (game-visuals spec).
class CurvedTerrainComponent extends BodyComponent
    with ContactCallbacks
    implements GroundSurface {
  new({required this.curve, required this.bottom, required this.terrain})
    : super(renderBody: false);

  /// The curve's top surface.
  final CurvedRun curve;

  /// How far down the terrain is drawn, in world y.
  final double bottom;

  final TerrainPaint terrain;

  /// The chain's friction, as the floor runs'.
  static const friction = 0.8;

  @override
  FloorSurface get floorSurface => FloorSurface.plain;

  @override
  bool supports(Vector2 center) =>
      center.x >= curve.left - GroundSurface.edgeTolerance &&
      center.x <= curve.right + GroundSurface.edgeTolerance &&
      center.y < curve.heightAt(center.x);

  @override
  Body createBody() {
    final first = curve.points.first;
    final last = curve.points.last;
    final body = world.createBody(BodyDef(userData: this));
    final chain = body.createChain(
      ChainDef(
        // Listed left to right, the walkable side faces up; the ends are
        // ghosts continuing the floor runs on either side.
        points: [
          Vector2(first.x - 1, first.y),
          for (final point in curve.points) Vector2(point.x, point.y),
          Vector2(last.x + 1, last.y),
        ],
        materials: [SurfaceMaterial(friction: friction)],
      ),
    );
    // Chain segments report no contacts unless asked to.
    for (final segment in chain.segments) {
      segment.contactEventsEnabled = true;
    }
    return body;
  }

  late final Path _fill = Path()
    ..moveTo(curve.left, bottom)
    ..addPolygon([
      Offset(curve.left, bottom),
      for (final point in curve.points) Offset(point.x, point.y),
      Offset(curve.right, bottom),
    ], true);
  late final Rect _bounds = _fill.getBounds();
  late final Paint _body = terrain.body(Vector2.zero());
  late final Paint _depth = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x73000000)],
    ).createShader(_bounds);

  /// The surface strip, bent along the curve: two vertices per point, its
  /// texture running along the curve.
  late final Vertices _strip = _bend();
  late final Paint _surface = Paint()
    ..filterQuality = FilterQuality.medium
    ..shader = ImageShader(
      terrain.textures.surface,
      TileMode.repeated,
      TileMode.decal,
      Float64List.fromList([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]),
    );

  Vertices _bend() {
    const pixels = TerrainTextures.pixelsPerMeter;
    const above = TerrainPaint.surfaceOverhang;
    const below = TerrainPaint.surfaceHeight - above;
    final points = curve.points;
    final positions = <Offset>[];
    final texture = <Offset>[];
    var along = curve.left;
    for (var i = 0; i < points.length; i++) {
      final before = points[math.max(0, i - 1)];
      final after = points[math.min(points.length - 1, i + 1)];
      final dx = after.x - before.x;
      final dy = after.y - before.y;
      final length = math.sqrt(dx * dx + dy * dy);
      // The upward normal, in world y growing downwards.
      final nx = dy / length;
      final ny = -dx / length;
      if (i > 0) {
        final previous = points[i - 1];
        final sx = points[i].x - previous.x;
        final sy = points[i].y - previous.y;
        along += math.sqrt(sx * sx + sy * sy);
      }
      final point = points[i];
      positions
        ..add(Offset(point.x + nx * above, point.y + ny * above))
        ..add(Offset(point.x - nx * below, point.y - ny * below));
      texture
        ..add(Offset(along * pixels, 0))
        ..add(Offset(along * pixels, TerrainTextures.surfaceHeight.toDouble()));
    }
    return Vertices(
      VertexMode.triangleStrip,
      positions,
      textureCoordinates: texture,
    );
  }

  /// The drawn area in world coordinates, to skip drawing when off screen.
  late final Rect _worldBounds = _bounds.inflate(TerrainPaint.surfaceHeight);

  @override
  void render(Canvas canvas) {
    if (!game.camera.visibleWorldRect.overlaps(_worldBounds)) return;
    canvas
      ..drawPath(_fill, _body)
      ..drawPath(_fill, _depth)
      ..drawVertices(_strip, BlendMode.srcOver, _surface);
  }
}
