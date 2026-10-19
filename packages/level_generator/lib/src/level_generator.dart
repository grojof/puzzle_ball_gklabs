import 'dart:math' as math;

import 'package:level_generator/src/difficulty_curve.dart';
import 'package:level_generator/src/laser_clearance.dart';
import 'package:level_generator/src/level_data.dart';
import 'package:level_generator/src/movement_envelope.dart';
import 'package:level_generator/src/random.dart';

/// Builds levels from a seed and a level number.
///
/// Generation walks a cursor from left to right, appending sections whose
/// gaps and climbs stay within the [envelope] scaled by the level's margin
/// (design D4–D6). Only exact floating-point operations are used here, so a
/// seed gives the same level on every platform (design D2).
class LevelGenerator {
  /// A generator bounded by [envelope], paced by [curve].
  const new({required this.envelope, this.curve = const DifficultyCurve()});

  /// What the ball can do.
  final MovementEnvelope envelope;

  /// How difficulty grows with the level number.
  final DifficultyCurve curve;

  /// Level [level] (from 1) of [seed].
  LevelData generate({required String seed, required int level}) {
    final parameters = curve.parametersFor(level);
    final builder = _Builder(
      envelope,
      parameters,
      Mulberry32(levelSeed(seed, level)),
    )..start();
    while (builder.duration < parameters.targetDuration) {
      builder.phrase();
    }
    return (builder..finish()).build(seed, level);
  }
}

/// Ground height of the start platform, in world y.
const _startHeight = 4.0;

/// Average speed over a level, including hesitation, in m/s.
const _referenceSpeed = 5.0;

/// Extra time an obstacle takes, in seconds.
const _obstacleOverhead = 0.8;

/// How wide a rounded slope is per meter of height: its steepest slope is
/// 1.5 times its height over its width, so this keeps it as gentle as a
/// ramp of 35°.
const _slopeStretch = 2.2;

/// How long a laser barrier hangs, and its rhythm, in meters and seconds.
const _laserLength = 10.0;
const _laserOn = 1.4;
const _laserOff = 1.0;

/// How wide a bump is per meter of height: its steepest slope is 3.08 times
/// its height over its width, so this keeps it as gentle as a ramp.
const _bumpStretch = 4.4;

/// The least height a tower climbs, in meters.
const _towerHeight = 8.0;

/// How much more often climbs or descents towards the heading come.
const _headingBias = 2.5;

/// The most a tower climbs or a descent drops, in meters.
const _bigSection = 16.0;

/// About how long spikes and their landing take, in seconds.
const _spikesTime = 3.0;

/// About how long a ferry crossing takes, in seconds.
const _ferryTime = 10.0;

/// How often an obstacle is one of the level's featured kinds.
const _featuredShare = 0.75;

/// How often an obstacle simply heads for the course's target height,
/// whatever the level features.
const _journeyShare = 0.25;

/// How far above and below its start a course may wander, in meters
/// (design D4 of raise-difficulty-and-pace).
const _maxRise = 40.0;
const _maxFall = 25.0;

/// Sections that end higher than they start.
const Set<SectionKind> _climbs = {
  SectionKind.rampUp,
  SectionKind.stepUp,
  SectionKind.jumpBoost,
  SectionKind.staircase,
  SectionKind.orbClimb,
  SectionKind.tower,
};

/// Sections that end lower than they start.
const Set<SectionKind> _descents = {
  SectionKind.rampDown,
  SectionKind.drop,
  SectionKind.cascade,
  SectionKind.descent,
};

class _Builder {
  new(this.envelope, this.parameters, this.random);

  final MovementEnvelope envelope;
  final LevelParameters parameters;
  final Mulberry32 random;

  final floors = <FloorRun>[];
  final ramps = <Ramp>[];
  final boosts = <Boost>[];
  final checkpoints = <Checkpoint>[];
  final hazards = <SpikeStrip>[];
  final platforms = <MovingPlatform>[];
  final curves = <CurvedRun>[];
  final trampolines = <Trampoline>[];
  final loops = <Loop>[];
  final sections = <SectionKind>[];

