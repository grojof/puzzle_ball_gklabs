import 'dart:math' as math;

import 'package:level_generator/src/level_data.dart';
import 'package:level_generator/src/movement_envelope.dart';

/// How far either side of a laser barrier the route is checked, in meters:
/// farther than any gap, so a jump from higher ground across a long falling
/// gap counts.
const laserWindow = 18.0;

/// The extra room between a barrier's lower end and the route's highest
/// jump, in meters: the ball's diameter, the envelope's rounding down, and
/// some air.
const laserMargin = 1.0;

/// How much higher than a plain jump the ball may fly off the top of a ramp
/// up, jumping as it leaves: the clearance near one, in meters.
const rampClearance = 4.5;

/// The route around a laser barrier: the ground and what launches the ball,
/// so a barrier can hang above everything the intended route reaches
/// (design D9 of raise-difficulty-and-pace).
class LaserClearance {
  /// The route made of [floors], [ramps], [platforms] and [boosts].
  const new({
    required this.envelope,
    required this.floors,
    required this.ramps,
    required this.platforms,
    required this.boosts,
  });

  /// What the ball can do.
  final MovementEnvelope envelope;

  /// The route's floor runs.
  final List<FloorRun> floors;

  /// The route's ramps.
  final List<Ramp> ramps;

  /// The route's moving platforms.
  final List<MovingPlatform> platforms;

  /// The route's boosts and orbs.
  final List<Boost> boosts;

  bool _near(double left, double right, double x) =>
      right >= x - laserWindow && left <= x + laserWindow;

  /// The highest ground (smallest world y) within [laserWindow] of [x], or
  /// null with none.
  double? highestGround(double x) {
    double? high;
    void see(double top) => high = high == null ? top : math.min(high!, top);
    for (final floor in floors) {
      if (_near(floor.left, floor.right, x)) see(floor.top);
    }
    for (final ramp in ramps) {
      if (_near(ramp.left, ramp.right, x)) see(ramp.top);
    }
    for (final platform in platforms) {
      final left = math.min(platform.start.x, platform.end.x);
      final right =
          math.max(platform.start.x, platform.end.x) + platform.size.x;
      if (_near(left, right, x)) {
        see(math.min(platform.start.y, platform.end.y));
      }
    }
    return high;
  }

  /// How high the route's jumps may rise near [x], above its ground, in
  /// meters: a plain jump's, a ramp launch's, an orb's double jump's or a
  /// jump boost's. Null where a gravity boost serves, whose floaty jumps
  /// rise too high for a barrier.
  double? clearance(double x) {
    var clearance = envelope.jumpHeight;
    for (final boost in boosts) {
      if ((boost.position.x - x).abs() > laserWindow) continue;
      switch (boost.type) {
        case BoostType.gravity:
          return null;
        case BoostType.jump:
          clearance = math.max(clearance, envelope.jumpBoostHeight);
        case BoostType.doubleJump:
          clearance = math.max(clearance, envelope.doubleJumpHeight);
        case BoostType.speed:
          break;
      }
    }
    for (final ramp in ramps) {
      if (ramp.ascending && _near(ramp.left, ramp.right, x)) {
        clearance = math.max(clearance, rampClearance);
      }
    }
    return clearance;
  }

  /// The highest a barrier's lower end may hang at [x], in world y: above
  /// every jump of the route around it. Null where no barrier may go.
  double? lowestEnd(double x) {
    final ground = highestGround(x);
    final rise = clearance(x);
    if (ground == null || rise == null) return null;
    return ground - rise - laserMargin;
  }
}
