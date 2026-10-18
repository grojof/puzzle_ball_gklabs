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
  }) => LaserClearance(
    envelope: testEnvelope,
    floors: floors,
    ramps: ramps,
    platforms: platforms,
    boosts: boosts,
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
}