  /// Where laser barriers should hang, and for a tower's top, the height
  /// the route must fall below after it for the barrier to be worth it.
  final _laserSites = <({double x, double? above})>[];

  /// The cursor: where the current floor run ends.
  double x = 0;

  /// Ground height of the current floor run, in world y (downwards).
  double y = _startHeight;

  /// Where the current floor run starts.
  double runStart = 0;

  /// Extra height below the current run, so a ledge reaches the ground
  /// below it.
  double runFill = 0;

  /// Whether the current run crumbles.
  bool runCrumbling = false;

  /// What the current run's top is made of.
  FloorSurface runSurface = FloorSurface.plain;

  /// The height the course is heading for, in world y; null until chosen.
  /// Climbs or descents towards it are favored, so the course travels up
  /// and down (design D4 of raise-difficulty-and-pace).
  double? _heading;

  /// Estimated speed of a player who keeps pushing right.
  double speed = 0;

  /// Whether the last landing capped [speed], so the player comes down at
  /// the far end of the landing with only its last tile left to speed up.
  bool _landedLate = false;

  /// Caps [speed] for a flight that must average at most [cap] to come down
  /// on its landing. Braking in the air against the ball's damping leaves
  /// it well below that average when it lands: about half, measured with
  /// the bot.
  void _capSpeed(double cap) {
    if (speed <= cap) return;
    speed = cap / 2;
    _landedLate = true;
  }

  double duration = 0;
  double sinceRespawn = 0;
  late Vec2 ballStart;
  late Vec2 goal;

  /// The kinds this level features (design D10).
  late final List<SectionKind> featured;

  /// The kinds this level introduces that have not appeared yet.
  final List<SectionKind> _toIntroduce = [];

  double get intensity => parameters.intensity;
  double get margin => parameters.margin;

  /// A share of the reach to use, drawn from the level's precision interval
  /// (design D3 of add-physical-mechanics).
  double _share() {
    final (low, high) = parameters.precision;
    return random.range(low, high);
  }

  double get runLength => x - runStart;

  void start() {
    final pool = Map.of(parameters.weights);
    // The sections this level introduces are always among its featured ones.
    final introduced = [
      for (final kind in SectionKind.values)
        if (parameters.introduces.contains(kind)) kind,
    ];
    pool.removeWhere((kind, _) => introduced.contains(kind));
    featured = [
      ...introduced,
      for (var i = random.intIn(2, 3) - introduced.length; i > 0; i--)
        _take(pool),
    ];
    _toIntroduce.addAll(introduced);
    _flat(3);
    ballStart = Vec2(tileSize / 2, y - 1);
  }

  void finish() {
    // Spikes never lie on the goal's run.
    if (hazards.isNotEmpty && hazards.last.left >= runStart) {
      _section(SectionKind.gap);
    }
    _flat(3);
    goal = Vec2(x - tileSize / 2, y - 1.75);
    _closeRun();
  }

  LevelData build(String seed, int level) => LevelData(
    seed: seed,
    level: level,
    ballStart: ballStart,
    goal: goal,
    floors: List.unmodifiable(floors),
    ramps: List.unmodifiable(ramps),
    boosts: List.unmodifiable(boosts),
    checkpoints: List.unmodifiable(checkpoints),
    hazards: List.unmodifiable(hazards),
    platforms: List.unmodifiable(platforms),
    lasers: List.unmodifiable(_lasers()),
    curves: List.unmodifiable(curves),
    trampolines: List.unmodifiable(trampolines),
    loops: List.unmodifiable(loops),
    sections: List.unmodifiable(sections),
    estimatedDuration: duration,
    featured: List.unmodifiable(featured),
  );

