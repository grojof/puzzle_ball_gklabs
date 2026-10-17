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

  /// The rules [level] breaks with [margin]; empty when it is valid.
  List<String> validate(LevelData level, {required double margin}) {
    final violations = <String>[];
    final floors = level.floors;
    if (floors.isEmpty) return ['the level has no floor'];

    _checkStartAndGoal(level, violations);
    _checkElementsAboveGround(level, violations);

    final rampsByLeft = {for (final ramp in level.ramps) ramp.left: ramp};
    var speed = 0.0;
    for (var i = 0; i < floors.length; i++) {
      final floor = floors[i];
      speed = envelope.speedAfter(floor.size.x, startSpeed: speed);
      if (i == floors.length - 1) break;
      final next = floors[i + 1];
      if (next.left < floor.right - _epsilon) {
        violations.add('floors overlap at x=${floor.right}');
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
          final limit = boost == BoostType.jump
              ? envelope.maxBoostedClimb(margin)
              : envelope.maxClimb(margin);
          if (rise > limit + _epsilon) {
            violations.add('climb of $rise at x=${next.left} exceeds $limit');
          }
          if (next.position.y + next.size.y < floor.top - _epsilon) {
            violations.add('ledge at x=${next.left} leaves a gap below');
          }
          speed *= 0.5;
        }
        continue;
      }
      var limit = envelope.maxGap(speed: speed, rise: rise, margin: margin);
      if (boost == BoostType.speed) {
        limit = envelope.maxSpeedBoostGap(margin);
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
      if (boost == BoostType.speed) speed = envelope.topSpeed;
    }
    return violations;
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
    final positions = [
      for (final boost in level.boosts) ('boost', boost.position),
      for (final checkpoint in level.checkpoints)
        ('checkpoint', checkpoint.position),
    ];
    for (final (name, position) in positions) {
      final grounded = level.floors.any(
        (floor) =>
            position.x >= floor.left &&
            position.x <= floor.right &&
            floor.top - position.y > 0 &&
            floor.top - position.y <= 1.2,
      );
      if (!grounded) violations.add('$name at $position is not above ground');
    }
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
