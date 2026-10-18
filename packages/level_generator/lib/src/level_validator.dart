import 'package:level_generator/src/level_data.dart';
import 'package:level_generator/src/movement_envelope.dart';

/// Checks a [LevelData] against the geometry rules and the movement envelope,
/// from the level's geometry alone (design D7).
///
/// It re-derives the expected speed along the course from the terrain, with
/// the same conservative rules as the generator, and reports every rule a
/// level breaks.
class LevelValidator {
  /// A validator for levels bounded by [envelope].
  const new({required this.envelope});

  /// What the ball can do.
  final MovementEnvelope envelope;

  static const _epsilon = 1e-6;

  /// How far a ferry's ends may stop from the edges they serve, in meters.
  static const ferryReach = 0.3;

  /// The slowest and fastest ferry, in m/s.
  static const ferrySpeeds = (1.5, 3.0);

  /// The rules [level] breaks with [margin]; empty when it is valid.
  List<String> validate(LevelData level, {required double margin}) {
    if (level.floors.isEmpty) return ['the level has no floor'];
    final violations = <String>[];
    _checkStartAndGoal(level, violations);
    _checkElementsAboveGround(level, violations);
    _checkSpikePlacement(level, violations);
    _walk(level, margin, violations);
    return violations;
  }

  /// The share of the full reach each unboosted gap of [level] uses, from
  /// the speed available before it (level-generation spec, precision).
  List<double> gapShares(LevelData level) {
    final shares = <double>[];
    _walk(level, 1, [], shares: shares);
    return shares;
  }

  /// Walks the floors from left to right with the speed available on each,
  /// checking every ramp, climb and gap against [margin].
  void _walk(
    LevelData level,
    double margin,
    List<String> violations, {
    List<double>? shares,
  }) {
    final floors = level.floors;

    final rampsByLeft = {for (final ramp in level.ramps) ramp.left: ramp};
    var speed = 0.0;
    for (var i = 0; i < floors.length; i++) {
      final floor = floors[i];
      if (floor.crumbling && floor.size.x < tileSize - _epsilon) {
        violations.add('crumbling island at x=${floor.left} is too short');
      }
      for (final strip in level.hazards) {
        if (strip.left < floor.left || strip.left > floor.right) continue;
        final before = envelope.speedAfter(
          strip.left - floor.left,
          startSpeed: speed,
        );
        final limit = envelope.maxGap(speed: before, rise: 0, margin: margin);
        if (strip.width > limit * (1 + _epsilon) + _epsilon) {
          violations.add(
            'spikes of ${strip.width} at x=${strip.left} exceed $limit',
          );
        }
      }
      speed = envelope.speedAfter(floor.size.x, startSpeed: speed);
      if (i == floors.length - 1) break;
      final next = floors[i + 1];
      if (next.left < floor.right - _epsilon) {
        violations.add('floors overlap at x=${floor.right}');
        continue;
      }
      final ferry = _ferryAfter(level, floor);
      if (ferry != null) {
        _checkFerry(level, ferry, floor, next, violations);
        speed = speed < ferry.speed ? speed : ferry.speed;
        continue;
      }
      final ramp = rampsByLeft[floor.right];
      final boost = _boostOn(level, floor);
      if (ramp != null) {
        _checkRamp(ramp, floor, next, violations);
        if (ramp.ascending) speed *= 0.7;
        continue;
      }
      final rise = floor.top - next.top;
      final gap = next.left - floor.right;
      if (gap < _epsilon) {
        if (rise > _epsilon) {
          final limit = switch (boost) {
            BoostType.jump => envelope.maxBoostedClimb(margin),
            BoostType.doubleJump => envelope.maxDoubleJumpClimb(margin),
            _ => envelope.maxClimb(margin),
          };
          if (rise > limit + _epsilon) {
            violations.add('climb of $rise at x=${next.left} exceeds $limit');
          }
          if (boost == BoostType.doubleJump &&
              rise <= envelope.maxClimb(margin) + _epsilon) {
            violations.add('orb at x=${floor.right} serves no high climb');
          }
          if (next.position.y + next.size.y < floor.top - _epsilon) {
            violations.add('ledge at x=${next.left} leaves a gap below');
          }
          speed *= 0.5;
        }
        continue;
      }
      final plain = envelope.maxGap(speed: speed, rise: rise, margin: margin);
      var limit = plain;
      if (boost == BoostType.doubleJump) {
        limit = envelope.maxDoubleJumpGap(speed: speed, margin: margin);
        if (gap <= plain + _epsilon) {
          violations.add('orb at x=${floor.right} serves no long gap');
        }
      } else if (boost == BoostType.speed) {
        limit = envelope.maxSpeedBoostGap(speed: speed, margin: margin);
      } else if (boost == BoostType.gravity) {
        final boosted = envelope.maxGravityBoostGap(
          speed: speed,
          margin: margin,
        );
        if (boosted > limit) limit = boosted;
      }
      if (gap > limit * (1 + _epsilon) + _epsilon) {
        violations.add('gap of $gap at x=${floor.right} exceeds $limit');
      }
      if (boost == null) {
        shares?.add(gap / envelope.maxGap(speed: speed, rise: rise, margin: 1));
      }
      if (boost == BoostType.speed) speed = envelope.topSpeed;
    }
  }

