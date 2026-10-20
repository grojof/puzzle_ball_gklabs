import 'package:level_generator/src/laser_clearance.dart';
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

  /// tan(35°): curves are at most this steep, as ramps.
  static const maxSlope = 0.7002075382097097;

  /// The rules [level] breaks with [margin]; empty when it is valid.
  List<String> validate(LevelData level, {required double margin}) {
    if (level.floors.isEmpty) return ['the level has no floor'];
    final violations = <String>[];
    _checkStartAndGoal(level, violations);
    _checkElementsAboveGround(level, violations);
    _checkSpikePlacement(level, violations);
    _checkLasers(level, violations);
    _checkCurves(level, violations);
    _checkTrampolines(level, violations);
    _checkLoops(level, violations);
    _checkSurfaces(level, violations);
    _checkAdrenaline(level, violations);
    _checkFans(level, violations);
    _checkBumpers(level, violations);
    _checkPendulums(level, margin, violations);
    _checkSeesaws(level, violations);
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
    final curvesByLeft = {for (final curve in level.curves) curve.left: curve};
    var speed = 0.0;
    for (var i = 0; i < floors.length; i++) {
      final floor = floors[i];
      // In an adrenaline zone the ball pushes harder.
      final rushing = level.adrenaline.any(
        (zone) => floor.right > zone.left && floor.left < zone.right,
      );
      double along(double distance, double start) => rushing
          ? envelope.rushSpeedAfter(distance, startSpeed: start)
          : envelope.speedOn(floor.surface, distance, startSpeed: start);
      if (floor.crumbling && floor.size.x < tileSize - _epsilon) {
        violations.add('crumbling island at x=${floor.left} is too short');
      } else if (floor.size.x < tileSize - _epsilon) {
        violations.add('floor at x=${floor.left} is shorter than a tile');
      }
      for (final strip in level.hazards) {
        if (strip.left < floor.left || strip.left > floor.right) continue;
        final before = along(strip.left - floor.left, speed);
        final limit = envelope.maxGap(speed: before, rise: 0, margin: margin);
        if (strip.width > limit * (1 + _epsilon) + _epsilon) {
          violations.add(
            'spikes of ${strip.width} at x=${strip.left} exceed $limit',
          );
        }
      }
      speed = along(floor.size.x, speed);
      // Past maces, the player sets off from rest at the last one's lane.
      final lane = _lastLane(level, floor);
      if (lane != null) {
        final fromRest = envelope.speedAfter(floor.right - lane);
        if (fromRest < speed) speed = fromRest;
      }
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
      final seesaw = _seesawAfter(level, floor);
      if (seesaw != null) {
        _checkSeesawGap(seesaw, next, margin, violations);
        speed = envelope.seesawExitSpeed;
        continue;
      }
      final columns = [
        for (final fan in level.fans)
          if (fan.left >= floor.right - _epsilon &&
              fan.right <= next.left + _epsilon)
            fan,
      ];
      if (columns.isNotEmpty) {
        _checkFanGap(columns, floor, next, violations);
        // The player lands from a float, and pushes on from rest.
        speed = 0;
        continue;
      }
      final ramp = rampsByLeft[floor.right];
      final boost = _boostOn(level, floor);
      if (ramp != null) {
        _checkRamp(ramp, floor, next, violations);
        if (ramp.ascending) speed *= 0.7;
        continue;
      }
      final curve = curvesByLeft[floor.right];
      if (curve != null) {
        _checkCurveJoins(curve, floor, next, violations);
        // Pushing climbs out of any curve at this speed or more; a slope
        // down only adds.
        final down = curve.kind == CurveKind.slope && !curve.rises;
        if (!down) speed = envelope.curveExitSpeed;
        continue;
      }
      final pad = _padOn(level, floor);
      final rise = floor.top - next.top;
      final gap = next.left - floor.right;
      if (gap < _epsilon) {
        final climb = _climbOf(level, floor, next);
        if (climb != null) {
          _checkClimb(climb, floor, next, margin, violations);
          speed = 0;
          continue;
        }
        final lift = _floorFan(level, floor);
        if (rise > _epsilon && lift != null) {
          if (next.top - lift.hover < envelope.fanClearance - _epsilon) {
            violations.add(
              'fan at x=${lift.left} does not lift above the wall',
            );
          }
          speed = 0;
          continue;
        }
        if (rise > _epsilon) {
          final limit = switch (boost) {
            BoostType.jump => envelope.maxBoostedClimb(margin),
            BoostType.doubleJump => envelope.maxDoubleJumpClimb(margin),
            _ => envelope.maxClimb(margin, surface: floor.surface),
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
        // A trampoline only ever stands before a pit.
        if (pad != null) {
          violations.add('trampoline at x=${pad.left} serves no pit');
        }
        continue;
      }
      final plain = envelope.maxGap(
        speed: speed,
        rise: rise,
        margin: margin,
        surface: floor.surface,
      );
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
      if (pad != null) {
        // The ball bounces where it lands on the pad: counted from its middle.
        final bounced =
            margin *
            (envelope.maxTrampolineGap(speed: speed, rise: rise, margin: 1) -
                pad.width / 2);
        if (bounced > limit) limit = bounced;
      }
      if (gap > limit * (1 + _epsilon) + _epsilon) {
        violations.add('gap of $gap at x=${floor.right} exceeds $limit');
      }
      if (boost == null && pad == null) {
        final reach = envelope.maxGap(
          speed: speed,
          rise: rise,
          margin: 1,
          surface: floor.surface,
        );
        shares?.add(gap / reach);
      }
      if (boost == BoostType.speed) speed = envelope.topSpeed;
    }
  }

  /// Where the lane of the last mace over [floor] starts, if any.
  static double? _lastLane(LevelData level, FloorRun floor) {
    double? lane;
    for (final pendulum in level.pendulums) {
      if (pendulum.pivot.x < floor.left || pendulum.pivot.x > floor.right) {
        continue;
      }
      final start = pendulum.left - ballRadius;
      if (lane == null || start > lane) lane = start;
    }
    return lane;
  }

  /// The seesaw whose near end rests just past [floor], if any.
  static Seesaw? _seesawAfter(LevelData level, FloorRun floor) {
    for (final seesaw in level.seesaws) {
      final near = seesaw.nearEnd;
      if (near.x >= floor.right - _epsilon &&
          near.x <= floor.right + seesawCrack + _epsilon &&
          (near.y - floor.top).abs() < _epsilon) {
        return seesaw;
      }
    }
    return null;
  }

  /// The fan set in [floor] at its right end, if any.
  static Fan? _floorFan(LevelData level, FloorRun floor) {
    for (final fan in level.fans) {
      if ((fan.base - floor.top).abs() < _epsilon &&
          (fan.right - floor.right).abs() < _epsilon &&
          fan.left >= floor.left - _epsilon) {
        return fan;
      }
    }
    return null;
  }

  /// The bumpers of a climb before the wall [next] rises to from [floor],
  /// from the bottom, if any: in the two columns before the wall, between
  /// the two runs' heights.
  static List<Bumper>? _climbOf(
    LevelData level,
    FloorRun floor,
    FloorRun next,
  ) {
    if ((next.left - floor.right).abs() > _epsilon ||
        next.top > floor.top - _epsilon) {
      return null;
    }
    final near = next.left - bumperWallGap;
    final bumpers = [
      for (final bumper in level.bumpers)
        if (((bumper.center.x - near).abs() < _epsilon ||
                (bumper.center.x - near + bumperColumnGap).abs() < _epsilon) &&
            bumper.center.y < floor.top &&
            bumper.center.y > next.top)
          bumper,
    ]..sort((a, b) => b.center.y.compareTo(a.center.y));
    return bumpers.isEmpty ? null : bumpers;
  }

  /// A bumper climb alternates its columns from the far one to the near
  /// one, its lowest top within a jump, each step and the ledge within a
  /// hop, with room on the run before it (design D2 of
  /// add-dynamic-elements).
  void _checkClimb(
    List<Bumper> bumpers,
    FloorRun floor,
    FloorRun wall,
    double margin,
    List<String> violations,
  ) {
    final near = wall.left - bumperWallGap;
    var shaped =
        bumpers.length.isEven &&
        floor.left <= near - bumperColumnGap - tileSize + _epsilon;
    for (var i = 0; i < bumpers.length; i++) {
      final onNear = (bumpers[i].center.x - near).abs() < _epsilon;
      // Each leans towards the next; the last throws straight up.
      final lean = i == bumpers.length - 1 ? 0 : (i.isEven ? 1 : -1);
      if (onNear != i.isOdd ||
          bumpers[i].lean != lean ||
          bumpers[i].radius != climbBumperRadius) {
        shaped = false;
      }
    }
    if (!shaped) {
      violations.add('bumper climb at x=${wall.left} is malformed');
    }
    final hop = envelope.bumperHopRise * margin;
    var top = floor.top;
    var reach = envelope.jumpHeight * margin;
    for (final bumper in [...bumpers.map((b) => b.top)]) {
      if (top - bumper > reach + _epsilon) {
        violations.add('bumper at y=$bumper is out of reach in its climb');
      }
      top = bumper;
      reach = hop;
    }
    if (top - wall.top > hop + _epsilon) {
      violations.add('ledge at x=${wall.left} is out of reach of its climb');
    }
  }

  /// Fans over a pit cover it from edge to edge, with at most a tile
  /// without wind between columns of at least two tiles; they hold the ball
  /// clear above both banks and catch it below the run (design D1 of
  /// add-dynamic-elements).
  void _checkFanGap(
    List<Fan> columns,
    FloorRun floor,
    FloorRun next,
    List<String> violations,
  ) {
    var edge = floor.right;
    for (final fan in columns) {
      final narrow = columns.length > 1 && fan.right - fan.left < 2 * tileSize;
      if (fan.left - edge > tileSize + _epsilon || narrow) {
        violations.add('fans over x=${floor.right} leave too wide a lull');
      }
      edge = fan.right;
      final higher = floor.top < next.top ? floor.top : next.top;
      if (fan.hover > higher - envelope.fanClearance + _epsilon) {
        violations.add('fan at x=${fan.left} floats the ball too low');
      }
      if (fan.base < floor.top + envelope.fanCatchDepth - _epsilon) {
        violations.add('fan at x=${fan.left} stands too high to catch');
      }
    }
    if ((columns.first.left - floor.right).abs() > _epsilon ||
        (next.left - edge).abs() > _epsilon) {
      violations.add('fans over x=${floor.right} do not span the pit');
    }
  }

  /// Every fan stands in a pit between two runs or in a floor before a
  /// wall, with a column that rises above its base.
  void _checkFans(LevelData level, List<String> violations) {
    final floors = level.floors;
    for (final fan in level.fans) {
      var placed = false;
      for (var i = 0; i + 1 < floors.length; i++) {
        final floor = floors[i];
        final next = floors[i + 1];
        final inPit =
            fan.left >= floor.right - _epsilon &&
            fan.right <= next.left + _epsilon;
        final inFloor =
            _floorFan(level, floor) == fan && next.top < floor.top - _epsilon;
        if (inPit || inFloor) placed = true;
      }
      if (!placed || fan.top >= fan.base || fan.left >= fan.right) {
        violations.add('fan at x=${fan.left} is misplaced');
      }
    }
  }

  /// Every bumper is part of a climb before a wall, or sits low in the
  /// riser of a step up (design D2 of add-dynamic-elements).
  void _checkBumpers(LevelData level, List<String> violations) {
    final floors = level.floors;
    for (final bumper in level.bumpers) {
      var placed = false;
      for (var i = 0; i + 1 < floors.length; i++) {
        final floor = floors[i];
        final next = floors[i + 1];
        final riser =
            (next.left - floor.right).abs() < _epsilon &&
            next.top < floor.top - _epsilon &&
            (bumper.center.x - (next.left + bumperInset)).abs() < _epsilon &&
            (bumper.center.y - (floor.top - bumperRadius)).abs() < _epsilon;
        final climb = _climbOf(level, floor, next);
        if (riser || (climb != null && climb.contains(bumper))) placed = true;
      }
      if (!placed) {
        violations.add('bumper at ${bumper.center} is misplaced');
      }
    }
  }

  /// Every mace hangs over a run with room to wait in before its lane and a
  /// tile after it, out of every other lane, and leaves the lane clear long
  /// enough to cross it from rest at the room's back (design D3 of
  /// add-dynamic-elements).
  void _checkPendulums(
    LevelData level,
    double margin,
    List<String> violations,
  ) {
    Pendulum? previous;
    for (final pendulum in level.pendulums) {
      final lane = pendulum.left - ballRadius;
      final end = pendulum.right + ballRadius;
      final over = level.floors.any(
        (floor) =>
            (floor.top - pendulum.ground).abs() < _epsilon &&
            floor.left <= lane - pendulumRoom * tileSize + _epsilon &&
            floor.right >= end + tileSize - _epsilon,
      );
      final shaped =
          pendulum.length >= 2.5 - _epsilon &&
          pendulum.length <= 3.5 + _epsilon &&
          pendulum.clear >= 0.2 - _epsilon &&
          pendulum.clear <= 0.3 + _epsilon;
      if (!over || !shaped) {
        violations.add('pendulum at x=${pendulum.pivot.x} is misplaced');
      }
      if (previous != null &&
          (previous.ground - pendulum.ground).abs() < _epsilon &&
          lane - (previous.right + ballRadius) <
              pendulumRoom * tileSize - _epsilon) {
        violations.add('pendulum at x=${pendulum.pivot.x} leaves no room');
      }
      previous = pendulum;
      const room = pendulumRoom * tileSize;
      final crossing = envelope.pushTime(room, room + end - lane);
      if (crossing > margin * pendulum.clearTime * (1 + _epsilon)) {
        violations.add(
          'pendulum at x=${pendulum.pivot.x} leaves $crossing s to cross '
          'in ${pendulum.clearTime}',
        );
      }
    }
  }

  /// Every seesaw rests with its near end level with a run, just past it.
  void _checkSeesaws(LevelData level, List<String> violations) {
    for (final seesaw in level.seesaws) {
      final rests = level.floors.any(
        (floor) => _seesawAfter(level, floor) == seesaw,
      );
      final shaped =
          seesaw.rest > 0 &&
          seesaw.tip > seesaw.rest &&
          seesaw.tip < seesaw.halfLength;
      if (!rests || !shaped) {
        violations.add('seesaw at x=${seesaw.pivot.x} is misplaced');
      }
    }
  }

  /// The far bank after [seesaw] is within a jump from its tipped far end,
  /// and clear of the plank at rest.
  void _checkSeesawGap(
    Seesaw seesaw,
    FloorRun bank,
    double margin,
    List<String> violations,
  ) {
    final far = seesaw.farEnd;
    final gap = bank.left - far.x;
    final limit = envelope.maxSeesawGap(rise: far.y - bank.top, margin: margin);
    if (gap > limit * (1 + _epsilon) + _epsilon) {
      violations.add('gap of $gap after seesaw at x=${far.x} exceeds $limit');
    }
    if (bank.left < seesaw.right + _epsilon) {
      violations.add('seesaw at x=${seesaw.pivot.x} reaches over its bank');
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

  /// Curves join two floor runs, smoothly and no steeper than a ramp: hills
  /// rise above the ground and half-pipes dip below it, both ending at their
  /// starting height, and slopes climb or fall steadily to the next run
  /// (level-generation spec).
  void _checkCurves(LevelData level, List<String> violations) {
    for (final curve in level.curves) {
      final ground = curve.points.first.y;
      final joined = level.floors.any(
        (floor) =>
            (floor.right - curve.left).abs() < _epsilon &&
            (floor.top - ground).abs() < _epsilon,
      );
      if (!joined) {
        violations.add('curve at x=${curve.left} does not join its floors');
      }
      final flat = (curve.points.last.y - ground).abs() < _epsilon;
      var smooth = flat != (curve.kind == CurveKind.slope);
      for (var i = 1; i < curve.points.length; i++) {
        final a = curve.points[i - 1];
        final b = curve.points[i];
        final dx = b.x - a.x;
        if (dx <= 0 ||
            dx > CurvedRun.step + _epsilon ||
            (b.y - a.y).abs() > maxSlope * dx + _epsilon) {
          smooth = false;
        }
      }
      final rises = curve.points.every((point) => point.y <= ground + _epsilon);
      final dips = curve.points.every((point) => point.y >= ground - _epsilon);
      var monotonic = true;
      for (var i = 2; i < curve.points.length; i++) {
        final before = curve.points[i - 1].y - curve.points[i - 2].y;
        final after = curve.points[i].y - curve.points[i - 1].y;
        if (before * after < -_epsilon) monotonic = false;
      }
      final shaped = switch (curve.kind) {
        CurveKind.hill => rises,
        CurveKind.halfPipe => dips,
        CurveKind.slope => monotonic,
      };
      if (!smooth || !shaped) {
        violations.add('curve at x=${curve.left} is malformed');
      }
    }
  }

  /// A curve ends where the next floor run starts, at the same height.
  void _checkCurveJoins(
    CurvedRun curve,
    FloorRun before,
    FloorRun after,
    List<String> violations,
  ) {
    final end = curve.points.last;
    if ((after.left - end.x).abs() > _epsilon ||
        (after.top - end.y).abs() > _epsilon) {
      violations.add('curve at x=${curve.left} does not join its floors');
    }
  }

  /// Trampolines lie on a floor run, at least a meter wide, before a pit.
  void _checkTrampolines(LevelData level, List<String> violations) {
    for (final pad in level.trampolines) {
      final lies = level.floors.any(
        (floor) =>
            (floor.top - pad.top).abs() < _epsilon &&
            pad.left >= floor.left - _epsilon &&
            pad.right <= floor.right + _epsilon,
      );
      if (!lies || pad.width < 1) {
        violations.add('trampoline at x=${pad.left} does not lie on a run');
      }
    }
  }

  /// A loop stands on a run that reaches a tile past it, with its speed
  /// boost just before it and nothing else in its way (level-generation
  /// spec).
  void _checkLoops(LevelData level, List<String> violations) {
    for (final loop in level.loops) {
      final approach = loop.left - loopBoostLead;
      final stands = level.floors.any(
        (floor) =>
            (floor.top - loop.foot.y).abs() < _epsilon &&
            floor.left <= approach + _epsilon &&
            floor.right >= loop.right + tileSize - _epsilon,
      );
      if (!stands || loop.radius <= 0) {
        violations.add('loop at x=${loop.foot.x} does not stand on a run');
      }
      final boosted = level.boosts.any(
        (boost) =>
            boost.type == BoostType.speed &&
            (boost.position.x - approach).abs() < _epsilon,
      );
      if (!boosted) {
        violations.add('loop at x=${loop.foot.x} has no speed boost');
      }
      bool inside(double x) => x > approach + _epsilon && x <= loop.right;
      if (level.boosts.any((boost) => inside(boost.position.x)) ||
          level.checkpoints.any((point) => inside(point.position.x)) ||
          level.trampolines.any((pad) => inside(pad.right)) ||
          level.hazards.any(
            (strip) => strip.right > approach && strip.left <= loop.right,
          )) {
        violations.add('something blocks the loop at x=${loop.foot.x}');
      }
    }
  }

  /// Adrenaline zones lie over the course, apart from each other, and hold
  /// no checkpoint, since a respawn ends the rush (design D8 of
  /// flow-and-pacing).
  void _checkAdrenaline(LevelData level, List<String> violations) {
    final start = level.floors.first.left;
    final end = level.floors.last.right;
    var last = double.negativeInfinity;
    for (final zone in level.adrenaline) {
      if (zone.left >= zone.right ||
          zone.left < start - _epsilon ||
          zone.right > end + _epsilon ||
          zone.left < last) {
        violations.add('adrenaline zone at x=${zone.left} is malformed');
      }
      last = zone.right;
      if (level.checkpoints.any((point) => zone.covers(point.position.x))) {
        violations.add('adrenaline zone at x=${zone.left} holds a checkpoint');
      }
    }
  }

  /// A backward belt never runs so fast that pushing cannot beat it.
  void _checkSurfaces(LevelData level, List<String> violations) {
    final backward = level.floors.any(
      (floor) => floor.surface == FloorSurface.conveyorBackward,
    );
    if (backward && envelope.beltSpeed * 2 > envelope.topSpeed) {
      violations.add('backward belts run faster than the ball can push');
    }
  }

  /// Laser barriers hang above every jump of the route around them, with a
  /// sensible rhythm (design D9 of raise-difficulty-and-pace).
  void _checkLasers(LevelData level, List<String> violations) {
    final clearance = LaserClearance(
      envelope: envelope,
      floors: level.floors,
      ramps: level.ramps,
      platforms: level.platforms,
      boosts: level.boosts,
      curves: level.curves,
      trampolines: level.trampolines,
      loops: level.loops,
      adrenaline: level.adrenaline,
      fans: level.fans,
      pendulums: level.pendulums,
      seesaws: level.seesaws,
    );
    for (final laser in level.lasers) {
      final lowest = clearance.lowestEnd(laser.x);
      if (lowest == null || laser.bottom > lowest + _epsilon) {
        violations.add('laser at x=${laser.x} reaches the route');
      }
      final rhythm = laser.on >= 0.5 && laser.off >= 0.5;
      if (laser.top >= laser.bottom || !rhythm) {
        violations.add('laser at x=${laser.x} is malformed');
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

  /// The trampoline lying on [floor], if any.
  static Trampoline? _padOn(LevelData level, FloorRun floor) {
    for (final pad in level.trampolines) {
      if ((pad.top - floor.top).abs() < _epsilon &&
          pad.left >= floor.left - _epsilon &&
          pad.right <= floor.right + _epsilon) {
        return pad;
      }
    }
    return null;
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
