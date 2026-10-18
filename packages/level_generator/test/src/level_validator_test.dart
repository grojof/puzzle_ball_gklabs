import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

import '../helpers/envelope.dart';

const double _tile = tileSize;

FloorRun floor(double left, double top, {double tiles = 3, double fill = 0}) =>
    FloorRun(
      position: Vec2(left, top),
      size: Vec2(tiles * _tile, _tile + fill),
    );

/// A valid two-run level with a small gap; tests break one rule at a time.
LevelData course({
  List<FloorRun>? floors,
  List<Ramp> ramps = const [],
  List<Boost> boosts = const [],
  List<Checkpoint> checkpoints = const [],
  List<SpikeStrip> hazards = const [],
  List<MovingPlatform> platforms = const [],
  List<LaserBarrier> lasers = const [],
  Vec2 ballStart = const Vec2(0.75, 3),
  Vec2? goal,
}) {
  final runs = floors ?? [floor(0, 4), floor(4.5 + 1.5, 4)];
  return LevelData(
    seed: 'test',
    level: 1,
    ballStart: ballStart,
    goal: goal ?? Vec2(runs.last.right - _tile / 2, runs.last.top - 1.75),
    floors: runs,
    ramps: ramps,
    boosts: boosts,
    checkpoints: checkpoints,
    hazards: hazards,
    platforms: platforms,
    lasers: lasers,
    sections: const [],
    estimatedDuration: 10,
  );
}