  void _checkStartAndGoal(LevelData level, List<String> violations) {
    final first = level.floors.first;
    final last = level.floors.last;
    if (first.size.x < 3 * tileSize - _epsilon) {
      violations.add('start platform shorter than three tiles');
    }
    final start = level.ballStart;
    if (start.x < first.left ||
        start.x > first.left + tileSize ||
        start.y >= first.top) {
      violations.add('ball does not start above the start platform');
    }
    if (last.size.x < 3 * tileSize - _epsilon) {
      violations.add('goal run shorter than three tiles');
    }
    final goal = level.goal;
    if (goal.x < last.left + 2 * tileSize ||
        goal.x > last.right ||
        (goal.y + 1.75 - last.top).abs() > _epsilon) {
      violations.add('goal does not stand at the end of the last run');
    }
  }

  void _checkElementsAboveGround(LevelData level, List<String> violations) {
    bool over(Vec2 position, bool Function(double height) fits) =>
        level.floors.any(
          (floor) =>
              position.x >= floor.left &&
              position.x <= floor.right &&
              fits(floor.top - position.y),
        );
    for (final boost in level.boosts) {
      if (!over(boost.position, (height) => height > 0 && height <= 1.2)) {
        violations.add('boost at ${boost.position} is not above ground');
      }
    }
    for (final checkpoint in level.checkpoints) {
      if (!over(checkpoint.position, (height) => height.abs() < _epsilon)) {
        violations.add(
          'checkpoint at ${checkpoint.position} does not stand on the ground',
        );
      }
    }
  }

  /// Spikes lie on a run, a tile or more from its ends, not on the start or
  /// goal runs, and not under a boost or a checkpoint.
  void _checkSpikePlacement(LevelData level, List<String> violations) {
    final floors = level.floors;
    for (final strip in level.hazards) {
      final index = floors.indexWhere(
        (floor) =>
            (floor.top - strip.top).abs() < _epsilon &&
            strip.left >= floor.left + tileSize - _epsilon &&
            strip.right <= floor.right - tileSize + _epsilon,
      );
      if (index < 0) {
        violations.add('spikes at x=${strip.left} do not lie inside a run');
        continue;
      }
      if (index == 0 || index == floors.length - 1) {
        violations.add('spikes at x=${strip.left} lie on the start or goal');
      }
      bool covers(double x) => x >= strip.left && x <= strip.right;
      if (level.boosts.any((boost) => covers(boost.position.x)) ||
          level.checkpoints.any((point) => covers(point.position.x))) {
        violations.add('spikes at x=${strip.left} lie under an element');
      }
    }
  }

  /// A ferry starts within [ferryReach] of the near edge and ends within it
  /// of the far edge, at their height, moves at one of [ferrySpeeds], and
  /// nothing else stands in its path.
  void _checkFerry(
    LevelData level,
    MovingPlatform ferry,
    FloorRun near,
    FloorRun far,
    List<String> violations,
  ) {
    final reaches =
        ferry.start.x - near.right <= ferryReach + _epsilon &&
        far.left - (ferry.end.x + ferry.size.x) <= ferryReach + _epsilon &&
        ferry.start.x >= near.right - _epsilon &&
        ferry.end.x + ferry.size.x <= far.left + _epsilon;
    final aligned =
        (ferry.start.y - near.top).abs() < _epsilon &&
        (ferry.end.y - far.top).abs() < _epsilon;
    if (!reaches || !aligned) {
      violations.add('ferry at x=${near.right} does not reach its edges');
    }
    final (slowest, fastest) = ferrySpeeds;
    if (ferry.speed < slowest || ferry.speed > fastest) {
      violations.add('ferry at x=${near.right} moves at ${ferry.speed}');
    }
    bool inPath(double x) => x > near.right && x < far.left;
    if (level.boosts.any((boost) => inPath(boost.position.x)) ||
        level.hazards.any((strip) => inPath(strip.left)) ||
        level.ramps.any((ramp) => inPath(ramp.left))) {
      violations.add('something blocks the ferry at x=${near.right}');
    }
  }

  /// The moving platform that crosses the gap after [floor], if any.
  static MovingPlatform? _ferryAfter(LevelData level, FloorRun floor) {
    for (final platform in level.platforms) {
      if ((platform.start.x - floor.right).abs() <= ferryReach + _epsilon) {
        return platform;
      }
    }
    return null;
  }

  void _checkRamp(
    Ramp ramp,
    FloorRun before,
    FloorRun after,
    List<String> violations,
  ) {
    final (startHeight, endHeight) = ramp.ascending
        ? (ramp.bottom, ramp.top)
        : (ramp.top, ramp.bottom);
    final joins =
        (before.top - startHeight).abs() < _epsilon &&
        (after.top - endHeight).abs() < _epsilon &&
        (after.left - ramp.right).abs() < _epsilon;
    if (!joins) {
      violations.add('ramp at x=${ramp.left} does not join its floors');
    }
  }

  /// The type of the boost standing on [floor], if any.
  static BoostType? _boostOn(LevelData level, FloorRun floor) {
    for (final boost in level.boosts) {
      if (boost.position.x >= floor.left && boost.position.x <= floor.right) {
        return boost.type;
      }
    }
    return null;
  }
}
