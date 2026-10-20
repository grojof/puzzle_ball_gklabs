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
      expect(mean(early), inInclusiveRange(0.6, 0.9));
      // Never beyond the first level's margin: about 90 %.
      expect(
        early.reduce(math.max),
        lessThanOrEqualTo(curve.parametersFor(1).margin + 1e-9),
      );
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
      final slopes = data.curves.where((c) => c.kind == CurveKind.slope);
      final downs = slopes.where((slope) => !slope.rises);
      final ups = slopes.where((slope) => slope.rises);
      expect(
        downs.any(
          (down) => ups.any(
            (up) =>
                up.left > down.right &&
                ((up.bottom - up.top) - (down.bottom - down.top)).abs() <
                    1e-9 &&
                (up.top - down.top).abs() < 1e-9,
          ),
        ),
        isTrue,
      );
      // Slopes are rounded: no straight ramps any more.
      expect(data.ramps, isEmpty);
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
    test('the first level mixes the basics, spikes and set pieces', () {
      const basics = {
        SectionKind.flat,
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
        SectionKind.breakPoint,
      };
      final seen = <SectionKind>{};
      for (final seed in [...seeds, ...seeds.map((s) => '$s+')]) {
        for (var n = 1; n <= 1; n++) {
          final data = level(n, seed);
          expect(data.sections.toSet().difference(basics), isEmpty);
          expect(data.boosts, isEmpty);
          expect(data.platforms, isEmpty);
          expect(data.floors.where((floor) => floor.crumbling), isEmpty);
          expect(data.trampolines, isEmpty);
          expect(data.loops, isEmpty);
          expect(
            data.floors.where((floor) => floor.surface != FloorSurface.plain),
            isEmpty,
          );
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
              // Hills and half-pipes may launch the ball with one too.
              BoostType.speed => [
                SectionKind.speedBoost,
                SectionKind.loop,
                SectionKind.hill,
                SectionKind.halfPipe,
              ],
              // Break points and deep towers climb with jump boosts too.
              BoostType.jump => [
                SectionKind.jumpBoost,
                SectionKind.breakPoint,
                SectionKind.tower,
              ],
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
            expect(
              strip.left - run.left,
              greaterThanOrEqualTo(tileSize - 1e-9),
            );
            expect(
              run.right - strip.right,
              greaterThanOrEqualTo(tileSize - 1e-9),
            );
            expect(strip.width, greaterThanOrEqualTo(1));
            // In an adrenaline zone the ball runs faster.
            final rush = data.adrenaline.any((z) => z.covers(strip.left));
            expect(
              strip.width,
              lessThanOrEqualTo(
                testEnvelope.maxGap(
                  speed:
                      testEnvelope.topSpeed *
                      (rush ? testEnvelope.rushGain : 1),
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

    /// The longest run of consecutive floor-to-floor changes in [data] that
    /// all go the same way ([up] or down), summed, in meters.
    double longestRun(LevelData data, {required bool up}) {
      var best = 0.0;
      var run = 0.0;
      final floors = data.floors;
      for (var i = 1; i < floors.length; i++) {
        final change = floors[i - 1].top - floors[i].top;
        final along = up ? change : -change;
        if (along > 1e-9) {
          run += along;
          if (run > best) best = run;
        } else if (along < -1e-9) {
          run = 0;
        }
      }
      return best;
    }

    test('towers climb at least 8 m', () {
      var checked = 0;
      for (final seed in seeds) {
        for (var n = 1; n <= 40; n++) {
          final data = level(n, seed);
          if (!data.sections.contains(SectionKind.tower)) continue;
          expect(longestRun(data, up: true), greaterThanOrEqualTo(8));
          checked++;
        }
      }
      expect(checked, greaterThan(0));
    });

    test('descents go a long way down', () {
      var checked = 0;
      for (final seed in seeds) {
        for (var n = 1; n <= 40; n++) {
          final data = level(n, seed);
          if (!data.sections.contains(SectionKind.descent)) continue;
          expect(longestRun(data, up: false), greaterThanOrEqualTo(6.5));
          checked++;
        }
      }
      expect(checked, greaterThan(0));
    });

    test('long levels climb and descend over a wide band', () {
      for (final seed in seeds) {
        for (final n in [50, 150, 300]) {
          final tops = [for (final floor in level(n, seed).floors) floor.top];
          final span = tops.reduce(math.max) - tops.reduce(math.min);
          expect(span, greaterThan(15), reason: '$seed / level $n');
          expect(span, lessThanOrEqualTo(75), reason: '$seed / level $n');
        }
      }
    });

    test('laser barriers guard descents and clear the route', () {
      var guarded = 0;
      for (final seed in seeds) {
        for (var n = 1; n <= 40; n++) {
          final data = level(n, seed);
          final clearance = LaserClearance(
            envelope: testEnvelope,
            floors: data.floors,
            ramps: data.ramps,
            platforms: data.platforms,
            boosts: data.boosts,
            curves: data.curves,
            trampolines: data.trampolines,
            loops: data.loops,
          );
          for (final laser in data.lasers) {
            final lowest = clearance.lowestEnd(laser.x)!;
            expect(laser.bottom, lessThanOrEqualTo(lowest));
            expect(laser.top, lessThan(laser.bottom));
          }
          if (data.sections.contains(SectionKind.descent)) {
            guarded += data.lasers.isEmpty ? 0 : 1;
          }
          // Consecutive barriers alternate.
          for (var i = 1; i < data.lasers.length; i++) {
            expect(data.lasers[i].phase, isNot(data.lasers[i - 1].phase));
          }
        }
      }
      expect(guarded, greaterThan(0));
    });

    test('estimated durations follow the pacing', () {
      for (final seed in seeds) {
        // About 1.5 min first, 4 min deep; the last section may run over.
        expect(level(1, seed).estimatedDuration, inInclusiveRange(80, 105));
        expect(level(300, seed).estimatedDuration, inInclusiveRange(210, 255));
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

  group('curved terrain and new physics', () {
    /// Every level from [from] to [to] for every seed.
    Iterable<(int, LevelData)> levels(int from, int to) sync* {
      for (final seed in seeds) {
        for (var n = from; n <= to; n++) {
          yield (n, level(n, seed));
        }
      }
    }

    test('curves join their runs, gentle and smooth', () {
      final kinds = <CurveKind>{};
      var bumps = 0;
      for (final (_, data) in levels(1, 40)) {
        for (final curve in data.curves) {
          kinds.add(curve.kind);
          final ground = curve.points.first.y;
          if (curve.kind != CurveKind.slope) {
            expect(curve.points.last.y, ground);
          }
          expect(data.floors.any((floor) => floor.right == curve.left), isTrue);
          expect(data.floors.any((floor) => floor.left == curve.right), isTrue);
          for (var i = 1; i < curve.points.length; i++) {
            final a = curve.points[i - 1];
            final b = curve.points[i];
            expect(b.x - a.x, inExclusiveRange(0, CurvedRun.step + 1e-9));
            expect(
              (b.y - a.y).abs(),
              lessThanOrEqualTo(LevelValidator.maxSlope * (b.x - a.x)),
            );
          }
          final extreme = curve.bottom - curve.top;
          // Descents may go a little past 3 m.
          expect(extreme, inInclusiveRange(0.5, 6.0));
          if (curve.kind == CurveKind.hill) bumps++;
        }
      }
      expect(kinds, CurveKind.values.toSet());
      expect(bumps, greaterThan(0));
    });

    test('trampolines are islands across a pit, before a bounce', () {
      var hops = 0;
      for (final (_, data) in levels(9, 40)) {
        for (final pad in data.trampolines) {
          final i = data.floors.indexWhere(
            (f) =>
                f.top == pad.top && pad.left >= f.left && pad.right <= f.right,
          );
          expect(i, greaterThanOrEqualTo(0));
          final floor = data.floors[i];
          final next = data.floors[i + 1];
          expect(floor.size.x, closeTo(2 * tileSize, 1e-9));
          expect(pad.width, closeTo(floor.size.x, 1e-9));
          expect(next.left, greaterThan(floor.right));
          hops++;
        }
      }
      expect(hops, greaterThan(0));
    });

    test('belts, ice and mud lie before gaps or climbs sized for them', () {
      final surfaces = <FloorSurface>{};
      for (final (n, data) in levels(11, 40)) {
        final margin = curve.parametersFor(n).margin;
        for (var i = 0; i < data.floors.length - 1; i++) {
          final floor = data.floors[i];
          if (floor.surface == FloorSurface.plain) continue;
          surfaces.add(floor.surface);
          final next = data.floors[i + 1];
          final rise = floor.top - next.top;
          final gap = next.left - floor.right;
          final climbs = gap.abs() < 1e-9 && rise > 0;
          expect(
            gap > 0 || climbs,
            isTrue,
            reason: 'level $n at ${floor.left}',
          );
          if (climbs) {
            expect(floor.surface, FloorSurface.mud);
            expect(
              rise,
              lessThanOrEqualTo(
                testEnvelope.maxClimb(margin, surface: FloorSurface.mud),
              ),
            );
          }
        }
      }
      expect(surfaces, {
        FloorSurface.conveyorForward,
        FloorSurface.conveyorBackward,
        FloorSurface.ice,
        FloorSurface.mud,
      });
    });

    test('loops stand on their run with a speed boost just before', () {
      var checked = 0;
      for (final (_, data) in levels(13, 40)) {
        for (final loop in data.loops) {
          expect(loop.radius, loopRadius);
          expect(
            data.boosts.where(
              (boost) =>
                  boost.type == BoostType.speed &&
                  (boost.position.x - (loop.left - loopBoostLead)).abs() < 1e-9,
            ),
            hasLength(1),
          );
          final run = data.floors.singleWhere(
            (floor) => floor.left <= loop.left && floor.right >= loop.right,
          );
          expect(run.top, loop.foot.y);
          expect(run.right, greaterThanOrEqualTo(loop.right + tileSize));
          checked++;
        }
      }
      expect(checked, greaterThan(0));
    });

    test('the levels that introduce the new physics feature it', () {
      for (final seed in seeds) {
        expect(level(9, seed).trampolines, isNotEmpty);
        expect(
          level(
            11,
            seed,
          ).floors.where((floor) => floor.surface != FloorSurface.plain),
          isNotEmpty,
        );
        expect(level(13, seed).loops, isNotEmpty);
        for (final n in [3, 5, 8]) {
          final early = level(n, seed);
          expect(early.trampolines, isEmpty);
          expect(early.loops, isEmpty);
        }
      }
    });
  });
  group('flow and pacing', () {
    Iterable<(int, LevelData)> levels(int from, int to) sync* {
      for (final seed in seeds) {
        for (var n = from; n <= to; n++) {
          yield (n, level(n, seed));
        }
      }
    }

    /// The share of a level's obstacles that are break points.
    double breaks(int from, int to) {
      var breakPoints = 0;
      var obstacles = 0;
      for (final (_, data) in levels(from, to)) {
        for (final kind in data.sections) {
          if (kind == SectionKind.flat) continue;
          obstacles++;
          if (kind == SectionKind.breakPoint) breakPoints++;
        }
      }
      return breakPoints / obstacles;
    }

    test('break points come more often deep', () {
      expect(breaks(1, 5), greaterThan(0));
      expect(breaks(300, 305), greaterThan(breaks(1, 5) * 1.5));
    });

    test('break points take three shapes, each close to its hazard', () {
      var treads = 0;
      var spiked = 0;
      var crests = 0;
      for (final (_, data) in levels(1, 60)) {
        final floors = data.floors;
        for (var i = 1; i + 1 < floors.length; i++) {
          final run = floors[i];
          final next = floors[i + 1];
          final single = (run.size.x - tileSize).abs() < 1e-9;
          final gapBefore = run.left - floors[i - 1].right > 1e-9;
          if (single && gapBefore && (next.left - run.right).abs() < 1e-9) {
            if (run.top - next.top > 0) treads++;
          }
          if (data.hazards.any(
            (strip) => (strip.left - run.left - 2 * tileSize).abs() < 1e-9,
          )) {
            spiked++;
          }
          final crest = data.curves.any(
            (curve) =>
                curve.kind == CurveKind.hill &&
                (curve.right - run.left).abs() < 1e-9,
          );
          if (crest && single && next.left - run.right > 1e-9) crests++;
        }
      }
      expect(treads, greaterThan(0));
      expect(spiked, greaterThan(0));
      expect(crests, greaterThan(0));
    });

    test('flow phrases and challenge phrases share every long level', () {
      const flow = {
        SectionKind.hill,
        SectionKind.halfPipe,
        SectionKind.rampDown,
        SectionKind.gap,
        SectionKind.drop,
        SectionKind.cascade,
        SectionKind.speedBoost,
        SectionKind.loop,
        SectionKind.trampolineHops,
        SectionKind.conveyor,
        SectionKind.bumperPosts,
        SectionKind.seesaw,
      };
      var total = 0;
      var mixed = 0;
      for (final (_, data) in levels(40, 45)) {
        final kinds = data.sections.toSet();
        expect(kinds.intersection(flow), isNotEmpty);
        total++;
        // A challenge phrase may draw flow kinds too, when the level
        // features them: only nearly every level shows another kind.
        if (kinds.difference(flow).difference({SectionKind.flat}).isNotEmpty) {
          mixed++;
        }
      }
      expect(mixed / total, greaterThan(0.9));
    });

    test('no plain climb follows another', () {
      for (final (n, data) in levels(1, 80)) {
        final obstacles = data.sections.where((k) => k != SectionKind.flat);
        SectionKind? last;
        for (final kind in obstacles) {
          final plain = DifficultyCurve.plainClimbs.contains(kind);
          if (plain) {
            expect(
              DifficultyCurve.plainClimbs.contains(last),
              isFalse,
              reason: 'level $n: $last then $kind',
            );
          }
          last = kind;
        }
      }
    });

    test('deep towers mix in jump-boost steps', () {
      var boosted = 0;
      for (final (_, data) in levels(150, 200)) {
        final floors = data.floors;
        for (var i = 1; i < floors.length; i++) {
          final tread = floors[i];
          // A one-tile tread reached by a step, with a jump boost on it.
          final stepped =
              (tread.left - floors[i - 1].right).abs() < 1e-9 &&
              floors[i - 1].top > tread.top;
          final single = (tread.size.x - tileSize).abs() < 1e-9;
          final boost = data.boosts.any(
            (b) =>
                b.type == BoostType.jump &&
                b.position.x >= tread.left &&
                b.position.x <= tread.right,
          );
          if (stepped && single && boost) boosted++;
        }
      }
      expect(boosted, greaterThan(0));
    });

    test('deep levels are fuller of rich sections', () {
      double rich(int from, int to) {
        var richCount = 0;
        var obstacles = 0;
        for (final (_, data) in levels(from, to)) {
          for (final kind in data.sections) {
            if (kind == SectionKind.flat) continue;
            obstacles++;
            if (DifficultyCurve.richKinds.contains(kind)) richCount++;
          }
        }
        return richCount / obstacles;
      }

      expect(rich(60, 64), greaterThan(rich(15, 19)));
    });

    test('adrenaline zones start at level 5 and size gaps for the rush', () {
      for (final (n, data) in levels(1, 4)) {
        expect(data.adrenaline, isEmpty, reason: 'level $n');
      }
      for (final seed in seeds) {
        expect(level(5, seed).adrenaline, isNotEmpty, reason: seed);
      }
      var beyondPlain = 0;
      for (final (n, data) in levels(5, 80)) {
        final margin = curve.parametersFor(n).margin;
        for (final zone in data.adrenaline) {
          expect(zone.right, greaterThan(zone.left));
          expect(
            data.checkpoints.where((c) => zone.covers(c.position.x)),
            isEmpty,
          );
        }
        final floors = data.floors;
        for (var i = 0; i + 1 < floors.length; i++) {
          final gap = floors[i + 1].left - floors[i].right;
          if (gap <= 0) continue;
          if (!data.adrenaline.any((z) => z.covers(floors[i].right))) continue;
          final rise = floors[i].top - floors[i + 1].top;
          final plain = testEnvelope.maxGap(
            speed: testEnvelope.topSpeed,
            rise: rise,
            margin: margin,
          );
          if (gap > plain) beyondPlain++;
        }
      }
      expect(beyondPlain, greaterThan(0));
    });
  });
  group('dynamic elements', () {
    Iterable<(int, LevelData)> levels(int from, int to) sync* {
      for (final seed in seeds) {
        for (var n = from; n <= to; n++) {
          yield (n, level(n, seed));
        }
      }
    }

    test('each first appears in its own level, and never before', () {
      for (final seed in seeds) {
        expect(level(15, seed).fans, isNotEmpty, reason: seed);
        expect(level(17, seed).bumpers, isNotEmpty, reason: seed);
        expect(level(19, seed).pendulums, isNotEmpty, reason: seed);
        expect(level(21, seed).seesaws, isNotEmpty, reason: seed);
        for (var n = 1; n < 15; n++) {
          expect(level(n, seed).fans, isEmpty);
        }
        for (var n = 15; n < 17; n++) {
          expect(level(n, seed).bumpers, isEmpty);
        }
        for (var n = 17; n < 19; n++) {
          expect(level(n, seed).pendulums, isEmpty);
        }
        for (var n = 19; n < 21; n++) {
          expect(level(n, seed).seesaws, isEmpty);
        }
      }
    });

    test('fans float the ball clear of the banks and catch it below', () {
      var gaps = 0;
      var climbs = 0;
      var split = 0;
      for (final (_, data) in levels(15, 80)) {
        final floors = data.floors;
        for (var i = 0; i + 1 < floors.length; i++) {
          final floor = floors[i];
          final next = floors[i + 1];
          final columns = [
            for (final fan in data.fans)
              if (fan.left >= floor.right - 1e-9 &&
                  fan.right <= next.left + 1e-9)
                fan,
          ];
          if (columns.isNotEmpty) {
            gaps++;
            if (columns.length > 1) split++;
            for (final fan in columns) {
              expect(
                fan.hover,
                lessThanOrEqualTo(
                  math.min(floor.top, next.top) -
                      testEnvelope.fanClearance +
                      1e-9,
                ),
              );
              expect(
                fan.base,
                greaterThanOrEqualTo(
                  floor.top + testEnvelope.fanCatchDepth - 1e-9,
                ),
              );
            }
            for (var c = 1; c < columns.length; c++) {
              expect(
                columns[c].left - columns[c - 1].right,
                lessThanOrEqualTo(tileSize + 1e-9),
              );
            }
            // Wider than a jump reaches.
            expect(
              next.left - floor.right,
              greaterThan(
                testEnvelope.maxGap(
                  speed: testEnvelope.topSpeed,
                  rise: 0,
                  margin: 1,
                ),
              ),
            );
          }
          final floorFan = data.fans.where(
            (fan) => fan.base == floor.top && fan.right == floor.right,
          );
          if (floorFan.isNotEmpty) {
            climbs++;
            expect(
              floor.top - next.top,
              greaterThan(testEnvelope.jumpBoostHeight),
            );
            expect(
              next.top - floorFan.single.hover,
              greaterThanOrEqualTo(testEnvelope.fanClearance - 1e-9),
            );
          }
        }
      }
      expect(gaps, greaterThan(0));
      expect(climbs, greaterThan(0));
      expect(split, greaterThan(0));
    });

    test('bumper posts stand on runs past a gap, and risers kick back', () {
      var posts = 0;
      var deep = 0;
      var risers = 0;
      for (final (n, data) in levels(17, 80)) {
        final floors = data.floors;
        final margin = curve.parametersFor(n).margin;
        for (var i = 0; i + 1 < floors.length; i++) {
          final floor = floors[i];
          final next = floors[i + 1];
          final stand = floor.top - bumperStand - bumperRadius;
          final on = data.bumpers.where(
            (bumper) =>
                (bumper.center.y - stand).abs() < 1e-9 &&
                bumper.center.x > floor.left &&
                bumper.center.x < floor.right,
          );
          if (on.isNotEmpty) {
            posts += on.length;
            if (on.length > 1) deep++;
            // A gap before the run, a tile to jump from, a tile to land on.
            expect(floor.left, greaterThan(floors[i - 1].right));
            expect(
              on.first.center.x - postSpan / 2 - floor.left,
              closeTo(tileSize, 1e-9),
            );
            expect(
              floor.right - on.last.center.x - postSpan / 2,
              greaterThanOrEqualTo(tileSize - 1e-9),
            );
            // Jumped like spikes as wide as the span.
            expect(
              postSpan,
              lessThanOrEqualTo(
                testEnvelope.maxGap(
                  speed: testEnvelope.speedCurve.first,
                  rise: 0,
                  margin: margin,
                ),
              ),
            );
          }
          final riser = (next.left + bumperInset, floor.top - bumperRadius);
          if (data.bumpers.any(
            (bumper) =>
                (bumper.center.x - riser.$1).abs() < 1e-9 &&
                (bumper.center.y - riser.$2).abs() < 1e-9,
          )) {
            expect(next.top, lessThan(floor.top));
            risers++;
          }
        }
      }
      expect(posts, greaterThan(0));
      expect(deep, greaterThan(0));
      expect(risers, greaterThan(0));
    });

    test('hills and half-pipes carry spikes or launch the ball, more '
        'often deep', () {
      double share(int from, int to) {
        var curves = 0;
        var carried = 0;
        for (final (_, data) in levels(from, to)) {
          for (final curve in data.curves) {
            if (curve.kind == CurveKind.slope) continue;
            curves++;
            final after = data.floors
                .where((floor) => (floor.left - curve.right).abs() < 1e-9)
                .firstOrNull;
            if (after == null) continue;
            final spiked = data.hazards.any(
              (strip) => strip.left >= after.left && strip.right <= after.right,
            );
            final boosted = data.boosts.any(
              (boost) =>
                  boost.type == BoostType.speed &&
                  boost.position.x >= after.left &&
                  boost.position.x <= after.right,
            );
            if (spiked || boosted) carried++;
          }
        }
        return carried / curves;
      }

      expect(share(3, 10), greaterThan(0.25));
      expect(share(120, 130), greaterThan(share(3, 10)));
    });

    test('pendulums leave room to wait and time to cross', () {
      var gauntlets = 0;
      for (final (_, data) in levels(19, 80)) {
        final byRun = <double, List<Pendulum>>{};
        for (final pendulum in data.pendulums) {
          const room = pendulumRoom * tileSize;
          final crossing = testEnvelope.pushTime(
            room,
            room + 2 * (pendulum.reach + ballRadius),
          );
          expect(crossing, lessThanOrEqualTo(pendulum.clearTime));
          final run = data.floors.singleWhere(
            (floor) =>
                floor.left <= pendulum.pivot.x &&
                floor.right >= pendulum.pivot.x &&
                (floor.top - pendulum.ground).abs() < 1e-9,
          );
          (byRun[run.left] ??= []).add(pendulum);
          expect(
            pendulum.left - ballRadius - run.left,
            greaterThanOrEqualTo(pendulumRoom * tileSize - 1e-9),
          );
          expect(
            run.right - pendulum.right - ballRadius,
            greaterThanOrEqualTo(tileSize - 1e-9),
          );
        }
        for (final run in byRun.values) {
          if (run.length > 1) gauntlets++;
          for (var i = 1; i < run.length; i++) {
            expect(
              run[i].left - run[i - 1].right - 2 * ballRadius,
              greaterThanOrEqualTo(pendulumRoom * tileSize - 1e-9),
            );
          }
        }
      }
      expect(gauntlets, greaterThan(0));
    });

    test('seesaws rest level with their run and reach their bank', () {
      var seesaws = 0;
      for (final (n, data) in levels(21, 80)) {
        final margin = curve.parametersFor(n).margin;
        for (final seesaw in data.seesaws) {
          seesaws++;
          final near = data.floors.lastWhere(
            (floor) => floor.right <= seesaw.left + 1e-9,
          );
          final bank = data.floors.firstWhere(
            (floor) => floor.left >= seesaw.right,
          );
          expect(seesaw.left - near.right, closeTo(seesawCrack, 1e-9));
          expect(seesaw.nearEnd.y, closeTo(near.top, 1e-9));
          final far = seesaw.farEnd;
          final reach = testEnvelope.maxSeesawGap(
            rise: far.y - bank.top,
            margin: margin,
          );
          expect(bank.left - far.x, lessThanOrEqualTo(reach + 1e-9));
        }
      }
      expect(seesaws, greaterThan(0));
    });

    test('deep levels use them all', () {
      final kinds = <SectionKind>{};
      for (final (_, data) in levels(60, 70)) {
        kinds.addAll(data.sections);
      }
      expect(
        kinds,
        containsAll([
          SectionKind.fanGap,
          SectionKind.fanClimb,
          SectionKind.bumperPosts,
          SectionKind.pendulums,
          SectionKind.seesaw,
        ]),
      );
    });
  });
}

const goldenDigests = [768873675, 2649850469, 3036758814];
