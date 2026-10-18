import 'dart:math' as math;

import 'package:level_generator/src/difficulty_curve.dart';
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

/// tan(35°): ramps are at most this steep.
const _maxRampSlope = 0.7002075382097097;

/// How often an obstacle is one of the level's featured kinds.
const _featuredShare = 0.65;

/// Sections that end higher than they start.
const Set<SectionKind> _climbs = {
  SectionKind.rampUp,
  SectionKind.stepUp,
  SectionKind.jumpBoost,
  SectionKind.staircase,
};

/// Sections that end lower than they start.
const Set<SectionKind> _descents = {
  SectionKind.rampDown,
  SectionKind.drop,
  SectionKind.cascade,
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
  final sections = <SectionKind>[];

  /// The cursor: where the current floor run ends.
  double x = 0;

  /// Ground height of the current floor run, in world y (downwards).
  double y = _startHeight;

  /// Where the current floor run starts.
  double runStart = 0;

  /// Extra height below the current run, so a ledge reaches the ground
  /// below it.
  double runFill = 0;

  /// Estimated speed of a player who keeps pushing right.
  double speed = 0;

  double duration = 0;
  double sinceRespawn = 0;
  late Vec2 ballStart;
  late Vec2 goal;

  /// The kinds this level features (design D10).
  late final List<SectionKind> featured;

  double get intensity => parameters.intensity;
  double get margin => parameters.margin;
  double get runLength => x - runStart;

  void start() {
    final pool = Map.of(parameters.weights);
    featured = [for (var i = random.intIn(2, 3); i > 0; i--) _take(pool)];
    _flat(3);
    ballStart = Vec2(tileSize / 2, y - 1);
  }

  void finish() {
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
    sections: List.unmodifiable(sections),
    estimatedDuration: duration,
    featured: List.unmodifiable(featured),
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
  int get _landingTiles => margin < 0.6 ? 3 : 2;

  /// Caps the estimated speed after a flight of [time] seconds that covers
  /// [covered] meters over the obstacle and must come down on a landing of
  /// [landingTiles] tiles: a faster player brakes in the air to land on it,
  /// and so reaches what follows slower.
  void _land(double time, {double covered = 0, int? landingTiles}) {
    final landing = ((landingTiles ?? _landingTiles) - 1) * tileSize;
    speed = math.min(speed, (covered + landing) / time);
  }

  /// An obstacle kind: usually one of the featured kinds, otherwise any
  /// other available one.
  SectionKind _chooseKind() {
    final weights = Map.of(parameters.weights);
    // Keep the course within a vertical band, so it reads as a journey
    // rather than a tower or a pit.
    if (y < _startHeight - 15) {
      weights.removeWhere((kind, _) => _climbs.contains(kind));
    }
    if (y > _startHeight + 6) {
      weights.removeWhere((kind, _) => _descents.contains(kind));
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
    speed = envelope.speedAfter(distance, startSpeed: speed);
    _time(distance);
  }

  void _closeRun() {
    floors.add(
      FloorRun(
        position: Vec2(runStart, y),
        size: Vec2(runLength, tileSize + runFill),
      ),
    );
  }

  void _openRun({double fill = 0}) {
    runStart = x;
    runFill = fill;
  }

  double _rampHeight() => random.range(0.75, 0.75 + 2.25 * intensity);

  void _rampUp(double height) {
    final width = math.max(height / _maxRampSlope, tileSize);
    _closeRun();
    ramps.add(
      Ramp(
        position: Vec2(x, y - height),
        size: Vec2(width, height),
        ascending: true,
      ),
    );
    x += width;
    y -= height;
    _openRun();
    speed *= 0.7;
    _time(width, obstacle: true);
  }

  void _rampDown(double height) {
    final width = math.max(
      height / _maxRampSlope * random.range(1, 1.4),
      tileSize,
    );
    _closeRun();
    ramps.add(
      Ramp(position: Vec2(x, y), size: Vec2(width, height), ascending: false),
    );
    x += width;
    y += height;
    _openRun();
    _time(width, obstacle: true);
  }

  double _gapRise() {
    if (random.chance(0.5)) return 0;
    return random.range(-2.5, 0.6 * envelope.maxClimb(margin));
  }

  /// A gap of a width the current speed can clear, landing [rise] higher.
  ///
  /// Never wider than the reach at the current speed; the landings after
  /// every obstacle leave enough run-up for the minimum gap.
  void _gap(double rise, {int? landingTiles}) {
    const minGap = tileSize * 0.8;
    final allowed = _allowedGap(rise);
    final low = 0.25 + 0.2 * intensity;
    final high = 0.45 + 0.55 * intensity;
    final width = math.max(minGap, allowed * random.range(low, high));
    _jumpGap(math.min(width, allowed), rise, landingTiles: landingTiles);
  }

  double _allowedGap(double rise) =>
      envelope.maxGap(speed: speed, rise: rise, margin: margin);

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
  /// landing that follows.
  void _drop(double height, {bool land = true}) {
    _closeRun();
    y += height;
    _openRun();
    _time(tileSize / 2, obstacle: true);
    if (land) _land(envelope.fallTime(height));
  }

  double _stepHeight() => math.max(
    0.6,
    envelope.maxClimb(margin) * random.range(0.4, 0.4 + 0.6 * intensity),
  );

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
  /// lower one, so only the final landing caps the speed: as if the whole
  /// cascade were flown over in one fall.
  void _cascade() {
    final drops = random.intIn(2, 3);
    final start = x;
    var fallen = 0.0;
    for (var i = 0; i < drops; i++) {
      if (i > 0) _flat(random.intIn(1, 2));
      final height = random.range(1, 1 + 1.5 * intensity);
      _drop(height, land: false);
      fallen += height;
    }
    _land(envelope.fallTime(fallen), covered: x - start);
  }

  void _valley() {
    final height = _rampHeight();
    _rampDown(height);
    _flat(2);
    _gap(0, landingTiles: 2);
    _flat(2);
    _rampUp(height);
  }

  /// A boost on the approach, [inset] meters before the end of the run.
  void _boostApproach(BoostType type, {required int tiles, double? inset}) {
    _flat(tiles);
    boosts.add(
      Boost(position: Vec2(x - (inset ?? tileSize / 2), y - 0.6), type: type),
    );
  }

  /// A width between just beyond the unboosted reach and [boostedMax].
  double _boostedWidth(double boostedMax) {
    final unboosted = _allowedGap(0);
    final low = math.min(unboosted * 1.15, boostedMax * 0.6);
    final high = math.max(low, boostedMax * random.range(0.6, 0.85));
    return random.range(low, high);
  }

  void _speedBoost() {
    _boostApproach(BoostType.speed, tiles: 3);
    final width = _boostedWidth(envelope.maxSpeedBoostGap(margin));
    speed = envelope.topSpeed;
    _jumpGap(width, 0);
  }

  void _jumpBoost() {
    _boostApproach(BoostType.jump, tiles: 2, inset: tileSize * 0.4);
    final low = envelope.maxClimb(margin) * 1.05;
    final high = envelope.maxBoostedClimb(margin);
    _stepUp(random.range(low, math.max(low, high * random.range(0.7, 1))));
  }

  void _gravityBoost() {
    _boostApproach(BoostType.gravity, tiles: 3);
    final boostedMax = envelope.maxGravityBoostGap(
      speed: speed,
      margin: margin,
    );
    _jumpGap(
      _boostedWidth(boostedMax),
      0,
      time: envelope.gravityBoostJumpDistance / envelope.topSpeed,
    );
  }

  /// Places a checkpoint at the start of the current run once the time since
  /// the last respawn point passes [threshold] times the stage's spacing.
  void _maybeCheckpoint({required double threshold}) {
    if (sinceRespawn < parameters.checkpointSpacing * threshold) return;
    if (runLength < 2 * tileSize) return;
    checkpoints.add(Checkpoint(Vec2(runStart + tileSize / 2, y)));
    sinceRespawn = 0;
  }
}
