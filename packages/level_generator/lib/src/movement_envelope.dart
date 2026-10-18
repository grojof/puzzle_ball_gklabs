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
    required this.speedCurve,
    required this.jumpBoostHeight,
    required this.speedBoostJumpDistance,
    required this.speedBoostGain,
    required this.gravityBoostJumpDistance,
    required this.doubleJumpHeight,
    required this.doubleJumpDistance,
  });

  /// Height of a standing jump, in meters.
  final double jumpHeight;

  /// Air time of a jump that lands at its take-off height, in seconds.
  final double flightTime;

  /// Top horizontal speed while pushing, in m/s.
  final double topSpeed;

  /// The speed after pushing from rest over `n × curveStep` meters, for
  /// n = 1, 2, …: measured with the real ball and rounded down. Past its end
  /// the speed stays at its last value.
  final List<double> speedCurve;

  /// The distance between [speedCurve] samples, in meters.
  static const double curveStep = 0.75;

  /// Height reached from a jump boost, without jumping, in meters.
  final double jumpBoostHeight;

  /// Distance of a jump taken right after a speed boost picked up at top
  /// speed, in meters.
  final double speedBoostJumpDistance;

  /// The speed a speed boost adds, in m/s.
  final double speedBoostGain;

  /// Distance of a jump taken at top speed during a gravity boost, in meters.
  final double gravityBoostJumpDistance;

  /// Height of a jump followed by an air jump at its apex, in meters.
  final double doubleJumpHeight;

  /// Distance of a running jump at top speed with an air jump at its apex,
  /// in meters.
  final double doubleJumpDistance;

  /// Speed reached after pushing over [distance] meters, starting at
  /// [startSpeed]: read on [speedCurve] from where it reaches [startSpeed].
  /// Only exact operations, so it is the same on every platform.
  double speedAfter(double distance, {double startSpeed = 0}) =>
      math.min(topSpeed, _speedAt(_distanceFor(startSpeed) + distance));

  /// The curve's speed after [distance] meters from rest.
  double _speedAt(double distance) {
    if (distance <= 0) return 0;
    final position = distance / curveStep;
    final index = position.floor();
    if (index >= speedCurve.length) return speedCurve.last;
    final lower = index == 0 ? 0.0 : speedCurve[index - 1];
    final upper = speedCurve[index];
    return lower + (upper - lower) * (position - index);
  }

  /// The distance from rest at which the curve reaches [speed].
  double _distanceFor(double speed) {
    if (speed <= 0) return 0;
    var lower = 0.0;
    for (var index = 0; index < speedCurve.length; index++) {
      final upper = speedCurve[index];
      if (speed <= upper) {
        return (index + (speed - lower) / (upper - lower)) * curveStep;
      }
      lower = upper;
    }
    return speedCurve.length * curveStep;
  }

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

  /// The widest gap after a speed boost picked up at [speed], scaled by
  /// [margin]. The boost adds [speedBoostGain] to the speed it finds, and a
  /// jump's distance grows with its launch speed: scaling the measured jump
  /// by the launch speed stays within it, as the push in the air adds a
  /// share that does not shrink.
  double maxSpeedBoostGap({required double speed, required double margin}) =>
      margin *
      speedBoostJumpDistance *
      math.min(1, (speed + speedBoostGain) / (topSpeed + speedBoostGain));

  /// The highest ledge a jump with an air jump reaches, scaled by [margin].
  double maxDoubleJumpClimb(double margin) => margin * doubleJumpHeight;

  /// The widest gap a jump with an air jump clears at [speed], scaled by
  /// [margin].
  double maxDoubleJumpGap({required double speed, required double margin}) =>
      margin * doubleJumpDistance * math.min(1, speed / topSpeed);

  /// The widest gap during a gravity boost at [speed], scaled by [margin].
  double maxGravityBoostGap({required double speed, required double margin}) =>
      margin * gravityBoostJumpDistance * math.min(1, speed / topSpeed);
}
