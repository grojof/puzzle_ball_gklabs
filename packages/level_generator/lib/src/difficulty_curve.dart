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
    required this.margin,
    required this.obstacleShare,
    required this.targetDuration,
    required this.checkpointSpacing,
    required this.weights,
  });

  /// The level number, from 1.
  final int level;

  /// The stage, from 0; each stage has [DifficultyCurve.stageLength] levels.
  final int stage;

  /// The level's position inside its stage, from 0.
  final int positionInStage;

  /// Whether this is one of the stage's gentler levels.
  final bool isBreather;

  /// Overall difficulty from 0 (first level) towards 1.
  final double intensity;

  /// The fraction of the movement envelope that gaps and climbs may use.
  final double margin;

  /// The probability that a section is an obstacle rather than flat ground.
  final double obstacleShare;

  /// The estimated play time to aim for, in seconds.
  final double targetDuration;

  /// The longest stretch between respawn points, in seconds; infinite when
  /// the stage has no checkpoints.
  final double checkpointSpacing;

  /// The relative frequency of each obstacle section allowed in this level.
  final Map<SectionKind, double> weights;
}

/// Maps a level number to [LevelParameters]: stages of ten that introduce
/// elements in order, a sawtooth of gentler levels, growing length, and
/// difficulty that keeps rising without ever leaving the movement envelope.
class DifficultyCurve {
  /// The default curve.
  const new();

  /// Levels per stage.
  static const stageLength = 10;

  /// Positions inside a stage that are breathers.
  static const breatherPositions = {3, 7};

  /// How much easier a breather is.
  static const breatherFactor = 0.65;

  /// How much easier the first level of a stage is, while it introduces an
  /// element.
  static const introFactor = 0.85;

  /// The margin of the very first level.
  static const minMargin = 0.45;

  /// The margin that deep levels approach and never reach.
  static const maxMargin = 0.85;

  /// Levels over which the base intensity rises most of the way.
  static const intensityScale = 40.0;

  /// The stage at which each obstacle becomes available.
  static const Map<SectionKind, int> introductionStage = {
    SectionKind.rampUp: 0,
    SectionKind.rampDown: 0,
    SectionKind.gap: 0,
    SectionKind.drop: 1,
    SectionKind.stepUp: 2,
    SectionKind.speedBoost: 2,
    SectionKind.chainedGaps: 3,
    SectionKind.jumpBoost: 3,
    SectionKind.gravityBoost: 4,
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
  };

  /// The parameters of [level] (from 1).
  LevelParameters parametersFor(int level) {
    if (level < 1) {
      throw ArgumentError.value(level, 'level', 'must be at least 1');
    }
    final stage = (level - 1) ~/ stageLength;
    final position = (level - 1) % stageLength;
    final isBreather = breatherPositions.contains(position);
    final factor = isBreather
        ? breatherFactor
        : position == 0 && stage > 0
        ? introFactor
        : 1.0;
    final base = 1 - math.exp(-(level - 1) / intensityScale);
    final intensity = _quantize(base * factor);
    final weights = {
      for (final MapEntry(key: kind, value: weight) in _baseWeights.entries)
        if (introductionStage[kind]! <= stage)
          // The stage that introduces an element features it.
          kind: introductionStage[kind] == stage && stage > 0
              ? weight * 2
              : weight,
    };
    return LevelParameters(
      level: level,
      stage: stage,
      positionInStage: position,
      isBreather: isBreather,
      intensity: intensity,
      margin: _quantize(minMargin + (maxMargin - minMargin) * intensity),
      obstacleShare: _quantize(0.35 + 0.45 * intensity),
      targetDuration: _quantize(
        35 +
            115 * (1 - math.exp(-(level - 1) / 60)) +
            25 * (1 - math.exp(-(level - 1) / 600)),
      ),
      checkpointSpacing: stage == 0
          ? double.infinity
          : _quantize(40 - 5 * math.min(1, stage / 10)),
      weights: weights,
    );
  }

  /// Rounds to a millionth, so that the last-bit differences of `exp` across
  /// platforms cannot change a generated level (design D2).
  static double _quantize(double value) =>
      (value * 1000000).roundToDouble() / 1000000;
}