  /// The laser barriers at the recorded sites, each hanging just above
  /// every jump of the route around it, alternating (design D9 of
  /// raise-difficulty-and-pace).
  List<LaserBarrier> _lasers() {
    final clearance = LaserClearance(
      envelope: envelope,
      floors: floors,
      ramps: ramps,
      platforms: platforms,
      boosts: boosts,
      curves: curves,
      trampolines: trampolines,
      loops: loops,
    );
    final lasers = <LaserBarrier>[];
    for (final site in _laserSites) {
      final above = site.above;
      if (above != null && !_fallsAfter(site.x, above)) continue;
      final bottom = clearance.lowestEnd(site.x);
      if (bottom == null) continue;
      lasers.add(
        LaserBarrier(
          x: site.x,
          top: bottom - _laserLength,
          bottom: bottom,
          on: _laserOn,
          off: _laserOff,
          phase: lasers.length.isOdd ? (_laserOn + _laserOff) / 2 : 0,
        ),
      );
    }
    return lasers;
  }

  /// Whether the ground within 20 m after [x] falls more than 6 m below
  /// [height]: worth guarding against a leap off the top.
  bool _fallsAfter(double x, double height) => floors.any(
    (floor) => floor.right > x && floor.left < x + 20 && floor.top > height + 6,
  );

  /// Draws a key of [pool] by weight and removes it.
  SectionKind _take(Map<SectionKind, double> pool) {
    final kind = random.weighted(pool);
    pool.remove(kind);
    return kind;
  }

  /// Appends a rest stretch, or an action phrase of back-to-back obstacles
  /// (design D10).
  void phrase() {
    if (!random.chance(parameters.obstacleShare)) {
      _section(SectionKind.flat);
      return;
    }
    final count = random.intIn(2, 2 + (3 * intensity).floor());
    for (var i = 0; i < count && duration < parameters.targetDuration; i++) {
      _section(_chooseKind());
    }
  }

  /// Appends a section of [kind]: a rest stretch of flat ground, or an
  /// obstacle and its landing.
  void _section(SectionKind kind) {
    switch (kind) {
      case SectionKind.flat:
        _flat(random.intIn(3, parameters.isBreather ? 7 : 5));
      case SectionKind.rampUp:
        _rampUp(_rampHeight());
      case SectionKind.rampDown:
        _rampDown(_rampHeight());
      case SectionKind.gap:
        _gap(_gapRise());
      case SectionKind.drop:
        _drop(random.range(1.5, 1.5 + 3 * intensity));
      case SectionKind.stepUp:
        _stepUp(_stepHeight());
      case SectionKind.speedBoost:
        _speedBoost();
      case SectionKind.chainedGaps:
        _chainedGaps();
      case SectionKind.jumpBoost:
        _jumpBoost();
      case SectionKind.gravityBoost:
        _gravityBoost();
      case SectionKind.staircase:
        _staircase();
      case SectionKind.cascade:
        _cascade();
      case SectionKind.valley:
        _valley();
      case SectionKind.spikes:
        _spikes();
      case SectionKind.ferry:
        _ferry();
      case SectionKind.crumblingHops:
        _crumblingHops();
      case SectionKind.orbGap:
        _orbGap();
      case SectionKind.orbClimb:
        _orbClimb();
      case SectionKind.tower:
        _tower();
      case SectionKind.descent:
        _descent();
      case SectionKind.hill:
        _hill();
      case SectionKind.halfPipe:
        _halfPipe();
      case SectionKind.trampolineHops:
        _trampolineHops();
      case SectionKind.conveyor:
        _surfaceGap(
          random.chance(0.5)
              ? FloorSurface.conveyorForward
              : FloorSurface.conveyorBackward,
        );
      case SectionKind.ice:
        _surfaceGap(FloorSurface.ice);
      case SectionKind.mud:
        _mud();
      case SectionKind.loop:
        _loop();
    }
    sections.add(kind);
    if (kind == SectionKind.flat) {
      _maybeCheckpoint(threshold: 1);
    } else {
      _flat(_landingTiles);
      _maybeCheckpoint(threshold: 0.75);
    }
  }

  /// The length of the landing run after an obstacle, in tiles.
  int get _landingTiles => intensity < 0.6 ? 3 : 2;

