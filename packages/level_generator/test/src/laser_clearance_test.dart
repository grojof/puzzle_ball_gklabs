import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

import '../helpers/envelope.dart';

void main() {
  const run = FloorRun(position: Vec2(0, 4), size: Vec2(30, tileSize));
  LaserClearance route({
    List<FloorRun> floors = const [run],
    List<Ramp> ramps = const [],
    List<MovingPlatform> platforms = const [],
    List<Boost> boosts = const [],
    List<CurvedRun> curves = const [],
    List<Trampoline> trampolines = const [],
    List<Loop> loops = const [],
    List<AdrenalineZone> adrenaline = const [],
  }) => LaserClearance(
    envelope: testEnvelope,
    floors: floors,
    ramps: ramps,
    platforms: platforms,
    boosts: boosts,
    curves: curves,
    trampolines: trampolines,
    loops: loops,
    adrenaline: adrenaline,
  );

  group('LaserClearance', () {
    test('hangs above a plain jump from the highest ground nearby', () {
      final clearance = route(
        floors: const [
          run,
          FloorRun(position: Vec2(40, 1), size: Vec2(6, tileSize)),
        ],
      );
      expect(clearance.routeTop(15), 4);
      // Over the gap to the higher run, the step between them counts.
      expect(clearance.routeTop(35), 1);
      expect(clearance.clearance(15), testEnvelope.jumpHeight);
      expect(
        clearance.lowestEnd(15),
        4 - testEnvelope.jumpHeight - laserMargin,
      );
      expect(route(floors: const []).routeTop(5), isNull);
      expect(route(floors: const []).lowestEnd(5), isNull);
    });

    test('rises above boosted jumps, ramp launches and platforms', () {
      Boost boost(BoostType type) =>
          Boost(position: const Vec2(12, 3.4), type: type);
      expect(
        route(boosts: [boost(BoostType.jump)]).clearance(15),
        testEnvelope.jumpBoostHeight,
      );
      expect(
        route(boosts: [boost(BoostType.doubleJump)]).clearance(15),
        testEnvelope.doubleJumpHeight,
      );
      expect(
        route(boosts: [boost(BoostType.speed)]).clearance(15),
        testEnvelope.jumpHeight,
      );
      // Far boosts do not count.
      expect(
        route(
          boosts: const [Boost(position: Vec2(50, 3.4), type: BoostType.jump)],
        ).clearance(15),
        testEnvelope.jumpHeight,
      );
      expect(
        route(
          ramps: const [
            Ramp(position: Vec2(14, 2), size: Vec2(3, 2), ascending: true),
          ],
        ).clearance(15),
        rampClearance,
      );
      expect(
        route(
          ramps: const [
            Ramp(position: Vec2(14, 2), size: Vec2(3, 2), ascending: false),
          ],
        ).routeTop(15),
        2,
      );
      final ferry = route(
        platforms: const [
          MovingPlatform(
            start: Vec2(16, 3),
            end: Vec2(20, 3),
            size: Vec2(3, 0.5),
            speed: 2,
            pause: 1,
          ),
        ],
      );
      expect(ferry.routeTop(15), 3);
    });

    test('counts only steps between consecutive runs, not shortcuts', () {
      // Down a descent: a top run, a tread, then the bottom run.
      final descent = route(
        floors: const [
          FloorRun(position: Vec2(0, 0), size: Vec2(10, tileSize)),
          FloorRun(position: Vec2(12, 4), size: Vec2(2, tileSize)),
          FloorRun(position: Vec2(16, 8), size: Vec2(14, tileSize)),
        ],
      );
      // Over the bottom run, the step from the tread counts, but not a leap
      // from the top run, which would be a shortcut.
      expect(descent.routeTop(20), 4);
      expect(descent.routeTop(13), 0);
    });

    test('counts a roll off a ledge over the runs below', () {
      // A ledge, a short tread a drop lower, then the bottom run.
      final drops = route(
        floors: const [
          FloorRun(position: Vec2(0, 0), size: Vec2(10, tileSize)),
          FloorRun(position: Vec2(10, 5), size: Vec2(2, tileSize)),
          FloorRun(position: Vec2(12, 10), size: Vec2(30, tileSize)),
        ],
      );
      // Rolling off the top ledge at speed passes over the tread and part
      // of the bottom run at up to the ledge's height, without a jump.
      expect(drops.rollOffTop(14), 0);
      expect(drops.rollOffTop(5), isNull);
      expect(drops.rollOffTop(40), isNull);
      expect(drops.lowestEnd(14), 0 - laserMargin);
      // Far along the bottom run only its own route counts.
      expect(drops.lowestEnd(40), 10 - testEnvelope.jumpHeight - laserMargin);
    });

    test('allows no barrier where a gravity boost serves', () {
      final clearance = route(
        boosts: const [Boost(position: Vec2(12, 3.4), type: BoostType.gravity)],
      );
      expect(clearance.clearance(15), isNull);
      expect(clearance.lowestEnd(15), isNull);
    });
  });

  group('LaserClearance with the new physics', () {
    test("counts a hill's crest, and the flight off it", () {
      final hill = CurvedRun.bumps(
        kind: CurveKind.hill,
        left: 10,
        ground: 4,
        bumps: const [(8, 2)],
      );
      final clearance = route(curves: [hill]);
      expect(clearance.routeTop(14), closeTo(2, 1e-9));
      // A ball flying off the crest passes past the hill's end.
      expect(clearance.routeTop(19.5), closeTo(2, 1e-9));
      expect(clearance.routeTop(28), 4);
      final pipe = CurvedRun.bumps(
        kind: CurveKind.halfPipe,
        left: 10,
        ground: 4,
        bumps: const [(8, -2)],
      );
      expect(route(curves: [pipe]).routeTop(14), 4);
    });

    test('rises above a launch off a slope up, not off a slope down', () {
      final up = CurvedRun.slope(left: 10, from: 4, to: 2, width: 4.4);
      expect(route(curves: [up]).clearance(12), rampClearance);
      final down = CurvedRun.slope(left: 10, from: 4, to: 6, width: 4.4);
      expect(route(curves: [down]).clearance(12), testEnvelope.jumpHeight);
    });

    test('rises above a trampoline bounce, and none goes near a loop', () {
      const pad = Trampoline(position: Vec2(5, 4), width: 1.5);
      final bounced = route(trampolines: const [pad]);
      expect(bounced.clearance(10), testEnvelope.trampolineHeight);
      expect(route().clearance(10), testEnvelope.jumpHeight);
      const loop = Loop(foot: Vec2(20, 4), radius: 2.5);
      final looped = route(loops: const [loop]);
      expect(looped.clearance(30), isNull);
      expect(looped.lowestEnd(30), isNull);
      expect(looped.clearance(20 + 2.5 + loopClearance + 1), isNotNull);
    });

    test('a trampoline extends the step from its run to the next', () {
      const near = FloorRun(position: Vec2(0, 4), size: Vec2(6, tileSize));
      const far = FloorRun(position: Vec2(40, 4), size: Vec2(6, tileSize));
      final plain = route(floors: const [near, far]);
      final bounced = route(
        floors: const [near, far],
        trampolines: const [Trampoline(position: Vec2(4.5, 4), width: 1.5)],
      );
      expect(plain.routeTop(25), isNull);
      expect(bounced.routeTop(25), 4);
    });
  });

  group('LaserClearance in adrenaline zones', () {
    test('count the rush: steps and roll-offs reach farther', () {
      const near = FloorRun(position: Vec2(0, 4), size: Vec2(6, tileSize));
      const far = FloorRun(position: Vec2(40, 4), size: Vec2(6, tileSize));
      // Plain, a step from the near run reaches about 13 m.
      final plain = route(floors: const [near, far]);
      final rushed = route(
        floors: const [near, far],
        adrenaline: const [AdrenalineZone(left: 0, right: 46)],
      );
      final x =
          6 +
          rollOffSpeed * testEnvelope.topSpeed * testEnvelope.flightTime +
          2 * routeSlack +
          0.5;
      expect(plain.routeTop(x), isNull);
      expect(rushed.routeTop(x), 4);
      const ledge = FloorRun(position: Vec2(0, 4), size: Vec2(6, tileSize));
      const low = FloorRun(position: Vec2(6, 9), size: Vec2(40, tileSize));
      final rolled = route(
        floors: const [ledge, low],
        adrenaline: const [AdrenalineZone(left: 0, right: 46)],
      );
      final calm = route(floors: const [ledge, low]);
      final reach =
          rollOffSpeed * testEnvelope.topSpeed * testEnvelope.fallTime(5) +
          routeSlack +
          6;
      expect(calm.rollOffTop(reach + 0.5), isNull);
      expect(rolled.rollOffTop(reach + 0.5), 4);
    });
  });

  group('LaserClearance near the dynamic elements', () {
    test('allows no barrier near a fan, a mace or a seesaw', () {
      LaserClearance near({
        List<Fan> fans = const [],
        List<Pendulum> pendulums = const [],
        List<Seesaw> seesaws = const [],
      }) => LaserClearance(
        envelope: testEnvelope,
        floors: const [
          FloorRun(position: Vec2(0, 4), size: Vec2(200, tileSize)),
        ],
        ramps: const [],
        platforms: const [],
        boosts: const [],
        fans: fans,
        pendulums: pendulums,
        seesaws: seesaws,
      );
      final fan = near(
        fans: const [Fan(left: 50, right: 60, base: 7, top: -5)],
      );
      expect(fan.clearance(75), isNull);
      expect(fan.clearance(60 + loopClearance + 1), isNotNull);
      const pendulum = Pendulum(
        pivot: Vec2(50, 0),
        length: 3,
        period: 4,
        clear: 0.25,
        phase: 0,
      );
      final mace = near(pendulums: const [pendulum]);
      expect(mace.clearance(50 + 3 + maceRadius + dynamicClearance), isNull);
      expect(mace.clearance(50 + 3.5 + dynamicClearance + 1), isNotNull);
      const seesaw = Seesaw(
        pivot: Vec2(50, 3),
        halfLength: 2,
        rest: 0.28,
        tip: 0.66,
      );
      final plank = near(seesaws: const [seesaw]);
      expect(plank.clearance(seesaw.right + dynamicClearance), isNull);
      expect(plank.clearance(seesaw.right + dynamicClearance + 1), isNotNull);
    });
  });
}
