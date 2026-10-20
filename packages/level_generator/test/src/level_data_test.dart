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

  group('new physics elements', () {
    final hill = CurvedRun.bumps(
      kind: CurveKind.hill,
      left: 10,
      ground: 4,
      bumps: const [(4, 1), (2, 0.5)],
    );

    test('surfaces show in a run and change it', () {
      const plain = FloorRun(position: Vec2(0, 4), size: Vec2(3, 1.5));
      const mud = FloorRun(
        position: Vec2(0, 4),
        size: Vec2(3, 1.5),
        surface: FloorSurface.mud,
      );
      expect(mud, isNot(plain));
      expect(mud.hashCode, isNot(plain.hashCode));
      expect('$mud', endsWith('mud'));
      expect('$plain', isNot(contains('plain')));
    });

    test('bumps start and end on the ground, every half meter at most', () {
      expect(hill.left, 10);
      expect(hill.right, 16);
      expect(hill.points.first, const Vec2(10, 4));
      expect(hill.points.last.y, 4);
      expect(hill.top, closeTo(3, 1e-9));
      expect(hill.bottom, 4);
      expect(hill.points, hasLength(1 + 8 + 4));
      // Halfway along the first bump, at its crest.
      expect(hill.heightAt(12), closeTo(3, 1e-9));
      // Between the points at 11 and 11.5.
      expect(hill.heightAt(11.25), closeTo((3.4375 + 3.12109375) / 2, 1e-9));
      expect(hill.heightAt(9), 4);
      expect(hill.heightAt(17), 4);
      final pipe = CurvedRun.bumps(
        kind: CurveKind.halfPipe,
        left: 0,
        ground: 4,
        bumps: const [(6, -2)],
      );
      expect(pipe.bottom, closeTo(6, 1e-9));
      expect(pipe.top, 4);
    });

    test('slopes are rounded, flat at both ends', () {
      final up = CurvedRun.slope(left: 2, from: 4, to: 1, width: 6.6);
      expect(up.kind, CurveKind.slope);
      expect(up.points.first, const Vec2(2, 4));
      expect(up.points.last.x, closeTo(8.6, 1e-9));
      expect(up.points.last.y, 1);
      expect(up.rises, isTrue);
      expect(up.heightAt(5.3), closeTo(2.5, 1e-9));
      // Flat where it meets the runs: the first step barely rises.
      expect(4 - up.points[1].y, lessThan(0.1));
      final down = CurvedRun.slope(left: 0, from: 1, to: 4, width: 6.6);
      expect(down.rises, isFalse);
      expect(down.bottom, 4);
    });

    test('curves have value equality and readable text', () {
      final same = CurvedRun.bumps(
        kind: CurveKind.hill,
        left: 10,
        ground: 4,
        bumps: const [(4, 1), (2, 0.5)],
      );
      expect(hill, same);
      expect(hill.hashCode, same.hashCode);
      expect(
        hill,
        isNot(CurvedRun(kind: CurveKind.halfPipe, points: hill.points)),
      );
      expect(
        hill,
        isNot(CurvedRun(kind: CurveKind.hill, points: hill.points.sublist(1))),
      );
      expect(
        hill,
        isNot(
          CurvedRun(
            kind: CurveKind.hill,
            points: [...hill.points.sublist(1), const Vec2(99, 4)],
          ),
        ),
      );
      expect('$hill', startsWith('Curve.hill(10.000, 4.000)'));
    });

    test('trampolines and loops expose their edges, equality and text', () {
      const pad = Trampoline(position: Vec2(3, 4), width: 1.5);
      expect((pad.left, pad.right, pad.top), (3, 4.5, 4));
      expect(pad, const Trampoline(position: Vec2(3, 4), width: 1.5));
      expect(pad, isNot(const Trampoline(position: Vec2(3, 4), width: 1)));
      expect(
        pad.hashCode,
        const Trampoline(position: Vec2(3, 4), width: 1.5).hashCode,
      );
      expect('$pad', 'Trampoline(3.000, 4.000)1.500');
      const loop = Loop(foot: Vec2(20, 4), radius: 2.5);
      expect(loop.center, const Vec2(20, 1.5));
      expect((loop.left, loop.right, loop.top), (17.5, 22.5, -1));
      expect(loop, const Loop(foot: Vec2(20, 4), radius: 2.5));
      expect(loop, isNot(const Loop(foot: Vec2(20, 4), radius: 2)));
      expect(
        loop.hashCode,
        const Loop(foot: Vec2(20, 4), radius: 2.5).hashCode,
      );
      expect('$loop', 'Loop(20.000, 4.000)2.500');
    });

    test('levels count curves in their lowest point and canonical form', () {
      final data = LevelData(
        seed: 's',
        level: 1,
        ballStart: const Vec2(0.75, 3),
        goal: const Vec2(5, 2.25),
        floors: const [FloorRun(position: Vec2(0, 4), size: Vec2(4.5, 1.5))],
        ramps: const [],
        boosts: const [],
        checkpoints: const [],
        sections: const [],
        estimatedDuration: 10,
        curves: [
          CurvedRun.bumps(
            kind: CurveKind.halfPipe,
            left: 4.5,
            ground: 4,
            bumps: const [(12, -3)],
          ),
        ],
        trampolines: const [Trampoline(position: Vec2(1, 4), width: 1.5)],
        loops: const [Loop(foot: Vec2(2, 4), radius: 1)],
      );
      expect(data.lowestPoint, closeTo(7, 1e-9));
      final text = data.canonical;
      expect(text, contains('Curve.halfPipe'));
      expect(text, contains('Trampoline'));
      expect(text, contains('Loop'));
    });
  });

  group('adrenaline zones', () {
    test('cover their span, with value equality and text', () {
      const zone = AdrenalineZone(left: 2, right: 8);
      expect(zone.covers(2), isTrue);
      expect(zone.covers(8), isTrue);
      expect(zone.covers(9), isFalse);
      expect(zone, const AdrenalineZone(left: 2, right: 8));
      expect(zone, isNot(const AdrenalineZone(left: 2, right: 9)));
      expect(zone.hashCode, const AdrenalineZone(left: 2, right: 8).hashCode);
      expect('$zone', 'Adrenaline(2.000..8.000)');
      const data = LevelData(
        seed: 's',
        level: 5,
        ballStart: Vec2(0.75, 3),
        goal: Vec2(5, 2.25),
        floors: [FloorRun(position: Vec2(0, 4), size: Vec2(9, 1.5))],
        ramps: [],
        boosts: [],
        checkpoints: [],
        sections: [],
        estimatedDuration: 10,
        adrenaline: [zone],
      );
      expect(data.canonical, contains('Adrenaline'));
    });
  });

  group('dynamic elements', () {
    test('fans lift two thirds up their column, with equality and text', () {
      const fan = Fan(left: 2, right: 8, base: 7, top: -1);
      expect(fan.height, 8);
      expect(fan.hover, closeTo(7 - 8 * 2 / 3, 1e-9));
      expect(fan.covers(2), isTrue);
      expect(fan.covers(9), isFalse);
      expect(fan, const Fan(left: 2, right: 8, base: 7, top: -1));
      expect(fan, isNot(const Fan(left: 2, right: 8, base: 7, top: 0)));
      expect(
        fan.hashCode,
        const Fan(left: 2, right: 8, base: 7, top: -1).hashCode,
      );
      expect(fan.toString(), 'Fan(2.000..8.000, 7.000..-1.000)');
    });

    test('bumpers have a top, value equality and text', () {
      const bumper = Bumper(Vec2(1, 2));
      expect(bumper.top, 2 - bumperRadius);
      expect(bumper, const Bumper(Vec2(1, 2)));
      expect(bumper, isNot(const Bumper(Vec2(1, 3))));
      expect(bumper.hashCode, const Bumper(Vec2(1, 2)).hashCode);
      expect(bumper.toString(), 'Bumper(1.000, 2.000)');
      const climbing = Bumper(Vec2(1, 2), radius: climbBumperRadius, lean: -1);
      expect(climbing.top, 2 - climbBumperRadius);
      expect(climbing, isNot(bumper));
      expect(climbing.toString(), 'Bumper(1.000, 2.000) r0.500 lean-1');
    });

    test('pendulums reach the lane over a strip, with equality and text', () {
      const pendulum = Pendulum(
        pivot: Vec2(10, 0),
        length: 3,
        period: 4,
        clear: 0.25,
        phase: 1,
      );
      expect(pendulum.ground, closeTo(3 + maceRadius + maceClearance, 1e-9));
      // √(3² − 2.55²) + the mace.
      expect(pendulum.reach, closeTo(1.5803 + maceRadius, 1e-4));
      expect(pendulum.left, closeTo(10 - pendulum.reach, 1e-9));
      expect(pendulum.right, closeTo(10 + pendulum.reach, 1e-9));
      expect(pendulum.clearTime, 1);
      const same = Pendulum(
        pivot: Vec2(10, 0),
        length: 3,
        period: 4,
        clear: 0.25,
        phase: 1,
      );
      expect(pendulum, same);
      expect(pendulum.hashCode, same.hashCode);
      expect(
        pendulum,
        isNot(
          const Pendulum(
            pivot: Vec2(10, 0),
            length: 3,
            period: 4,
            clear: 0.25,
            phase: 2,
          ),
        ),
      );
      expect(
        pendulum.toString(),
        'Pendulum(10.000, 0.000) 3.000 4.000/0.250+1.000',
      );
    });

    test('seesaws place their ends at rest and tipped, with equality and '
        'text', () {
      const seesaw = Seesaw(pivot: Vec2(10, 3), halfLength: 5, rest: 3, tip: 4);
      expect(seesaw.nearEnd, const Vec2(6, 6));
      expect(seesaw.farEndAtRest, const Vec2(14, 0));
      expect(seesaw.farEnd, const Vec2(13, 7));
      expect((seesaw.left, seesaw.right), (6, 14));
      const same = Seesaw(pivot: Vec2(10, 3), halfLength: 5, rest: 3, tip: 4);
      expect(seesaw, same);
      expect(seesaw.hashCode, same.hashCode);
      expect(
        seesaw,
        isNot(
          const Seesaw(pivot: Vec2(10, 3), halfLength: 5, rest: 3, tip: 3.5),
        ),
      );
      expect(seesaw.toString(), 'Seesaw(10.000, 3.000) 5.000 3.000/4.000');
    });

    test('levels count fans in their lowest point and list every element', () {
      const data = LevelData(
        seed: 's',
        level: 1,
        ballStart: Vec2(0.75, 3),
        goal: Vec2(10, 2.25),
        floors: [FloorRun(position: Vec2(0, 4), size: Vec2(12, 1.5))],
        ramps: [],
        boosts: [],
        checkpoints: [],
        sections: [],
        estimatedDuration: 10,
        fans: [Fan(left: 2, right: 8, base: 9, top: 1)],
        bumpers: [Bumper(Vec2(1, 2))],
        pendulums: [
          Pendulum(
            pivot: Vec2(10, 0),
            length: 3,
            period: 4,
            clear: 0.25,
            phase: 1,
          ),
        ],
        seesaws: [Seesaw(pivot: Vec2(10, 3), halfLength: 5, rest: 3, tip: 4)],
      );
      expect(data.lowestPoint, 9);
      final text = data.canonical;
      expect(text, contains('Fan('));
      expect(text, contains('Bumper('));
      expect(text, contains('Pendulum('));
      expect(text, contains('Seesaw('));
    });
  });
}
