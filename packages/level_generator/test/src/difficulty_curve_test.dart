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

    test('starts a little above the old level 50, never trivial', () {
      final first = curve.parametersFor(1);
      expect(first.intensity, 0.8);
      final (low, high) = first.precision;
      expect(low, closeTo(0.83, 0.01));
      expect(high, closeTo(0.904, 0.01));
      expect(first.margin, high);
      // Most sections are obstacles, more than before (0.69).
      expect(first.obstacleShare, closeTo(0.81, 1e-6));
      // Level 4 is a breather: easier, but its gaps still need well over
      // half of the reach.
      final breather = curve.parametersFor(4);
      expect(breather.isBreather, isTrue);
      expect(breather.intensity, closeTo(0.71, 0.01));
      expect(breather.precision.$1, greaterThan(0.75));
    });

    test('depth grows from 0 at the start to 1 deep', () {
      expect(curve.parametersFor(1).depth, 0);
      expect(curve.parametersFor(4).depth, 0);
      expect(curve.parametersFor(60).depth, inExclusiveRange(0.3, 0.6));
      expect(curve.parametersFor(10000).depth, closeTo(1, 0.01));
      expect(curve.parametersFor(1).breakChance, closeTo(0.2, 1e-9));
      expect(curve.parametersFor(10000).breakChance, closeTo(0.8, 0.01));
    });

    test('the adrenaline rush starts at level 5 and grows with depth', () {
      for (final level in [1, 2, 3, 4]) {
        expect(curve.parametersFor(level).rushChance, 0);
        expect(curve.parametersFor(level).introducesRush, isFalse);
      }
      final first = curve.parametersFor(DifficultyCurve.adrenalineLevel);
      expect(first.introducesRush, isTrue);
      expect(first.rushChance, greaterThanOrEqualTo(0.3));
      expect(curve.parametersFor(6).introducesRush, isFalse);
      expect(
        curve.parametersFor(300).rushChance,
        greaterThan(curve.parametersFor(6).rushChance),
      );
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

    test('introduces every element by level 21, leaving room for later '
        'mechanics', () {
      expect(
        curve.parametersFor(1).weights.keys,
        unorderedEquals([
          SectionKind.rampUp,
          SectionKind.rampDown,
          SectionKind.hill,
          SectionKind.halfPipe,
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
        (9, {SectionKind.trampolineHops}),
        (11, {SectionKind.conveyor, SectionKind.ice, SectionKind.mud}),
        (13, {SectionKind.loop}),
        (15, {SectionKind.fanGap, SectionKind.fanClimb}),
        (17, {SectionKind.bumperClimb}),
        (19, {SectionKind.pendulums}),
        (21, {SectionKind.seesaw}),
      ];
      for (final (level, kinds) in order) {
        expect(curve.parametersFor(level).introduces, kinds);
        for (final kind in kinds) {
          expect(curve.parametersFor(level - 1).weights, isNot(contains(kind)));
          expect(curve.parametersFor(level).weights, contains(kind));
        }
      }
      expect(curve.parametersFor(1).introduces, isEmpty);
      // Kept for the logic mechanics of the next change.
      for (final level in [10, 12, 14, 16, 18, 20]) {
        expect(curve.parametersFor(level).introduces, isEmpty);
      }
      expect(
        curve.parametersFor(21).weights.keys,
        unorderedEquals(
          SectionKind.values.where(
            (kind) =>
                kind != SectionKind.flat && kind != SectionKind.breakPoint,
          ),
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
      // Rich kinds grow with depth, and double while featured.
      double rich(int level, double base, {bool featuring = false}) {
        final p = curve.parametersFor(level);
        return (featuring ? 2 * base : base) * (1 + p.depth);
      }

      expect(
        curve.parametersFor(3).weights[SectionKind.speedBoost],
        closeTo(rich(3, 0.5, featuring: true), 1e-5),
      );
      expect(
        curve.parametersFor(7).weights[SectionKind.speedBoost],
        closeTo(rich(7, 0.5, featuring: true), 1e-5),
      );
      expect(
        curve.parametersFor(8).weights[SectionKind.speedBoost],
        closeTo(rich(8, 0.5), 1e-5),
      );
      expect(
        curve.parametersFor(13).weights[SectionKind.loop],
        closeTo(rich(13, 0.4, featuring: true), 1e-5),
      );
      expect(
        curve.parametersFor(18).weights[SectionKind.loop],
        closeTo(rich(18, 0.4), 1e-5),
      );
      // At level 1, plain kinds keep their weights.
      expect(curve.parametersFor(1).weights[SectionKind.gap], 1.4);
      expect(curve.parametersFor(2).weights[SectionKind.spikes], 0.9);
      // Straight ramps share their weight with curves.
      expect(curve.parametersFor(1).weights[SectionKind.rampUp], 0.5);
      expect(curve.parametersFor(1).weights[SectionKind.hill], 1);
      // Deep, plain gaps and plain climbs grow rarer.
      final deep = curve.parametersFor(10000);
      expect(deep.weights[SectionKind.gap], closeTo(1.4 * 0.6, 0.01));
      expect(deep.weights[SectionKind.stepUp], closeTo(0.5, 0.01));
      expect(deep.weights[SectionKind.loop], closeTo(0.8, 0.01));
      // Introductions are eased: level 10, which introduces nothing, is
      // clearly harder than level 8.
      expect(
        curve.parametersFor(10).intensity,
        greaterThan(curve.parametersFor(8).intensity + 0.04),
      );
      // A level that introduces nothing is not eased.
      expect(
        curve.parametersFor(12).intensity,
        greaterThan(curve.parametersFor(11).intensity),
      );
      expect(
        curve.parametersFor(11).intensity,
        lessThan(curve.parametersFor(10).intensity),
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