  /// Caps the estimated speed after a flight of [time] seconds that covers
  /// [covered] meters over the obstacle and must come down on a landing of
  /// [landingTiles] tiles: a faster player brakes in the air to land on it,
  /// and so reaches what follows slower.
  void _land(double time, {double covered = 0, int? landingTiles}) {
    final landing = ((landingTiles ?? _landingTiles) - 1) * tileSize;
    _capSpeed((covered + landing) / time);
  }

  /// An obstacle kind: usually one of the featured kinds, otherwise any
  /// other available one.
  SectionKind _chooseKind() {
    final weights = Map.of(parameters.weights);
    // Keep the course within a vertical band, so it reads as a journey
    // rather than a tower or a pit.
    if (y < _startHeight - _maxRise) {
      weights.removeWhere((kind, _) => _climbs.contains(kind));
    }
    if (y > _startHeight + _maxFall) {
      weights.removeWhere((kind, _) => _descents.contains(kind));
    }
    // Head for a height inside the band, and pick another once there.
    final heading = _heading ??= _newHeading();
    if ((heading - y).abs() < 3) _heading = _newHeading();
    final towards = _heading! < y ? _climbs : _descents;
    weights.updateAll(
      (kind, weight) => towards.contains(kind) ? weight * _headingBias : weight,
    );
    // Towers and descents only where they fit inside the band.
    if (y - _bigSection < _startHeight - _maxRise) {
      weights.remove(SectionKind.tower);
    }
    if (y + _bigSection > _startHeight + _maxFall) {
      weights.remove(SectionKind.descent);
    }
    // Spikes never lie on the start's or the goal's run, and a ferry takes a
    // while: neither when the level is about to end.
    final left = parameters.targetDuration - duration;
    if (runStart == 0 || left < _spikesTime) {
      weights.remove(SectionKind.spikes);
    }
    if (left < _ferryTime) weights.remove(SectionKind.ferry);
    // An element first appears in its introduction level, at the first
    // obstacle that allows it.
    for (final kind in _toIntroduce) {
      if (weights.containsKey(kind)) {
        _toIntroduce.remove(kind);
        return kind;
      }
    }
    final journey = Map.of(weights)
      ..removeWhere((kind, _) => !towards.contains(kind));
    if (journey.isNotEmpty && random.chance(_journeyShare)) {
      return random.weighted(journey);
    }
    final mine = Map.of(weights)
      ..removeWhere((kind, _) => !featured.contains(kind));
    final others = weights..removeWhere((kind, _) => featured.contains(kind));
    final useFeatured = mine.isNotEmpty && random.chance(_featuredShare);
    return random.weighted(useFeatured ? mine : others);
  }

  void _time(double distance, {bool obstacle = false}) {
    final time =
        distance / _referenceSpeed + (obstacle ? _obstacleOverhead : 0);
    duration += time;
    sinceRespawn += time;
  }

  void _flat(int tiles) {
    final distance = tiles * tileSize;
    x += distance;
    speed = envelope.speedOn(
      runSurface,
      _landedLate ? tileSize : distance,
      startSpeed: speed,
    );
    _landedLate = false;
    _time(distance);
  }

  void _closeRun() {
    floors.add(
      FloorRun(
        position: Vec2(runStart, y),
        size: Vec2(runLength, tileSize + runFill),
        crumbling: runCrumbling,
        surface: runSurface,
      ),
    );
  }

  void _openRun({double fill = 0, FloorSurface surface = FloorSurface.plain}) {
    runStart = x;
    runFill = fill;
    runCrumbling = false;
    runSurface = surface;
  }

  double _rampHeight() => random.range(0.75, 0.75 + 2.25 * intensity);

  /// A rounded slope up [height] meters: pushing climbs it, and leaves at
  /// [MovementEnvelope.curveExitSpeed] or more (design D2 of
  /// add-curved-terrain-and-physics).
  void _rampUp(double height) {
    _slope(-height, math.max(height * _slopeStretch, tileSize));
    speed = envelope.curveExitSpeed;
  }

