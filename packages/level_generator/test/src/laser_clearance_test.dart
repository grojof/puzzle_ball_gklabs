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
      expect(clearance.highestGround(15), 4);
      expect(clearance.highestGround(25), 1);
      expect(clearance.clearance(15), testEnvelope.jumpHeight);
      expect(
        clearance.lowestEnd(15),
        4 - testEnvelope.jumpHeight - laserMargin,
      );
      expect(route(floors: const []).highestGround(5), isNull);
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
        ).highestGround(15),
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
      expect(ferry.highestGround(15), 3);
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