void main() {
  const validator = LevelValidator(envelope: testEnvelope);
  List<String> check(LevelData level, {double margin = 0.5}) =>
      validator.validate(level, margin: margin);

  group('LevelValidator', () {
    test('accepts a valid course', () {
      expect(check(course()), isEmpty);
    });

    test('rejects a level without floors', () {
      expect(check(course(floors: const [], goal: const Vec2(0, 0))), [
        'the level has no floor',
      ]);
    });

    test('rejects overlapping floors', () {
      expect(
        check(course(floors: [floor(0, 4), floor(3, 4)])),
        contains(startsWith('floors overlap')),
      );
    });

    test('rejects gaps beyond the reach of the current speed', () {
      expect(
        check(course(floors: [floor(0, 4), floor(4.5 + 6, 4)])),
        contains(startsWith('gap of')),
      );
    });

    test('a speed boost allows a wider gap, and a gravity boost too', () {
      final wide = [floor(0, 4), floor(4.5 + 6, 4), floor(10.5 + 4.5 + 6, 4)];
      expect(
        check(
          course(
            floors: wide,
            boosts: const [
              Boost(position: Vec2(3.75, 3.4), type: BoostType.speed),
              Boost(position: Vec2(14.25, 3.4), type: BoostType.gravity),
            ],
          ),
          margin: 0.8,
        ),
        isEmpty,
      );
    });

    test('rejects climbs beyond a jump, unless a jump boost precedes them', () {
      final steps = [floor(0, 4), floor(4.5, 1)];
      expect(check(course(floors: steps)), contains(startsWith('climb of')));
      expect(
        check(
          course(
            floors: [floor(0, 4), floor(4.5, 1, fill: 3)],
            boosts: const [
              Boost(position: Vec2(3.9, 3.4), type: BoostType.jump),
            ],
          ),
        ),
        isEmpty,
      );
    });

    test('rejects a ledge that leaves a gap below it', () {
      expect(
        check(course(floors: [floor(0, 4), floor(4.5, 2.3)])),
        contains(startsWith('ledge at')),
      );
    });

    test('accepts drops, and ramps that join their floors', () {
      expect(check(course(floors: [floor(0, 4), floor(4.5, 7)])), isEmpty);
      final joined = course(
        floors: [floor(0, 4), floor(6, 2)],
        ramps: const [
          Ramp(position: Vec2(4.5, 2), size: Vec2(1.5, 2), ascending: true),
        ],
      );
      expect(check(joined), isEmpty);
      final down = course(
        floors: [floor(0, 4), floor(6, 6)],
        ramps: const [
          Ramp(position: Vec2(4.5, 4), size: Vec2(1.5, 2), ascending: false),
        ],
      );
      expect(check(down), isEmpty);
    });

    test('rejects ramps that do not join their floors', () {
      final broken = course(
        floors: [floor(0, 4), floor(6, 3)],
        ramps: const [
          Ramp(position: Vec2(4.5, 2), size: Vec2(1.5, 2), ascending: true),
        ],
      );
      expect(check(broken), contains(startsWith('ramp at')));
    });

    test('checks the start platform and the ball', () {
      expect(
        check(course(floors: [floor(0, 4, tiles: 2), floor(4.5, 4)])),
        contains('start platform shorter than three tiles'),
      );
      expect(
        check(course(ballStart: const Vec2(0.75, 5))),
        contains('ball does not start above the start platform'),
      );
    });

    test('checks the goal run and the goal', () {
      expect(
        check(course(floors: [floor(0, 4), floor(6, 4, tiles: 2)])),
        contains('goal run shorter than three tiles'),
      );
      expect(
        check(course(goal: const Vec2(7, 2.25))),
        contains('goal does not stand at the end of the last run'),
      );
    });

    group('spikes', () {
      // A start run, a long middle run for the spikes, and the goal run.
      final runs = [floor(0, 4), floor(6, 4, tiles: 5), floor(15, 4)];
      List<String> spikes(
        SpikeStrip strip, {
        List<Checkpoint> checkpoints = const [],
        double margin = 0.3,
      }) => check(
        course(floors: runs, hazards: [strip], checkpoints: checkpoints),
        margin: margin,
      );

      test('accepts a strip inside a run that a jump clears', () {
        expect(
          spikes(const SpikeStrip(position: Vec2(7.5, 4), width: 1.5)),
          isEmpty,
        );
      });

      test('rejects a strip wider than a jump from the run-up', () {
        expect(
          spikes(const SpikeStrip(position: Vec2(7.5, 4), width: 4.5)),
          contains(startsWith('spikes of')),
        );
      });

      test('rejects a strip less than a tile from a run end', () {
        expect(
          spikes(const SpikeStrip(position: Vec2(6.5, 4), width: 1.5)),
          contains(endsWith('do not lie inside a run')),
        );
      });

      test('rejects a strip on the start run', () {
        expect(
          spikes(const SpikeStrip(position: Vec2(1.5, 4), width: 1.5)),
          contains(endsWith('lie on the start or goal')),
        );
      });

      test('rejects a strip under a checkpoint', () {
        expect(
          spikes(
            const SpikeStrip(position: Vec2(7.5, 4), width: 1.5),
            checkpoints: const [Checkpoint(Vec2(8, 4))],
          ),
          contains(endsWith('lie under an element')),
        );
      });
    });

    test('rejects a floor run shorter than a tile', () {
      final level = course(
        floors: [
          floor(0, 4),
          const FloorRun(position: Vec2(6, 4), size: Vec2(0, _tile)),
          floor(7.5, 4),
        ],
      );
      expect(check(level), contains(endsWith('is shorter than a tile')));
    });

    test('rejects a crumbling island shorter than a tile', () {
      final level = course(
        floors: [
          floor(0, 4),
          const FloorRun(
            position: Vec2(6, 4),
            size: Vec2(0.75, _tile),
            crumbling: true,
          ),
          floor(8.25, 4),
        ],
      );
      expect(check(level), contains(endsWith('is too short')));
    });

    group('orbs', () {
      const orb = Boost(position: Vec2(3.75, 3.4), type: BoostType.doubleJump);

      test('reject a climb a plain jump makes', () {
        final level = course(
          floors: [floor(0, 4), floor(4.5, 3, fill: 1)],
          boosts: const [orb],
        );
        expect(check(level), contains(endsWith('serves no high climb')));
      });

      test('reject a gap a plain jump clears', () {
        expect(
          check(course(boosts: const [orb])),
          contains(endsWith('serves no long gap')),
        );
      });

      test('allow a climb and a gap within the double jump', () {
        final climb = course(
          floors: [floor(0, 4), floor(4.5, 1.5, fill: 2.5)],
          boosts: const [orb],
        );
        expect(check(climb, margin: 0.8), isEmpty);
        final gap = course(
          floors: [floor(0, 4), floor(4.5 + 9, 4)],
          boosts: const [orb],
        );
        expect(check(gap, margin: 0.8), isEmpty);
      });
    });

    group('ferries', () {
      final runs = [floor(0, 4), floor(14.5, 4)];
      MovingPlatform ferry({double end = 11.35, double speed = 2.2}) =>
          MovingPlatform(
            start: const Vec2(4.65, 4),
            end: Vec2(end, 4),
            size: const Vec2(3, 0.5),
            speed: speed,
            pause: 0.8,
          );

      test('bridge a gap too wide to jump', () {
        expect(check(course(floors: runs, platforms: [ferry()])), isEmpty);
      });

      test('must reach both edges', () {
        expect(
          check(course(floors: runs, platforms: [ferry(end: 10)])),
          contains(endsWith('does not reach its edges')),
        );
      });

      test('move at a speed the ball can ride', () {
        expect(
          check(course(floors: runs, platforms: [ferry(speed: 5)])),
          contains(contains('moves at 5')),
        );
      });

      test('have a clear path', () {
        final blocked = course(
          floors: runs,
          platforms: [ferry()],
          boosts: const [Boost(position: Vec2(9, 3.4), type: BoostType.jump)],
        );
        expect(check(blocked), contains(startsWith('something blocks')));
      });
    });

    group('laser barriers', () {
      LaserBarrier laser({double bottom = -0.5, double top = -10}) =>
          LaserBarrier(
            x: 3,
            top: top,
            bottom: bottom,
            on: 1.4,
            off: 1,
            phase: 0,
          );

      test('accept a barrier above every jump of the route', () {
        expect(check(course(lasers: [laser()])), isEmpty);
      });

      test('reject a barrier a jump reaches', () {
        expect(
          check(course(lasers: [laser(bottom: 2)])),
          contains(endsWith('reaches the route')),
        );
      });

      test('reject a malformed barrier', () {
        expect(
          check(course(lasers: [laser(top: 0)])),
          contains(endsWith('is malformed')),
        );
      });
    });

    test('requires boosts above ground and checkpoints on it', () {
      final floating = course(
        boosts: const [Boost(position: Vec2(5, 3.4), type: BoostType.speed)],
        checkpoints: const [Checkpoint(Vec2(1, 1))],
      );
      final violations = check(floating);
      expect(violations, contains(startsWith('boost at')));
      expect(violations, contains(startsWith('checkpoint at')));
    });
  });
}
