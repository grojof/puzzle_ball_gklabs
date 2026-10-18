import 'dart:typed_data';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_textures.dart';

/// Paints for terrain drawn from a world's [TerrainTextures] (design D3).
///
/// The body texture is anchored in world coordinates, so neighboring floor
/// runs and ramps line up without seams.
class TerrainPaint {
  new(this.textures);

  final TerrainTextures textures;

  /// Meters per texture pixel.
  static const double _scale = 1 / TerrainTextures.pixelsPerMeter;

  /// Height of the surface strip, in meters.
  static const double surfaceHeight =
      TerrainTextures.surfaceHeight / TerrainTextures.pixelsPerMeter;

  /// How far the surface strip rises above the ground line, in meters.
  static const double surfaceOverhang =
      surfaceHeight * TerrainTextures.overhangFraction;

  /// The body paint for a component whose local origin is at [origin] in
  /// world coordinates.
  Paint body(Vector2 origin) => Paint()
    ..filterQuality = FilterQuality.medium
    ..shader = ImageShader(
      textures.body,
      TileMode.repeated,
      TileMode.repeated,
      _matrix(-origin.x, -origin.y),
    );

  /// The surface paint for a strip whose top-left corner is at [left],
  /// [top] in the component's local coordinates, with its texture anchored
  /// horizontally at world x 0 when [originX] is the component's world x.
  Paint surface({
    required double left,
    required double top,
    double originX = 0,
  }) => Paint()
    ..filterQuality = FilterQuality.medium
    ..shader = ImageShader(
      textures.surface,
      TileMode.repeated,
      TileMode.decal,
      _matrix(-originX, top),
    );

  /// Maps texture pixels to local coordinates: scaled to meters, then moved
  /// by [dx], [dy].
  static Float64List _matrix(double dx, double dy) => Float64List.fromList([
    _scale, 0, 0, 0, //
    0, _scale, 0, 0, //
    0, 0, 1, 0, //
    dx, dy, 0, 1, //
  ]);
}
