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

    test('requires boosts and checkpoints above ground', () {
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