  /// A rounded slope down [height] meters. A player faster than the slope
  /// flies off its top as off a ledge, so the landing of [landingTiles]
  /// after it caps the speed as a drop does.
  void _rampDown(double height, {int? landingTiles}) {
    final width = math.max(
      height * _slopeStretch * random.range(1, 1.4),
      tileSize,
    );
    _slope(height, width);
    _land(
      envelope.fallTime(height),
      covered: width,
      landingTiles: landingTiles,
    );
  }

  /// A rounded slope from the cursor, [drop] meters lower (negative to
  /// rise), [width] long.
  void _slope(double drop, double width) {
    _closeRun();
    final curve = CurvedRun.slope(left: x, from: y, to: y + drop, width: width);
    curves.add(curve);
    _time(width, obstacle: true);
    x = curve.right;
    y += drop;
    _openRun();
  }

  double _gapRise() {
    if (random.chance(0.5)) return 0;
    return random.range(
      -2.5,
      0.6 * envelope.maxClimb(margin, surface: runSurface),
    );
  }

  /// A gap landing [rise] higher, using a share of the reach at the current
  /// speed from the precision interval, and never more than its high end.
  void _gap(double rise, {int? landingTiles}) {
    const minGap = tileSize * 0.8;
    final reach = _reach(rise);
    final width = math.max(minGap, reach * _share());
    _jumpGap(math.min(width, reach * margin), rise, landingTiles: landingTiles);
  }

  /// The full reach of a jump from the current run at the current speed,
  /// landing [rise] higher.
  double _reach(double rise) =>
      envelope.maxGap(speed: speed, rise: rise, margin: 1, surface: runSurface);

  /// A gap of [width] landing [rise] higher, flown in [time] seconds (a
  /// plain jump's air time by default) onto a landing of [landingTiles].
  void _jumpGap(double width, double rise, {double? time, int? landingTiles}) {
    _closeRun();
    x += width;
    y -= rise;
    _openRun();
    _time(width, obstacle: true);
    _land(
      time ?? envelope.airTime(rise) ?? envelope.flightTime,
      covered: width,
      landingTiles: landingTiles,
    );
  }

  /// A ledge to fall [height] meters from; [land] caps the speed for the
  /// landing of [landingTiles] that follows.
  void _drop(double height, {bool land = true, int? landingTiles}) {
    _closeRun();
    y += height;
    _openRun();
    _time(tileSize / 2, obstacle: true);
    if (land) {
      _land(envelope.fallTime(height), landingTiles: landingTiles);
    }
  }

  double _stepHeight() =>
      math.max(0.6, envelope.maxClimb(1, surface: runSurface) * _share());

  void _stepUp(double height) {
    _closeRun();
    y -= height;
    _openRun(fill: height);
    speed *= 0.5;
    _time(tileSize / 2, obstacle: true);
  }

  void _chainedGaps() {
    final count = random.intIn(2, 3);
    for (var i = 0; i < count; i++) {
      final last = i == count - 1;
      final between = last ? _landingTiles : random.intIn(1, 2);
      _gap(_gapRise(), landingTiles: between);
      if (!last) _flat(between);
    }
  }

  void _staircase() {
    final steps = random.intIn(2, 3);
    for (var i = 0; i < steps; i++) {
      if (i > 0) _flat(random.intIn(1, 2));
      _stepUp(_stepHeight());
    }
  }

  /// Drops with treads between them. Overshooting a tread only lands on a
  /// lower one, so a player may fly from any ledge to the final landing, as
  /// long as the flight clears the treads in between; the fastest such
  /// flight caps the speed.
  void _cascade() {
    final drops = random.intIn(2, 3);
    final ledges = <double>[];
    final heights = <double>[];
    for (var i = 0; i < drops; i++) {
      if (i > 0) _flat(random.intIn(1, 2));
      ledges.add(x);
      final height = random.range(1, 1 + 1.5 * intensity);
      heights.add(height);
      _drop(height, land: false);
    }
    final landing = x + (_landingTiles - 1) * tileSize;
    var cap = 0.0;
    for (var from = 0; from < drops; from++) {
      final fallen = heights.sublist(from).reduce((a, b) => a + b);
      final flight = (landing - ledges[from]) / envelope.fallTime(fallen);
      var clears = true;
      var below = 0.0;
      for (var next = from + 1; next < drops; next++) {
        below += heights[next - 1];
        final reach = ledges[next] - ledges[from];
        if (reach / flight > envelope.fallTime(below)) clears = false;
      }
      if (clears) cap = math.max(cap, flight);
    }
    _capSpeed(cap);
  }

