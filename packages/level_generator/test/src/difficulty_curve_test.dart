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

    test('precision rises from about 70-80 % to about 90-95 %', () {
      final (firstLow, firstHigh) = curve.parametersFor(1).precision;
      expect(firstLow, closeTo(0.71, 0.01));
      expect(firstHigh, closeTo(0.82, 0.01));
      expect(curve.parametersFor(1).margin, firstHigh);
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

    test(
      'starts with the basic obstacles and introduces the rest by level',
      () {
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
          ]),
        );
        expect(
          curve.parametersFor(2).weights,
          isNot(contains(SectionKind.ferry)),
        );
        expect(curve.parametersFor(3).weights, contains(SectionKind.ferry));
        expect(
          curve.parametersFor(6).weights,
          contains(SectionKind.crumblingHops),
        );
        expect(
          curve.parametersFor(20).weights,
          isNot(contains(SectionKind.orbGap)),
        );
        expect(curve.parametersFor(21).weights, contains(SectionKind.orbGap));
        expect(curve.parametersFor(21).weights, contains(SectionKind.orbClimb));
        expect(
          curve.parametersFor(5).weights,
          isNot(contains(SectionKind.speedBoost)),
        );
        expect(
          curve.parametersFor(6).weights,
          contains(SectionKind.speedBoost),
        );
        expect(
          curve.parametersFor(10).weights,
          isNot(contains(SectionKind.jumpBoost)),
        );
        expect(
          curve.parametersFor(11).weights,
          contains(SectionKind.jumpBoost),
        );
        expect(
          curve.parametersFor(11).weights,
          contains(SectionKind.chainedGaps),
        );
        expect(
          curve.parametersFor(15).weights,
          isNot(contains(SectionKind.gravityBoost)),
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
        expect(
          curve.parametersFor(16).weights,
          contains(SectionKind.gravityBoost),
        );
      },
    );

    test('knows which elements each level introduces', () {
      expect(curve.parametersFor(1).introduces, isEmpty);
      expect(curve.parametersFor(2).introduces, isEmpty);
      expect(curve.parametersFor(3).introduces, {SectionKind.ferry});
      expect(curve.parametersFor(21).introduces, {
        SectionKind.orbGap,
        SectionKind.orbClimb,
      });
      expect(curve.parametersFor(22).introduces, isEmpty);
    });

    test('the five levels from an introduction feature the element', () {
      final intro = curve.parametersFor(6);
      expect(intro.weights[SectionKind.speedBoost], 1);
      expect(curve.parametersFor(10).weights[SectionKind.speedBoost], 1);
      expect(curve.parametersFor(11).weights[SectionKind.speedBoost], 0.5);
      expect(curve.parametersFor(3).weights[SectionKind.ferry], 1);
      expect(curve.parametersFor(8).weights[SectionKind.ferry], 0.5);
      expect(curve.parametersFor(1).weights[SectionKind.gap], 1.4);
      expect(curve.parametersFor(2).weights[SectionKind.spikes], 0.9);
      expect(intro.intensity, lessThan(curve.parametersFor(5).intensity));
      // A level that introduces nothing is not eased.
      expect(
        curve.parametersFor(26).intensity,
        greaterThan(curve.parametersFor(25).intensity),
      );
    });

    test('levels last 30-45 s early and 2-3 min deep', () {
      expect(curve.parametersFor(3).targetDuration, inInclusiveRange(30, 45));
      expect(
        curve.parametersFor(150).targetDuration,
        inInclusiveRange(120, 180),
      );
      expect(curve.parametersFor(10000).targetDuration, lessThanOrEqualTo(180));
    });

    test('checkpoints are at most 40 s apart, 35 s deep', () {
      expect(curve.parametersFor(1).checkpointSpacing, lessThanOrEqualTo(40));
      expect(curve.parametersFor(500).checkpointSpacing, 35);
    });
  });
}
