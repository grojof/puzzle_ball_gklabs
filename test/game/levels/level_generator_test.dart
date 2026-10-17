import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/levels/levels.dart';

void main() {
  group('LevelGenerator', () {
    const tileSize = 1.5;

    test('generates the same level for the same seed', () {
      final a = LevelGenerator.generate(42);
      final b = LevelGenerator.generate(42);

      expect(
        a.floorData.map((f) => f.position),
        orderedEquals(b.floorData.map((f) => f.position)),
      );
      expect(a.goalPosition, b.goalPosition);
    });

    test('starts with a flat platform of three contiguous tiles', () {
      for (final seed in [1, 7, 42, 1234]) {
        final floors = LevelGenerator.generate(seed).floorData.take(3).toList();

        expect(floors.map((f) => f.position.y).toSet(), hasLength(1));
        expect(floors[1].position.x - floors[0].position.x, tileSize);
        expect(floors[2].position.x - floors[1].position.x, tileSize);
      }
    });

    test('spawns the ball above the middle of the first tile', () {
      final level = LevelGenerator.generate(42);
      final first = level.floorData.first.position;

      expect(level.ballStart.x, first.x + tileSize / 2);
      expect(level.ballStart.y, lessThan(first.y));
    });
  });
}
