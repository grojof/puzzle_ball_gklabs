import 'dart:math' as math;

import 'package:level_generator/src/level_data.dart';
import 'package:level_generator/src/movement_envelope.dart';

/// How far either side of a laser barrier boosts, orbs and ramps up raise
/// the route's jumps, in meters: farther than any gap.
const laserWindow = 18.0;

/// How far past a floor run's ends its ground still counts at a barrier,
/// in meters.
const routeSlack = 1.0;

/// How far after a ledge a roll off it looks for the ground it falls to, in
/// meters.
const rollOffReach = 30.0;

/// How much faster than the envelope's top speed a ball may roll off a
/// ledge: the envelope is rounded down.
const rollOffSpeed = 1.1;

/// The extra room between a barrier's lower end and the route's highest
/// jump, in meters: the ball's diameter, the envelope's rounding down, and
/// some air.
const laserMargin = 1.0;

/// How much higher than a plain jump the ball may fly off the top of a ramp
/// up, jumping as it leaves: the clearance near one, in meters.
const rampClearance = 4.5;

/// How far either side of a loop no barrier hangs, in meters (design D7 of
/// add-curved-terrain-and-physics).
const loopClearance = 20.0;

/// How far either side of a mace's swing or a seesaw no barrier hangs, in
/// meters; fans keep [loopClearance], since they lift the ball high
/// (design D6 of add-dynamic-elements).
const dynamicClearance = 6.0;

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
    this.curves = const [],
    this.trampolines = const [],
    this.loops = const [],
    this.adrenaline = const [],
    this.fans = const [],
    this.pendulums = const [],
    this.seesaws = const [],
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

  /// The route's hills and half-pipes.
  final List<CurvedRun> curves;

  /// The route's trampolines.
  final List<Trampoline> trampolines;

  /// The route's loops.
  final List<Loop> loops;

  /// The route's adrenaline zones, where the ball runs faster.
  final List<AdrenalineZone> adrenaline;

  /// The route's fans, which lift the ball to their hover heights.
  final List<Fan> fans;

  /// The route's pendulums.
  final List<Pendulum> pendulums;

  /// The route's seesaws.
  final List<Seesaw> seesaws;

  /// The fastest the ball runs between [left] and [right]: faster in an
  /// adrenaline zone (design D8 of flow-and-pacing).
  double _topSpeed(double left, double right) =>
      adrenaline.any((zone) => zone.right >= left && zone.left <= right)
      ? envelope.rushGain * envelope.topSpeed
      : envelope.topSpeed;

  bool _near(double left, double right, double x) =>
      right >= x - laserWindow && left <= x + laserWindow;

  /// The highest point (smallest world y) the intended route touches at
  /// [x], before its jumps: the ground under [x], and every step from one
  /// floor run to the next that passes over [x], from leaving the first to
  /// landing on the second, as far as a jump carries. Null with none. A
  /// flight that skips floor runs is a shortcut, and is not counted (design
  /// D9 of raise-difficulty-and-pace).
  double? routeTop(double x) {
    double? high;
    void see(double top) => high = high == null ? top : math.min(high!, top);
    bool over(double left, double right) =>
        x >= left - routeSlack && x <= right + routeSlack;
    for (var i = 0; i < floors.length; i++) {
      final floor = floors[i];
      if (over(floor.left, floor.right)) see(floor.top);
      if (i + 1 < floors.length) {
        final next = floors[i + 1];
        final end = math.min(next.right, floor.right + _jumpReach(floor, next));
        if (over(floor.right, end)) see(math.min(floor.top, next.top));
      }
    }
    for (final ramp in ramps) {
      if (over(ramp.left, ramp.right)) see(ramp.top);
    }
    for (final curve in curves) {
      // A fast ball takes off from a crest and flies on past the curve.
      final ground = curve.points.first.y;
      final flight = curve.top < ground
          ? rollOffSpeed *
                envelope.topSpeed *
                envelope.fallTime(ground - curve.top)
          : 0.0;
      if (over(curve.left, curve.right + flight)) see(curve.top);
    }
    for (final platform in platforms) {
      final left = math.min(platform.start.x, platform.end.x);
      final right =
          math.max(platform.start.x, platform.end.x) + platform.size.x;
      if (over(left, right)) see(math.min(platform.start.y, platform.end.y));
    }
    return high;
  }

  /// How far a jump from [floor] towards [next] can carry, in meters: a
  /// plain jump at top speed, or a speed boost's, an orb's or a
  /// trampoline's on [floor].
  double _jumpReach(FloorRun floor, FloorRun next) {
    final rise = floor.top - next.top;
    final time = envelope.airTime(rise) ?? envelope.flightTime;
    var reach = _topSpeed(floor.left, floor.right) * time;
    for (final pad in trampolines) {
      if (pad.right < floor.left || pad.left > floor.right) continue;
      reach = math.max(
        reach,
        envelope.maxTrampolineGap(
          speed: envelope.topSpeed,
          rise: rise,
          margin: 1,
        ),
      );
    }
    for (final boost in boosts) {
      if (boost.position.x < floor.left || boost.position.x > floor.right) {
        continue;
      }
      reach = switch (boost.type) {
        BoostType.speed => math.max(reach, envelope.speedBoostJumpDistance),
        BoostType.doubleJump => math.max(reach, envelope.doubleJumpDistance),
        BoostType.gravity => math.max(reach, envelope.gravityBoostJumpDistance),
        BoostType.jump => reach,
      };
    }
    return rollOffSpeed * reach + routeSlack;
  }

  /// The highest point (smallest world y) a ball rolling off a ledge, without
  /// jumping, passes at [x]: rolling off at top speed, it can fly over the
  /// runs below before it lands, and that is still the intended route. Null
  /// with none.
  double? rollOffTop(double x) {
    double? high;
    for (var i = 0; i + 1 < floors.length; i++) {
      final ledge = floors[i];
      if (floors[i + 1].top <= ledge.top || x < ledge.right) continue;
      // How far down it can fall: to the lowest ground soon after.
      var lowest = ledge.top;
      for (final floor in floors.skip(i + 1)) {
        if (floor.left > ledge.right + rollOffReach) break;
        lowest = math.max(lowest, floor.top);
      }
      final flight =
          rollOffSpeed *
              _topSpeed(ledge.left, ledge.right) *
              envelope.fallTime(lowest - ledge.top) +
          routeSlack;
      if (x <= ledge.right + flight) {
        high = high == null ? ledge.top : math.min(high, ledge.top);
      }
    }
    return high;
  }

  /// How high the route's jumps may rise near [x], above its ground, in
  /// meters: a plain jump's, a ramp launch's, an orb's double jump's, a
  /// trampoline's or a jump boost's. Null where a gravity boost serves,
  /// whose floaty jumps rise too high for a barrier, and near a loop, a fan,
  /// a mace or a seesaw.
  double? clearance(double x) {
    bool within(double left, double right, double room) =>
        right >= x - room && left <= x + room;
    if (loops.any((loop) => within(loop.left, loop.right, loopClearance)) ||
        fans.any((fan) => within(fan.left, fan.right, loopClearance)) ||
        pendulums.any(
          (pendulum) => within(
            pendulum.pivot.x - pendulum.length - maceRadius,
            pendulum.pivot.x + pendulum.length + maceRadius,
            dynamicClearance,
          ),
        ) ||
        seesaws.any(
          (seesaw) => within(seesaw.left, seesaw.right, dynamicClearance),
        )) {
      return null;
    }
    var clearance = envelope.jumpHeight;
    for (final pad in trampolines) {
      if (_near(pad.left, pad.right, x)) {
        clearance = math.max(clearance, envelope.trampolineHeight);
      }
    }
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
    for (final curve in curves) {
      if (curve.rises && _near(curve.left, curve.right, x)) {
        clearance = math.max(clearance, rampClearance);
      }
    }
    return clearance;
  }

  /// The highest a barrier's lower end may hang at [x], in world y: above
  /// every jump of the intended route there. Null where no barrier may go.
  double? lowestEnd(double x) {
    final ground = routeTop(x);
    final rise = clearance(x);
    if (ground == null || rise == null) return null;
    final jumps = ground - rise;
    final rolling = rollOffTop(x);
    return (rolling == null ? jumps : math.min(jumps, rolling)) - laserMargin;
  }
}