  /// A strip of spikes on the run, a tile after the section starts, as wide
  /// as a share of the jump reach at the speed available.
  void _spikes() {
    const double minWidth = 1;
    _flat(1);
    final reach = _reach(0);
    final width = math.min(
      math.max(minWidth, reach * _share()),
      reach * margin,
    );
    hazards.add(SpikeStrip(position: Vec2(x, y), width: width));
    x += width;
    _time(width, obstacle: true);
    _land(envelope.flightTime, covered: width);
  }

  /// Room to stop and wait, then a gap too wide to jump, 1.2 to 2.5 times
  /// the reach, with a platform shuttling across it from just beyond the
  /// near edge to just short of the far one (design D4).
  void _ferry() {
    const platform = Vec2(2 * tileSize, 0.5);
    const crack = 0.15;
    const ferrySpeed = 2.2;
    const pause = 0.8;
    final width = math.max(
      _reach(0) * random.range(1.2, 2.5),
      platform.x + 2 * crack + tileSize,
    );
    _flat(2);
    _closeRun();
    platforms.add(
      MovingPlatform(
        start: Vec2(x + crack, y),
        end: Vec2(x + width - crack - platform.x, y),
        size: platform,
        speed: ferrySpeed,
        pause: pause,
      ),
    );
    x += width;
    _openRun();
    // On average, half a round trip to wait for the platform, then the ride.
    final travel = width - 2 * crack - platform.x;
    final wait = 2 * (travel / ferrySpeed) + pause;
    duration += wait;
    sinceRespawn += wait;
    // The player steps off the platform at its speed.
    speed = math.min(speed, ferrySpeed);
  }

  /// Island hops whose islands crumble: a player who keeps moving crosses
  /// them before they fall.
  void _crumblingHops() {
    final count = random.intIn(2, 3);
    for (var i = 0; i < count; i++) {
      final last = i == count - 1;
      final between = last ? _landingTiles : random.intIn(1, 2);
      _gap(_gapRise(), landingTiles: between);
      if (!last) {
        runCrumbling = true;
        _flat(between);
      }
    }
  }

  /// An orb on the approach, then a gap beyond one jump and within the
  /// double jump's reach.
  void _orbGap() {
    _boostApproach(BoostType.doubleJump, tiles: 3);
    final width = _boosted(
      envelope.maxDoubleJumpGap(speed: speed, margin: 1),
      _reach(0),
    );
    _jumpGap(width, 0, time: envelope.doubleJumpDistance / envelope.topSpeed);
  }

  /// An orb on the approach, then a climb beyond one jump and within the
  /// double jump's reach.
  void _orbClimb() {
    _boostApproach(BoostType.doubleJump, tiles: 2, inset: tileSize * 0.4);
    _stepUp(_boosted(envelope.maxDoubleJumpClimb(1), envelope.maxClimb(1)));
  }

  /// A long climb: four to six tall steps with one-tile treads, some with a
  /// rising gap instead of the tread, until at least [_towerHeight] meters
  /// are climbed (design D5 of raise-difficulty-and-pace).
  void _tower() {
    final start = x;
    var steps = 0;
    var climbed = 0.0;
    while (steps < 4 || (climbed < _towerHeight && steps < 6)) {
      final height = _stepHeight();
      if (steps > 0 && random.chance(0.2 + 0.3 * intensity)) {
        // A gap that rises onto the next tread, lower than a step, taken
        // from a tread of its own.
        final rise = height * 0.6;
        if (runLength < tileSize) _flat(1);
        _gap(rise, landingTiles: 1);
        _flat(1);
        climbed += rise;
      } else {
        if (steps > 0) _flat(1);
        _stepUp(height);
        climbed += height;
      }
      steps++;
    }
    // Guard a leap off the top, where the route turns back down.
    if (x > start) _laserSites.add((x: x + 6, above: y));
  }

