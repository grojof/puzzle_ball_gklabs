import 'dart:math' as math;

import 'package:meta/meta.dart';

/// What the ball can do, measured with the game's real physics.
///
/// The generator keeps every gap and climb within these limits, scaled by a
/// safety margin; the game proves its physics reaches them (design D3).
@immutable
class MovementEnvelope {
  /// An envelope from measured abilities.
  const new({
    required this.jumpHeight,
    required this.flightTime,
    required this.topSpeed,
    required this.timeToTopSpeed,
    required this.jumpBoostHeight,
    required this.speedBoostJumpDistance,
    required this.gravityBoostJumpDistance,
  });

  /// Height of a standing jump, in meters.
  final double jumpHeight;

  /// Air time of a jump that lands at its take-off height, in seconds.
  final double flightTime;

  /// Top horizontal speed while pushing, in m/s.
  final double topSpeed;

  /// Time to reach [topSpeed] from rest, as uniform acceleration (which
  /// underestimates the real, faster start, so it errs on the safe side).
  final double timeToTopSpeed;

  /// Height reached from a jump boost, without jumping, in meters.
  final double jumpBoostHeight;

  /// Distance of a jump taken right after a speed boost, in meters.
  final double speedBoostJumpDistance;

  /// Distance of a jump taken at top speed during a gravity boost, in meters.
  final double gravityBoostJumpDistance;

  /// Horizontal acceleration while pushing, in m/s².
  double get acceleration => topSpeed / timeToTopSpeed;

  /// Speed reached after pushing over [distance] meters, starting at
  /// [startSpeed].
  double speedAfter(double distance, {double startSpeed = 0}) => math.min(
    topSpeed,
    math.sqrt(startSpeed * startSpeed + 2 * acceleration * distance),
  );

  /// Air time of a jump landing [rise] meters above its take-off (negative
  /// when landing lower), or null when the landing is out of reach.
  ///
  /// Uses the ballistic arc fitted to [jumpHeight] and [flightTime].
  double? airTime(double rise) {
    final gravity = 8 * jumpHeight / (flightTime * flightTime);
    final launch = 4 * jumpHeight / flightTime;
    final discriminant = launch * launch - 2 * gravity * rise;
    if (discriminant < 0) return null;
    return (launch + math.sqrt(discriminant)) / gravity;
  }

  /// Time to fall [height] meters without jumping, on the same fitted arc.
  double fallTime(double height) =>
      math.sqrt(2 * height * flightTime * flightTime / (8 * jumpHeight));

  /// The widest gap a jump at [speed] can clear, landing [rise] meters
  /// higher, scaled by [margin].
  double maxGap({
    required double speed,
    required double rise,
    required double margin,
  }) {
    if (rise > maxClimb(margin)) return 0;
    final time = airTime(rise);
    return time == null ? 0 : margin * speed * time;
  }

  /// The highest ledge a standing jump can reach, scaled by [margin].
  double maxClimb(double margin) => margin * jumpHeight;

  /// The highest ledge a jump boost can reach, scaled by [margin].
  double maxBoostedClimb(double margin) => margin * jumpBoostHeight;

  /// The widest gap after a speed boost, scaled by [margin].
  double maxSpeedBoostGap(double margin) => margin * speedBoostJumpDistance;

  /// The widest gap during a gravity boost at [speed], scaled by [margin].
  double maxGravityBoostGap({required double speed, required double margin}) =>
      margin * gravityBoostJumpDistance * math.min(1, speed / topSpeed);
}
