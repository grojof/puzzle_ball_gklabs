import 'dart:math' as math;

import 'package:level_generator/src/level_data.dart';
import 'package:meta/meta.dart';

/// What the generator should build for one level.
@immutable
class LevelParameters {
  /// Parameters for [level].
  const new({
    required this.level,
    required this.stage,
    required this.positionInStage,
    required this.isBreather,
    required this.intensity,
    required this.precision,
    required this.margin,
    required this.obstacleShare,
    required this.targetDuration,
    required this.checkpointSpacing,
    required this.weights,
    this.introduces = const {},
  });

  /// The level number, from 1.
  final int level;

  /// The stage, from 0; each stage has [DifficultyCurve.stageLength] levels.
  final int stage;

  /// The level's position inside its stage, from 0.
  final int positionInStage;

  /// Whether this is one of the stage's gentler levels.
  final bool isBreather;

  /// Overall difficulty, from [DifficultyCurve.startIntensity] at the first
  /// level towards 1.
  final double intensity;

  /// The interval of the reach that gaps and climbs use: drawn uniformly
  /// between its ends. Grows with intensity, from about 70–80 % on the first
  /// levels to about 90–95 % deep (level-generation spec).
  final (double, double) precision;

  /// The most of the reach any gap or climb may use: the precision
  /// interval's high end, which the validator checks against.
  final double margin;

  /// The probability that a section is an obstacle rather than flat ground.
  final double obstacleShare;

  /// The estimated play time to aim for, in seconds.
  final double targetDuration;

  /// The longest stretch between respawn points, in seconds.
  final double checkpointSpacing;

  /// The relative frequency of each obstacle section allowed in this level.
  final Map<SectionKind, double> weights;

  /// The sections that first appear in this level: each is featured and
  /// used at least once.
  final Set<SectionKind> introduces;
}

/// Maps a level number to [LevelParameters]: a demanding start with the
/// basic obstacles, stages of five that add the boosts in order, a sawtooth
/// of gentler levels, growing length, and difficulty that keeps rising
/// without ever leaving the movement envelope.
class DifficultyCurve {
  /// The default curve.
  const new();

  /// Levels per stage.
  static const stageLength = 5;

  /// Positions inside a stage that are breathers.
  static const breatherPositions = {3};

  /// How much easier a breather is.
  static const breatherFactor = 0.65;

  /// How much easier a level that introduces an element is.
  static const introFactor = 0.85;

  /// How many levels feature an element from its introduction.
  static const featureLength = 5;

  /// The intensity of the very first level: already a real challenge.
  static const startIntensity = 0.45;

  /// The share of the reach that gaps and climbs use, at intensity 0 and
  /// how much it grows with intensity, for the interval's low and high ends
  /// (design D3 of add-physical-mechanics).
  static const precisionLowBase = 0.55;

  /// How much the precision interval's low end grows with intensity.
  static const precisionLowGrowth = 0.35;

  /// The precision interval's high end at intensity 0.
  static const precisionHighBase = 0.72;

  /// How much the precision interval's high end grows with intensity.
  static const precisionHighGrowth = 0.23;

  /// Levels over which the base intensity rises most of the way to 1.
  static const intensityScale = 60.0;

  /// The level at which each obstacle first appears (design D5 of
  /// add-physical-mechanics).
  static const Map<SectionKind, int> introductionLevel = {
    SectionKind.rampUp: 1,
    SectionKind.rampDown: 1,
    SectionKind.gap: 1,
    SectionKind.drop: 1,
    SectionKind.stepUp: 1,
    SectionKind.staircase: 1,
    SectionKind.cascade: 1,
    SectionKind.valley: 1,
    SectionKind.spikes: 1,
    SectionKind.ferry: 3,
    SectionKind.speedBoost: 6,
    SectionKind.crumblingHops: 6,
    SectionKind.jumpBoost: 11,
    SectionKind.chainedGaps: 11,
    SectionKind.gravityBoost: 16,
    SectionKind.orbGap: 21,
    SectionKind.orbClimb: 21,
  };

  static const Map<SectionKind, double> _baseWeights = {
    SectionKind.rampUp: 1.0,
    SectionKind.rampDown: 1.0,
    SectionKind.gap: 1.4,
    SectionKind.drop: 0.8,
    SectionKind.stepUp: 1.0,
    SectionKind.speedBoost: 0.5,
    SectionKind.chainedGaps: 0.8,
    SectionKind.jumpBoost: 0.5,
    SectionKind.gravityBoost: 0.4,
    SectionKind.staircase: 0.8,
    SectionKind.cascade: 0.7,
    SectionKind.valley: 0.8,
    SectionKind.spikes: 0.9,
    SectionKind.ferry: 0.5,
    SectionKind.crumblingHops: 0.6,
    SectionKind.orbGap: 0.4,
    SectionKind.orbClimb: 0.35,
  };

  /// The parameters of [level] (from 1).
  LevelParameters parametersFor(int level) {
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'must be at least 1');
    }
    final stage = (level - 1) ~/ stageLength;
    final position = (level - 1) % stageLength;
    final isBreather = breatherPositions.contains(position);
    final introduces = {
      if (level > 1)
        for (final MapEntry(key: kind, value: first)
            in introductionLevel.entries)
          if (first == level) kind,
    };
    final factor = isBreather
        ? breatherFactor
        : introduces.isNotEmpty
        ? introFactor
        : 1.0;
    final base =
        startIntensity +
        (1 - startIntensity) * (1 - math.exp(-(level - 1) / intensityScale));
    final intensity = _quantize(base * factor);
    final weights = {
      for (final MapEntry(key: kind, value: weight) in _baseWeights.entries)
        if (introductionLevel[kind]! <= level)
          // The levels right after an element's introduction feature it.
          kind: _featuring(introductionLevel[kind]!, level)
              ? weight * 2
              : weight,
    };
    return LevelParameters(
      level: level,
      stage: stage,
      positionInStage: position,
      isBreather: isBreather,
      intensity: intensity,
      precision: (
        _quantize(precisionLowBase + precisionLowGrowth * intensity),
        _quantize(precisionHighBase + precisionHighGrowth * intensity),
      ),
      margin: _quantize(precisionHighBase + precisionHighGrowth * intensity),
      obstacleShare: _quantize(0.35 + 0.45 * intensity),
      targetDuration: _quantize(
        35 +
            115 * (1 - math.exp(-(level - 1) / 60)) +
            25 * (1 - math.exp(-(level - 1) / 600)),
      ),
      checkpointSpacing: _quantize(40 - 5 * math.min(1, level / 100)),
      weights: weights,
      introduces: introduces,
    );
  }

  /// Whether [level] is among the first levels of an element introduced
  /// after level 1 at [introduction].
  static bool _featuring(int introduction, int level) =>
      introduction > 1 && level < introduction + featureLength;

  /// Rounds to a millionth, so that the last-bit differences of `exp` across
  /// platforms cannot change a generated level (design D2).
  static double _quantize(double value) =>
      (value * 1000000).roundToDouble() / 1000000;
}
