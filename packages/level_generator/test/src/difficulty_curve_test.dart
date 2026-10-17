import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

void main() {
  const curve = DifficultyCurve();

  group('DifficultyCurve', () {
    test('rejects levels below 1', () {
      expect(() => curve.parametersFor(0), throwsArgumentError);
    });

    test('groups levels in stages of ten', () {
      final p = curve.parametersFor(23);
      expect((p.level, p.stage, p.positionInStage), (23, 2, 2));
    });

    test('breathers are easier than the levels around them', () {
      for (final level in [4, 8, 14, 18, 54, 104]) {
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
      expect(curve.parametersFor(1).margin, DifficultyCurve.minMargin);
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

    test('introduces elements stage by stage', () {
      expect(
        curve.parametersFor(3).weights.keys,
        unorderedEquals([
          SectionKind.rampUp,
          SectionKind.rampDown,
          SectionKind.gap,
        ]),
      );
      final stage1 = curve.parametersFor(15).weights.keys;
      expect(stage1, contains(SectionKind.drop));
      expect(stage1, isNot(contains(SectionKind.speedBoost)));
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
        curve.parametersFor(41).weights,
        contains(SectionKind.gravityBoost),
      );
    });

    test('a stage features the element it introduces', () {
      final intro = curve.parametersFor(21);
      final later = curve.parametersFor(31);
      expect(intro.weights[SectionKind.stepUp], 2);
      expect(later.weights[SectionKind.stepUp], 1);
      expect(intro.intensity, lessThan(curve.parametersFor(20).intensity));
    });

    test('levels last 30-45 s early and 2-3 min deep', () {
      expect(curve.parametersFor(3).targetDuration, inInclusiveRange(30, 45));
      expect(
        curve.parametersFor(150).targetDuration,
        inInclusiveRange(120, 180),
      );
      expect(curve.parametersFor(10000).targetDuration, lessThanOrEqualTo(180));
    });

    test('checkpoints start in the second stage, at most 40 s apart', () {
      expect(curve.parametersFor(9).checkpointSpacing, double.infinity);
      expect(curve.parametersFor(11).checkpointSpacing, lessThanOrEqualTo(40));
      expect(curve.parametersFor(500).checkpointSpacing, 35);
    });
  });
}
