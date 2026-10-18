import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart' show EdgeInsets;

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

  /// The pause button of `GamePage`, a small floating action button: its
  /// distance from the top-left corner of the safe area and the side of its
  /// box, with the tap target padding, in logical pixels. The checkpoint
  /// track sits under it (design D1 of add-hud-indicators).
  static const pauseInset = 24.0;
  static const pauseSize = 48.0;

  /// The sound button (`SoundToggleFab`), a mini floating action button: its
  /// distance from the top-right corner of the safe area and the side of its
  /// box. The boost tray sits under it.
  static const soundInset = 12.0;
  static const soundSize = 48.0;

  /// The gap between a button and the indicators under it.
  static const indicatorGap = 6.0;

  /// The height of a checkpoint flag: a fixed indicator, smaller than the
  /// temporary ones (game-hud spec).
  static double flagSize(Vector2 screen) =>
      (0.06 * _shortSide(screen)).clamp(20, 28);

  /// The top-left corner of the checkpoint track, under the pause button,
  /// inside the system's [safeArea].
  static Vector2 trackOrigin(EdgeInsets safeArea) => Vector2(
    safeArea.left + pauseInset + indicatorGap,
    safeArea.top + pauseInset + pauseSize + indicatorGap,
  );

  /// The top-right corner of the boost tray, under the sound button, inside
  /// the system's [safeArea], on a [screen].
  static Vector2 trayOrigin(Vector2 screen, EdgeInsets safeArea) => Vector2(
    screen.x - safeArea.right - soundInset - indicatorGap,
    safeArea.top + soundInset + soundSize + indicatorGap,
  );

  /// The side of a running boost's or the orb's icon: a temporary
  /// indicator, larger than the fixed ones.
  static double boostIconSize(Vector2 screen) =>
      (0.08 * _shortSide(screen)).clamp(28, 40);

  /// The font size of a pickup message.
  static double messageFontSize(Vector2 screen) =>
      (0.05 * _shortSide(screen)).clamp(16, 24);

  static double _shortSide(Vector2 screen) => math.min(screen.x, screen.y);
}