  /// A long way down: three to five drops, ramps down and falling gaps, with
  /// short treads between them, descending 8–16 m (design D6 of
  /// raise-difficulty-and-pace).
  void _descent() {
    final start = x;
    final parts = random.intIn(3, 5);
    final part = (8 + 8 * _share()) / parts;
    for (var i = 0; i < parts; i++) {
      final last = i == parts - 1;
      final tread = last ? _landingTiles : random.intIn(1, 2);
      final height = part * random.range(0.85, 1.15);
      switch (random.intIn(0, 2)) {
        case 0:
          _drop(height, landingTiles: tread);
        case 1:
          _rampDown(height, landingTiles: tread);
        default:
          _gap(-math.min(height, 3.5), landingTiles: tread);
      }
      if (!last) _flat(tread);
    }
    // Barriers over the lower half guard a leap from the top.
    final count = random.intIn(1, 2);
    for (var i = 0; i < count; i++) {
      final along = count == 1 ? 0.7 : 0.6 + 0.25 * i;
      _laserSites.add((x: start + (x - start) * along, above: null));
    }
  }

  /// A height to head for, inside the band, at least 10 m from here.
  double _newHeading() {
    const low = _startHeight - _maxRise + 5;
    const high = _startHeight + _maxFall - 5;
    final target = random.range(low, high);
    if ((target - y).abs() >= 10) return target;
    return target < y ? math.max(low, y - 10) : math.min(high, y + 10);
  }

  void _valley() {
    final height = _rampHeight();
    _rampDown(height, landingTiles: 2);
    _flat(2);
    _gap(0, landingTiles: 2);
    _flat(2);
    _rampUp(height);
  }

  /// A boost on the approach, [inset] meters before the end of the run;
  /// returns the speed the player picks it up at.
  double _boostApproach(
    BoostType type, {
    required int tiles,
    double inset = tileSize / 2,
  }) {
    final run = _landedLate ? tileSize : tiles * tileSize;
    final pickUp = envelope.speedAfter(
      math.max(0, run - inset),
      startSpeed: speed,
    );
    _flat(tiles);
    boosts.add(Boost(position: Vec2(x - inset, y - 0.6), type: type));
    return pickUp;
  }

  /// A share of a [boostedReach] from the precision interval, beyond the
  /// [unboostedReach] by at least 5 % so the boost is needed, and never
  /// beyond the interval's high end.
  double _boosted(double boostedReach, double unboostedReach) => math.min(
    math.max(boostedReach * _share(), unboostedReach * 1.05),
    boostedReach * margin,
  );

  void _speedBoost() {
    final pickUp = _boostApproach(BoostType.speed, tiles: 3);
    final width = _boosted(
      envelope.maxSpeedBoostGap(speed: pickUp, margin: 1),
      _reach(0),
    );
    speed = envelope.topSpeed;
    _jumpGap(width, 0);
  }

  void _jumpBoost() {
    _boostApproach(BoostType.jump, tiles: 2, inset: tileSize * 0.4);
    _stepUp(_boosted(envelope.maxBoostedClimb(1), envelope.maxClimb(1)));
  }

  void _gravityBoost() {
    _boostApproach(BoostType.gravity, tiles: 3);
    final width = _boosted(
      envelope.maxGravityBoostGap(speed: speed, margin: 1),
      _reach(0),
    );
    _jumpGap(
      width,
      0,
      time: envelope.gravityBoostJumpDistance / envelope.topSpeed,
    );
  }

  /// A curve of [bumps] from the cursor, on level ground: pushing climbs
  /// any of them, and leaves at [MovementEnvelope.curveExitSpeed] or more
  /// (design D2 of add-curved-terrain-and-physics).
  void _curve(CurveKind kind, List<(double, double)> bumps) {
    _closeRun();
    final curve = CurvedRun.bumps(kind: kind, left: x, ground: y, bumps: bumps);
    curves.add(curve);
    _time(curve.right - x, obstacle: true);
    x = curve.right;
    _openRun();
    speed = envelope.curveExitSpeed;
    _landedLate = false;
  }

