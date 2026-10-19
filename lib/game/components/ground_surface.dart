import 'package:flame/components.dart';
import 'package:level_generator/level_generator.dart' show FloorSurface;

/// Terrain the ball can stand on: floors, ramps and curves.
abstract interface class GroundSurface {
  /// How far past a surface's ends the ball still counts as standing on it,
  /// in meters: rolling over an edge.
  static const edgeTolerance = 0.1;

  /// Whether a ball centered at [center], touching this surface, stands on
  /// its top rather than against its side.
  bool supports(Vector2 center);

  /// What the top is made of, which changes how the ball moves on it
  /// (level-mechanics spec).
  FloorSurface get floorSurface;
}
