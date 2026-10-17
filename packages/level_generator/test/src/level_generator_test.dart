import 'package:level_generator/level_generator.dart';
import 'package:level_generator/src/random.dart';
import 'package:test/test.dart';

import '../helpers/envelope.dart';

void main() {
  const generator = LevelGenerator(envelope: testEnvelope);
  const validator = LevelValidator(envelope: testEnvelope);
  const curve = DifficultyCurve();
  const seeds = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];

  LevelData level(int n, [String seed = 'a']) =>
      generator.generate(seed: seed, level: n);

  group('determinism', () {
    test('the same seed and level give the same level', () {
      expect(level(37).canonical, level(37).canonical);
    });

    test('different seeds or levels give different layouts', () {
      expect(level(37).canonical, isNot(level(37, 'b').canonical));
      expect(level(37).canonical, isNot(level(38).canonical));
    });

    test('digests match on every platform (golden)', () {
      // Computed once; the suite runs on the VM and in Chrome.
      expect([
        for (final n in [1, 37, 150]) fnv1a32(level(n, 'golden').canonical),
      ], goldenDigests);
    });

    test('rejects levels below 1', () {
      expect(() => level(0), throwsArgumentError);
    });
  });

  group('every generated level is valid', () {
    test('levels 1-200 for ten seeds', () {
      for (final seed in seeds) {
        for (var n = 1; n <= 200; n++) {
          final violations = validator.validate(
            level(n, seed),
            margin: curve.parametersFor(n).margin,
          );
          expect(violations, isEmpty, reason: '$seed / level $n');
        }
      }
    });

    test('deep levels up to 10 000', () {
      for (final seed in seeds) {
        for (final n in [500, 1000, 2500, 5000, 10000]) {
          final violations = validator.validate(
            level(n, seed),
            margin: curve.parametersFor(n).margin,
          );
          expect(violations, isEmpty, reason: '$seed / level $n');
        }
      }
    });
  });

  group('structure', () {
    test('the first stage mixes the basic obstacles, without boosts', () {
      const basics = {
        SectionKind.flat,
        SectionKind.rampUp,
        SectionKind.rampDown,
        SectionKind.gap,
        SectionKind.drop,
        SectionKind.stepUp,
      };
      final seen = <SectionKind>{};
      for (final seed in seeds) {
        for (var n = 1; n <= 5; n++) {
          final data = level(n, seed);
          expect(data.sections.toSet().difference(basics), isEmpty);
          expect(data.boosts, isEmpty);
          seen.addAll(data.sections);
        }
      }
      expect(seen, basics);
    });

    test('no level uses an element before its stage', () {
      for (final seed in seeds) {
        for (var n = 1; n <= 60; n++) {
          final stage = curve.parametersFor(n).stage;
          for (final kind in level(n, seed).sections) {
            if (kind == SectionKind.flat) continue;
            expect(
              DifficultyCurve.introductionStage[kind],
              lessThanOrEqualTo(stage),
              reason: '$seed / level $n uses $kind',
            );
          }
        }
      }
    });

    test('boosts appear only with their sections', () {
      final counts = {for (final type in BoostType.values) type: 0};
      for (final seed in seeds) {
        for (var n = 21; n <= 120; n++) {
          final data = level(n, seed);
          for (final boost in data.boosts) {
            counts[boost.type] = counts[boost.type]! + 1;
            final section = switch (boost.type) {
              BoostType.speed => SectionKind.speedBoost,
              BoostType.jump => SectionKind.jumpBoost,
              BoostType.gravity => SectionKind.gravityBoost,
            };
            expect(data.sections, contains(section));
          }
        }
      }
      expect(counts.values, everyElement(greaterThan(0)));
    });

    test('jump boosts precede climbs beyond a normal jump', () {
      var checked = 0;
      for (final seed in seeds) {
        for (var n = 31; n <= 120; n++) {
          final data = level(n, seed);
          final margin = curve.parametersFor(n).margin;
          for (final boost in data.boosts.where(
            (b) => b.type == BoostType.jump,
          )) {
            final i = data.floors.indexWhere(
              (f) => boost.position.x >= f.left && boost.position.x <= f.right,
            );
            final climb = data.floors[i].top - data.floors[i + 1].top;
            expect(climb, greaterThan(testEnvelope.maxClimb(margin)));
            expect(
              climb,
              lessThanOrEqualTo(testEnvelope.maxBoostedClimb(margin)),
            );
            checked++;
          }
        }
      }
      expect(checked, greaterThan(0));
    });

    test('estimated durations follow the pacing', () {
      for (final seed in seeds) {
        expect(level(3, seed).estimatedDuration, inInclusiveRange(30, 45));
        expect(level(150, seed).estimatedDuration, inInclusiveRange(120, 180));
      }
    });

    test('long levels have checkpoints about every 40 s at most', () {
      for (final seed in seeds) {
        final data = level(150, seed);
        final spacing = curve.parametersFor(150).checkpointSpacing;
        expect(
          data.checkpoints.length,
          greaterThanOrEqualTo(data.estimatedDuration ~/ (spacing * 1.25)),
        );
      }
    });

    test('start, goal and ball sit where the player expects', () {
      final data = level(12);
      final first = data.floors.first;
      expect(first.size.x, greaterThanOrEqualTo(3 * tileSize));
      expect(data.ballStart.y, lessThan(first.top));
      expect(data.goal.x, lessThanOrEqualTo(data.floors.last.right));
      expect(data.lowestPoint, greaterThan(first.top));
    });
  });
}

const goldenDigests = [4205256131, 4081506409, 1832030488];