  /// One to three bumps in a row, each as gentle as a ramp. A fast ball
  /// takes off from a crest and comes down on the next slope or the
  /// landing.
  void _hill() {
    final count = random.intIn(1, 3);
    _curve(CurveKind.hill, [
      for (var i = 0; i < count; i++) _bump(_rampHeight()),
    ]);
  }

  /// A smooth dip 1.5–3 m deep, to roll through and climb out of.
  void _halfPipe() {
    final (width, depth) = _bump(random.range(1.5, 1.5 + 1.5 * intensity));
    _curve(CurveKind.halfPipe, [(width, -depth)]);
  }

  /// A bump of [height] and the width that keeps it gentle.
  (double, double) _bump(double height) =>
      (math.max(tileSize, height * _bumpStretch), height);

  /// One to three trampoline islands across a pit: a jump onto the first, then
  /// bounces beyond a jump's reach onto the next island or the landing.
  void _trampolineHops() {
    const island = 2 * tileSize;
    final islands = random.intIn(1, 3);
    _gap(random.range(-2, 0), landingTiles: 2);
    for (var i = 0; i < islands; i++) {
      // The island is the pad: the ball bounces where it lands.
      trampolines.add(Trampoline(position: Vec2(x, y), width: island));
      x += island;
      _time(island);
      final last = i == islands - 1;
      final rise = random.range(-1.5, 1.5);
      // The ball bounces where it lands on the island: count from its middle.
      final width = _boosted(
        envelope.maxTrampolineGap(speed: speed, rise: rise, margin: 1) -
            island / 2,
        _reach(rise),
      );
      _jumpGap(
        width,
        rise,
        time: envelope.trampolineAirTime(rise),
        landingTiles: last ? null : 2,
      );
    }
  }

  /// A run of [surface] before a gap sized from the speed and jump it allows
  /// (design D4 of add-curved-terrain-and-physics).
  void _surfaceGap(FloorSurface surface) {
    _surfaceRun(surface, tiles: random.intIn(3, 5));
    _gap(_gapRise());
  }

  /// A run of mud before a gap or a climb within its weaker jump.
  void _mud() {
    _surfaceRun(FloorSurface.mud, tiles: random.intIn(2, 3));
    if (random.chance(0.5)) {
      _stepUp(_stepHeight());
    } else {
      _gap(_gapRise());
    }
  }

  /// Starts a run of [surface] [tiles] long at the cursor, at the same
  /// height.
  void _surfaceRun(FloorSurface surface, {required int tiles}) {
    _closeRun();
    _openRun(surface: surface);
    _flat(tiles);
  }

  /// A run-up, a speed boost just before a loop, and the loop, all on one
  /// run: the boost's speed carries the ball around (design D5 of
  /// add-curved-terrain-and-physics).
  void _loop() {
    _flat(2);
    boosts.add(Boost(position: Vec2(x, y - 0.6), type: BoostType.speed));
    final foot = x + loopBoostLead + loopRadius;
    loops.add(Loop(foot: Vec2(foot, y), radius: loopRadius));
    final end = foot + loopRadius + tileSize;
    _time(end - x, obstacle: true);
    x = end;
    speed = envelope.curveExitSpeed;
    _landedLate = false;
    // The boost belongs to the loop's run alone.
    _closeRun();
    _openRun();
  }

  /// Places a checkpoint at the start of the current run once the time since
  /// the last respawn point passes [threshold] times the stage's spacing.
  void _maybeCheckpoint({required double threshold}) {
    if (sinceRespawn < parameters.checkpointSpacing * threshold) return;
    if (runLength < 2 * tileSize) return;
    checkpoints.add(Checkpoint(Vec2(runStart + tileSize / 2, y)));
    sinceRespawn = 0;
    // A player respawning here starts from rest on this run.
    speed = math.min(speed, envelope.speedAfter(runLength - tileSize / 2));
    _landedLate = false;
  }
}
