import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

void main() {
  const curve = DifficultyCurve();

  group('DifficultyCurve', () {
    test('rejects levels below 1', () {
      expect(() => curve.parametersFor(0), throwsArgumentError);
    });

    test('groups levels in stages of five', () {
      final p = curve.parametersFor(23);
      expect((p.level, p.stage, p.positionInStage), (23, 4, 2));
    });

    test('starts demanding and keeps rising', () {
      final first = curve.parametersFor(1);
      expect(first.intensity, DifficultyCurve.startIntensity);
      expect(first.obstacleShare, greaterThanOrEqualTo(0.55));
      expect(
        curve.parametersFor(50).intensity,
        greaterThan(curve.parametersFor(10).intensity),
      );
    });

    test('breathers are easier than the levels around them', () {
      for (final level in [4, 9, 14, 19, 54, 104]) {
        final breather = curve.parametersFor(level);
        expect(breather.isBreather, isTrue);
        expect(
          breather.intensity,
          lessThan(curve.parametersFor(level - 1).intensity),
        );
        expect(
          breather.intensity,
          lessThan(curve.parametersFor(level + 1).intensity),
        );
      }
    });

    test('starts as demanding as the old level 50, never trivial', () {
      final first = curve.parametersFor(1);
      expect(first.intensity, 0.76);
      final (low, high) = first.precision;
      expect(low, closeTo(0.82, 0.01));
      expect(high, closeTo(0.89, 0.01));
      expect(first.margin, high);
      // Level 4 is a breather: easier, but its gaps still need well over
      // half of the reach.
      final breather = curve.parametersFor(4);
      expect(breather.isBreather, isTrue);
      expect(breather.intensity, closeTo(0.67, 0.01));
      expect(breather.precision.$1, greaterThan(0.75));
    });

    test('precision rises towards 90-95 %', () {
      final (deepLow, deepHigh) = curve.parametersFor(10000).precision;
      expect(deepLow, closeTo(0.9, 0.01));
      expect(deepHigh, lessThanOrEqualTo(0.95));
      expect(deepHigh, greaterThan(0.94));
      final deep = curve.parametersFor(10000).margin;
      expect(deep, deepHigh);
      expect(
        curve.parametersFor(300).margin,
        greaterThan(curve.parametersFor(100).margin),
      );
      expect(
        curve.parametersFor(300).obstacleShare,
        greaterThan(curve.parametersFor(100).obstacleShare),
      );
    });

    test('introduces every element by level 8', () {
      expect(
        curve.parametersFor(1).weights.keys,
        unorderedEquals([
          SectionKind.rampUp,
          SectionKind.rampDown,
          SectionKind.gap,
          SectionKind.drop,
          SectionKind.stepUp,
          SectionKind.staircase,
          SectionKind.cascade,
          SectionKind.valley,
          SectionKind.spikes,
          SectionKind.tower,
          SectionKind.descent,
        ]),
      );
      const order = [
        (2, {SectionKind.ferry}),
        (3, {SectionKind.speedBoost}),
        (4, {SectionKind.crumblingHops}),
        (5, {SectionKind.chainedGaps}),
        (6, {SectionKind.jumpBoost}),
        (7, {SectionKind.gravityBoost}),
        (8, {SectionKind.orbGap, SectionKind.orbClimb}),
      ];
      for (final (level, kinds) in order) {
        expect(curve.parametersFor(level).introduces, kinds);
        for (final kind in kinds) {
          expect(curve.parametersFor(level - 1).weights, isNot(contains(kind)));
          expect(curve.parametersFor(level).weights, contains(kind));
        }
      }
      expect(curve.parametersFor(1).introduces, isEmpty);
      expect(curve.parametersFor(9).introduces, isEmpty);
      expect(
        curve.parametersFor(10).weights.keys,
        unorderedEquals(
          SectionKind.values.where((kind) => kind != SectionKind.flat),
        ),
      );
      for (var level = 1; level <= 60; level++) {
        final p = curve.parametersFor(level);
        for (final kind in p.weights.keys) {
          expect(
            DifficultyCurve.introductionLevel[kind],
            lessThanOrEqualTo(level),
          );
        }
      }
      expect(
        DifficultyCurve.introductionLevel.keys,
        unorderedEquals(
          SectionKind.values.where((kind) => kind != SectionKind.flat),
        ),
      );
    });

    test('the five levels from an introduction feature the element', () {
      final intro = curve.parametersFor(3);
      expect(intro.weights[SectionKind.speedBoost], 1);
      expect(curve.parametersFor(7).weights[SectionKind.speedBoost], 1);
      expect(curve.parametersFor(8).weights[SectionKind.speedBoost], 0.5);
      expect(curve.parametersFor(2).weights[SectionKind.ferry], 1);
      expect(curve.parametersFor(7).weights[SectionKind.ferry], 0.5);
      expect(curve.parametersFor(1).weights[SectionKind.gap], 1.4);
      expect(curve.parametersFor(2).weights[SectionKind.spikes], 0.9);
      // Introductions are eased: level 10, which introduces nothing, is
      // clearly harder than level 8.
      expect(
        curve.parametersFor(10).intensity,
        greaterThan(curve.parametersFor(8).intensity + 0.04),
      );
      // A level that introduces nothing is not eased.
      expect(
        curve.parametersFor(11).intensity,
        greaterThan(curve.parametersFor(10).intensity),
      );
    });

    test('levels last about 1.5 min first and 4 min deep', () {
      expect(curve.parametersFor(1).targetDuration, 90);
      expect(
        curve.parametersFor(50).targetDuration,
        inInclusiveRange(150, 170),
      );
      expect(
        curve.parametersFor(300).targetDuration,
        inInclusiveRange(210, 240),
      );
      expect(curve.parametersFor(10000).targetDuration, lessThanOrEqualTo(240));
    });

    test('checkpoints are at most 35 s apart', () {
      expect(curve.parametersFor(1).checkpointSpacing, 35);
      expect(curve.parametersFor(500).checkpointSpacing, 35);
    });
  });
}
