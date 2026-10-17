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

    test('margins grow towards the cap without reaching it', () {
      expect(
        curve.parametersFor(1).margin,
        inInclusiveRange(DifficultyCurve.minMargin, 0.65),
      );
      final deep = curve.parametersFor(10000).margin;
      expect(deep, lessThanOrEqualTo(DifficultyCurve.maxMargin));
      expect(
        curve.parametersFor(300).margin,
        greaterThan(curve.parametersFor(100).margin),
      );
      expect(
        curve.parametersFor(300).obstacleShare,
        greaterThan(curve.parametersFor(100).obstacleShare),
      );
    });

    test('starts with the basic obstacles and adds a boost every stage', () {
      expect(
        curve.parametersFor(1).weights.keys,
        unorderedEquals([
          SectionKind.rampUp,
          SectionKind.rampDown,
          SectionKind.gap,
          SectionKind.drop,
          SectionKind.stepUp,
        ]),
      );
      expect(
        curve.parametersFor(5).weights,
        isNot(contains(SectionKind.speedBoost)),
      );
      expect(curve.parametersFor(6).weights, contains(SectionKind.speedBoost));
      expect(
        curve.parametersFor(10).weights,
        isNot(contains(SectionKind.jumpBoost)),
      );
      expect(curve.parametersFor(11).weights, contains(SectionKind.jumpBoost));
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
            DifficultyCurve.introductionStage[kind],
            lessThanOrEqualTo(p.stage),
          );
        }
      }
      expect(
        curve.parametersFor(16).weights,
        contains(SectionKind.gravityBoost),
      );
    });

    test('a stage features the element it introduces', () {
      final intro = curve.parametersFor(6);
      final later = curve.parametersFor(11);
      expect(intro.weights[SectionKind.speedBoost], 1);
      expect(later.weights[SectionKind.speedBoost], 0.5);
      expect(curve.parametersFor(1).weights[SectionKind.gap], 1.4);
      expect(intro.intensity, lessThan(curve.parametersFor(5).intensity));
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
