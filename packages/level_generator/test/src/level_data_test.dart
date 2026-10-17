import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

void main() {
  group('Vec2', () {
    test('adds, compares and prints', () {
      expect(const Vec2(1, 2) + const Vec2(3, 4), const Vec2(4, 6));
      expect(const Vec2(1, 2).hashCode, const Vec2(1, 2).hashCode);
      expect(const Vec2(1, 2), isNot(const Vec2(2, 1)));
      expect(const Vec2(1, 2).toString(), '(1.000, 2.000)');
    });
  });

  group('elements', () {
    const floor = FloorRun(position: Vec2(1, 4), size: Vec2(3, 1.5));
    const ramp = Ramp(position: Vec2(4, 2), size: Vec2(3, 2), ascending: true);
    const boost = Boost(position: Vec2(2, 3.4), type: BoostType.speed);
    const checkpoint = Checkpoint(Vec2(2, 3.75));

    test('expose their edges', () {
      expect((floor.left, floor.right, floor.top), (1, 4, 4));
      expect((ramp.left, ramp.right, ramp.top, ramp.bottom), (4, 7, 2, 4));
    });

    test('have value equality and readable text', () {
      expect(floor, const FloorRun(position: Vec2(1, 4), size: Vec2(3, 1.5)));
      expect(floor.hashCode, isNot(0));
      expect(
        ramp,
        isNot(
          const Ramp(position: Vec2(4, 2), size: Vec2(3, 2), ascending: false),
        ),
      );
      expect(ramp.hashCode, isNot(0));
      expect(boost, const Boost(position: Vec2(2, 3.4), type: BoostType.speed));
      expect(boost.hashCode, isNot(0));
      expect(checkpoint, const Checkpoint(Vec2(2, 3.75)));
      expect(checkpoint.hashCode, const Vec2(2, 3.75).hashCode);
      expect('$floor $ramp $boost $checkpoint', contains('Boost.speed'));
      expect(
        const Ramp(
          position: Vec2(0, 0),
          size: Vec2(1, 1),
          ascending: false,
        ).toString(),
        endsWith('down'),
      );
    });
  });

  group('LevelData', () {
    const level = LevelData(
      seed: 's',
      level: 1,
      ballStart: Vec2(0.75, 3),
      goal: Vec2(5, 2.25),
      floors: [
        FloorRun(position: Vec2(0, 4), size: Vec2(4.5, 1.5)),
        FloorRun(position: Vec2(6, 7), size: Vec2(4.5, 3)),
      ],
      ramps: [
        Ramp(position: Vec2(4.5, 4), size: Vec2(1.5, 9), ascending: false),
      ],
      boosts: [Boost(position: Vec2(1, 3.4), type: BoostType.jump)],
      checkpoints: [Checkpoint(Vec2(7, 6.75))],
      sections: [SectionKind.rampDown],
      estimatedDuration: 10,
    );

    test('finds the lowest terrain point among floors and ramps', () {
      expect(level.lowestPoint, 13);
    });

    test('has a canonical text form listing every element', () {
      final text = level.canonical;
      expect(text, startsWith('seed=s level=1'));
      expect(text.split('\n'), hasLength(6));
    });
  });
}
