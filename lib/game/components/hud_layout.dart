import 'dart:math' as math;

import 'package:flame/components.dart';

/// Sizes and margins of the on-screen controls, from the screen size, so
/// they fit the thumb in portrait and landscape (player-controls spec,
/// design D7).
abstract final class HudLayout {
  /// The smallest and largest control, in logical pixels.
  static const minControlSize = 72.0;
  static const maxControlSize = 120.0;

  /// The width of a control across, for a [screen] size.
  static double controlSize(Vector2 screen) =>
      (0.22 * _shortSide(screen)).clamp(minControlSize, maxControlSize);

  /// The distance from the screen edges to each control.
  static double margin(Vector2 screen) =>
      math.max(16, 0.04 * _shortSide(screen));

  static double _shortSide(Vector2 screen) => math.min(screen.x, screen.y);
}
