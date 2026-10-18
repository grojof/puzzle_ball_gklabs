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
    const spikes = SpikeStrip(position: Vec2(2, 4), width: 1.5);
    const platform = MovingPlatform(
      start: Vec2(4, 4),
      end: Vec2(9, 4),
      size: Vec2(3, 0.5),
      speed: 2.2,
      pause: 0.8,
    );

    test('expose their edges', () {
      expect((floor.left, floor.right, floor.top), (1, 4, 4));
      expect((ramp.left, ramp.right, ramp.top, ramp.bottom), (4, 7, 2, 4));
      expect((spikes.left, spikes.right, spikes.top), (2, 3.5, 4));
    });

    test('laser barriers have a rhythm, value equality and text', () {
      const laser = LaserBarrier(
        x: 5,
        top: -8,
        bottom: 2,
        on: 1.4,
        off: 1,
        phase: 1.2,
      );
      // 1.2 s into a 2.4 s cycle at time zero: lit until 0.2 s, then dark
      // until 1.2 s.
      expect(laser.isOnAt(0), isTrue);
      expect(laser.isOnAt(0.3), isFalse);
      expect(laser.isOnAt(1.3), isTrue);
      expect(
        laser,
        const LaserBarrier(
          x: 5,
          top: -8,
          bottom: 2,
          on: 1.4,
          off: 1,
          phase: 1.2,
        ),
      );
      expect(
        laser,
        isNot(
          const LaserBarrier(
            x: 5,
            top: -8,
            bottom: 2,
            on: 1.4,
            off: 1,
            phase: 0,
          ),
        ),
      );
      expect(laser.hashCode, isNot(0));
      expect('$laser', 'Laser(5.000, -8.000..2.000) 1.400/1.000+1.200');
    });

    test('crumbling runs differ from solid ones', () {
      const crumbling = FloorRun(
        position: Vec2(1, 4),
        size: Vec2(3, 1.5),
        crumbling: true,
      );
      expect(crumbling, isNot(floor));
      expect(crumbling.hashCode, isNot(floor.hashCode));
      expect('$crumbling', endsWith('crumbling'));
      expect('$floor', isNot(contains('crumbling')));
    });

    test('spikes and platforms have value equality and readable text', () {
      expect(spikes, const SpikeStrip(position: Vec2(2, 4), width: 1.5));
      expect(spikes, isNot(const SpikeStrip(position: Vec2(2, 4), width: 2)));
      expect(spikes.hashCode, isNot(0));
      expect('$spikes', 'Spikes(2.000, 4.000)1.500');
      expect(
        platform,
        const MovingPlatform(
          start: Vec2(4, 4),
          end: Vec2(9, 4),
          size: Vec2(3, 0.5),
          speed: 2.2,
          pause: 0.8,
        ),
      );
      expect(
        platform,
        isNot(
          const MovingPlatform(
            start: Vec2(4, 4),
            end: Vec2(9, 4),
            size: Vec2(3, 0.5),
            speed: 2.2,
            pause: 1,
          ),
        ),
      );
      expect(platform.hashCode, isNot(0));
      expect(
        '$platform',
        'Platform(4.000, 4.000)->(9.000, 4.000)(3.000, 0.500) v=2.200 p=0.800',
      );
      expect(
        const Boost(
          position: Vec2(1, 1),
          type: BoostType.doubleJump,
        ).toString(),
        startsWith('Boost.doubleJump'),
      );
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
      hazards: [SpikeStrip(position: Vec2(1.5, 4), width: 1.5)],
      platforms: [
        MovingPlatform(
          start: Vec2(6, 7),
          end: Vec2(8, 7),
          size: Vec2(3, 0.5),
          speed: 2,
          pause: 1,
        ),
      ],
      lasers: [LaserBarrier(x: 3, top: -9, bottom: 1, on: 1, off: 1, phase: 0)],
      sections: [SectionKind.rampDown],
      estimatedDuration: 10,
    );

    test('finds the lowest terrain point among floors and ramps', () {
      expect(level.lowestPoint, 13);
    });

    test('has a canonical text form listing every element', () {
      final text = level.canonical;
      expect(text, startsWith('seed=s level=1'));
      expect(text.split('\n'), hasLength(9));
      expect(text, contains('Laser'));
      expect(text, contains('Spikes'));
      expect(text, contains('Platform'));
    });
  });
}
