import 'dart:math' as math;

import 'package:level_generator/level_generator.dart';
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

  group('precision', () {
    test('early gaps need most of the reach, deep ones nearly all', () {
      List<double> shares(int from, int to) => [
        for (final seed in seeds)
          for (var n = from; n <= to; n++)
            ...validator.gapShares(level(n, seed)),
      ];
      final early = shares(1, 5);
      final deep = shares(300, 304);
      double mean(List<double> values) =>
          values.reduce((a, b) => a + b) / values.length;
      // The validator's speed is generous, so these are lower bounds.
      expect(mean(early), inInclusiveRange(0.5, 0.85));
      expect(early.reduce(math.max), lessThanOrEqualTo(0.85));
      expect(mean(deep), greaterThan(mean(early)));
      expect(deep.reduce(math.max), lessThanOrEqualTo(0.96));
    });
  });

  group('set pieces and character', () {
    /// Consecutive floor runs that touch, as (previous, next) pairs.
    Iterable<(FloorRun, FloorRun)> joined(LevelData data) sync* {
      for (var i = 1; i < data.floors.length; i++) {
        final (before, after) = (data.floors[i - 1], data.floors[i]);
        if ((after.left - before.right).abs() < 1e-9) yield (before, after);
      }
    }

    /// Whether [data] has two height changes in the [up] direction joined by
    /// a tread of one or two tiles.
    bool hasFlight(LevelData data, {required bool up}) {
      final changes = [
        for (final (before, after) in joined(data))
          if (up ? after.top < before.top : after.top > before.top) after,
      ];
      for (var i = 0; i < changes.length - 1; i++) {
        final tread = changes[i];
        final next = changes[i + 1];
        if ((next.left - tread.right).abs() < 1e-9 &&
            tread.size.x <= 2 * tileSize + 1e-9) {
          return true;
        }
      }
      return false;
    }

    LevelData withSection(SectionKind kind) {
      for (final seed in seeds) {
        for (var n = 1; n <= 60; n++) {
          final data = level(n, seed);
          if (data.sections.contains(kind)) return data;
        }
      }
      throw StateError('no $kind generated');
    }

    test('staircases and cascades chain their steps with short treads', () {
      expect(hasFlight(withSection(SectionKind.staircase), up: true), isTrue);
      expect(hasFlight(withSection(SectionKind.cascade), up: false), isTrue);
    });

    test('valleys go down and back up to the same height', () {
      final data = withSection(SectionKind.valley);
      final downs = data.ramps.where((ramp) => !ramp.ascending);
      final ups = data.ramps.where((ramp) => ramp.ascending);
      expect(
        downs.any(
          (down) => ups.any(
            (up) =>
                up.left > down.right &&
                (up.size.y - down.size.y).abs() < 1e-9 &&
                (up.top - down.top).abs() < 1e-9,
          ),
        ),
        isTrue,
      );
    });

    test('island hops change height between platforms', () {
      final data = withSection(SectionKind.chainedGaps);
      final tops = data.floors.map((run) => run.top).toSet();
      expect(tops.length, greaterThan(2));
    });

    test('each level features two or three kinds of its own', () {
      for (final seed in seeds) {
        final featured = <String>{};
        for (var n = 20; n < 30; n++) {
          final data = level(n, seed);
          expect(data.featured.length, inInclusiveRange(2, 3));
          expect(
            curve.parametersFor(n).weights.keys,
            containsAll(data.featured),
          );
          featured.add(
            (data.featured.map((k) => k.name).toList()..sort()).join(),
          );
        }
        expect(featured.length, greaterThan(1), reason: seed);
      }
    });

    test('featured kinds make up most obstacles', () {
      var obstacles = 0;
      var featured = 0;
      for (final seed in seeds) {
        for (var n = 1; n <= 100; n++) {
          final data = level(n, seed);
          for (final kind in data.sections) {
            if (kind == SectionKind.flat) continue;
            obstacles++;
            if (data.featured.contains(kind)) featured++;
          }
        }
      }
      expect(featured / obstacles, greaterThan(0.55));
    });
  });

  group('structure', () {
    test('the first two levels mix the basics, spikes and set pieces', () {
      const basics = {
        SectionKind.flat,
        SectionKind.rampUp,
        SectionKind.rampDown,
        SectionKind.gap,
        SectionKind.drop,
        SectionKind.stepUp,
        SectionKind.staircase,
        SectionKind.cascade,
        SectionKind.valley,
        SectionKind.spikes,
      };
      final seen = <SectionKind>{};
      for (final seed in seeds) {
        for (var n = 1; n <= 2; n++) {
          final data = level(n, seed);
          expect(data.sections.toSet().difference(basics), isEmpty);
          expect(data.boosts, isEmpty);
          expect(data.platforms, isEmpty);
          expect(data.floors.where((floor) => floor.crumbling), isEmpty);
          seen.addAll(data.sections);
        }
      }
      expect(seen, basics);
    });

    test('no level uses an element before its introduction', () {
      for (final seed in seeds) {
        for (var n = 1; n <= 60; n++) {
          for (final kind in level(n, seed).sections) {
            if (kind == SectionKind.flat) continue;
            expect(
              DifficultyCurve.introductionLevel[kind],
              lessThanOrEqualTo(n),
              reason: '$seed / level $n uses $kind',
            );
          }
        }
      }
    });

    test('each element appears, featured, in the level that introduces it', () {
      // Level 1 has too many first elements to fit them all.
      for (final MapEntry(key: kind, value: intro)
          in DifficultyCurve.introductionLevel.entries) {
        if (intro == 1) continue;
        for (final seed in seeds) {
          final data = level(intro, seed);
          expect(data.sections, contains(kind), reason: '$seed / $kind');
          expect(data.featured, contains(kind), reason: '$seed / $kind');
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
            final served = switch (boost.type) {
              BoostType.speed => [SectionKind.speedBoost],
              BoostType.jump => [SectionKind.jumpBoost],
              BoostType.gravity => [SectionKind.gravityBoost],
              BoostType.doubleJump => [
                SectionKind.orbGap,
                SectionKind.orbClimb,
              ],
            };
            expect(
              data.sections.toSet().intersection(served.toSet()),
              isNotEmpty,
            );
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

    test('spikes lie inside runs, as wide as a jump clears', () {
      var checked = 0;
      for (final seed in seeds) {
        for (var n = 1; n <= 60; n++) {
          final data = level(n, seed);
          final margin = curve.parametersFor(n).margin;
          for (final strip in data.hazards) {
            final run = data.floors.singleWhere(
              (f) => strip.left >= f.left && strip.right <= f.right,
            );
            expect(strip.top, run.top);
            expect(strip.left - run.left, greaterThanOrEqualTo(tileSize));
            expect(run.right - strip.right, greaterThanOrEqualTo(tileSize));
            expect(strip.width, greaterThanOrEqualTo(1));
            expect(
              strip.width,
              lessThanOrEqualTo(
                testEnvelope.maxGap(
                  speed: testEnvelope.topSpeed,
                  rise: 0,
                  margin: margin,
                ),
              ),
            );
            expect(run, isNot(data.floors.first));
            expect(run, isNot(data.floors.last));
            checked++;
          }
        }
      }
      expect(checked, greaterThan(0));
    });

    test('ferries cross gaps too wide to jump, from edge to edge', () {
      var checked = 0;
      for (final seed in seeds) {
        for (var n = 3; n <= 60; n++) {
          final data = level(n, seed);
          for (final ferry in data.platforms) {
            final near = data.floors.lastWhere((f) => f.right <= ferry.start.x);
            final far = data.floors.firstWhere(
              (f) => f.left >= ferry.end.x + ferry.size.x,
            );
            expect(ferry.start.x - near.right, closeTo(0.15, 1e-9));
            expect(far.left - ferry.end.x - ferry.size.x, closeTo(0.15, 1e-9));
            expect((ferry.start.y, ferry.end.y), (near.top, far.top));
            expect(
              far.left - near.right,
              greaterThan(
                testEnvelope.maxGap(
                      speed: testEnvelope.topSpeed,
                      rise: 0,
                      margin: 1,
                    ) *
                    0.5,
              ),
            );
            expect((ferry.speed, ferry.pause), (2.2, 0.8));
            expect(ferry.size.x, 2 * tileSize);
            checked++;
          }
        }
      }
      expect(checked, greaterThan(0));
    });

    test('crumbling islands are one or two tiles between gaps', () {
      var checked = 0;
      for (final seed in seeds) {
        for (var n = 6; n <= 60; n++) {
          final data = level(n, seed);
          final floors = data.floors;
          for (var i = 0; i < floors.length; i++) {
            if (!floors[i].crumbling) continue;
            expect(
              floors[i].size.x,
              anyOf(closeTo(tileSize, 1e-9), closeTo(2 * tileSize, 1e-9)),
            );
            expect(floors[i].left, greaterThan(floors[i - 1].right));
            expect(floors[i + 1].left, greaterThan(floors[i].right));
            checked++;
          }
        }
      }
      expect(checked, greaterThan(0));
    });

    test('orbs precede gaps and climbs beyond one jump', () {
      var gaps = 0;
      var climbs = 0;
      for (final seed in seeds) {
        for (var n = 21; n <= 120; n++) {
          final data = level(n, seed);
          final margin = curve.parametersFor(n).margin;
          for (final orb in data.boosts.where(
            (b) => b.type == BoostType.doubleJump,
          )) {
            final i = data.floors.indexWhere(
              (f) => orb.position.x >= f.left && orb.position.x <= f.right,
            );
            final floor = data.floors[i];
            final next = data.floors[i + 1];
            if (next.left - floor.right > 1e-9) {
              expect(
                next.left - floor.right,
                lessThanOrEqualTo(
                  testEnvelope.maxDoubleJumpGap(
                    speed: testEnvelope.topSpeed,
                    margin: margin,
                  ),
                ),
              );
              gaps++;
            } else {
              final climb = floor.top - next.top;
              expect(climb, greaterThan(testEnvelope.maxClimb(margin)));
              expect(
                climb,
                lessThanOrEqualTo(testEnvelope.maxDoubleJumpClimb(margin)),
              );
              climbs++;
            }
          }
        }
      }
      expect(gaps, greaterThan(0));
      expect(climbs, greaterThan(0));
    });

    test('estimated durations follow the pacing', () {
      for (final seed in seeds) {
        // About 35-45 s; the last section may run a little over.
        expect(level(3, seed).estimatedDuration, inInclusiveRange(30, 48));
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

const goldenDigests = [1292913836, 3135107716, 577518912];
