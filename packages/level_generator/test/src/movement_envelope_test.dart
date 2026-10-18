import 'package:test/test.dart';

import '../helpers/envelope.dart';

void main() {
  group('MovementEnvelope', () {
    test('reproduces the measured running jump within tolerance', () {
      // Measured: 13.03 m at 8.54 m/s, 2.75 m high, about 1.55 s of air.
      expect(
        testEnvelope.maxGap(speed: 8.54, rise: 0, margin: 1),
        closeTo(13.03, 0.4),
      );
    });

    test('speed follows the measured curve from rest', () {
      expect(testEnvelope.speedAfter(0), 0);
      expect(testEnvelope.speedAfter(0.75), 3.03);
      // Halfway between two samples.
      expect(testEnvelope.speedAfter(1.125), closeTo((3.03 + 4.06) / 2, 1e-12));
      expect(testEnvelope.speedAfter(30), 8.27);
      // Past the curve the speed stays at its last value.
      expect(testEnvelope.speedAfter(100), 8.27);
    });

    test('a start speed continues along the curve', () {
      // 4.06 m/s is reached after 1.5 m; 0.75 m more gives the next sample.
      expect(
        testEnvelope.speedAfter(0.75, startSpeed: 4.06),
        closeTo(4.71, 1e-12),
      );
      expect(
        testEnvelope.speedAfter(2, startSpeed: 3),
        greaterThan(testEnvelope.speedAfter(2)),
      );
      // Faster than the curve ever gets: it continues at its end.
      expect(testEnvelope.speedAfter(1, startSpeed: 20), 8.27);
      // A start speed of zero or less starts from rest.
      expect(
        testEnvelope.speedAfter(1, startSpeed: -1),
        testEnvelope.speedAfter(1),
      );
    });

    test('air time is longer for lower landings and null out of reach', () {
      final level = testEnvelope.airTime(0)!;
      expect(level, closeTo(testEnvelope.flightTime, 1e-9));
      expect(testEnvelope.airTime(-3), greaterThan(level));
      expect(testEnvelope.airTime(2), lessThan(level));
      expect(testEnvelope.airTime(10), isNull);
    });

    test('falling from the jump height takes half a jump', () {
      expect(
        testEnvelope.fallTime(testEnvelope.jumpHeight),
        closeTo(testEnvelope.flightTime / 2, 1e-9),
      );
      expect(testEnvelope.fallTime(0), 0);
    });

    test('gaps scale with speed and margin, and need a reachable landing', () {
      final slow = testEnvelope.maxGap(speed: 3, rise: 0, margin: 0.5);
      final fast = testEnvelope.maxGap(speed: 7, rise: 0, margin: 0.5);
      expect(fast, greaterThan(slow));
      expect(
        testEnvelope.maxGap(speed: 7, rise: 0, margin: 0.8),
        greaterThan(fast),
      );
      expect(testEnvelope.maxGap(speed: 7, rise: 3, margin: 0.5), 0);
    });

    test('climbs and boosted limits follow the margin', () {
      expect(testEnvelope.maxClimb(0.5), 1.325);
      expect(testEnvelope.maxBoostedClimb(0.5), 3.2);
      expect(testEnvelope.maxSpeedBoostGap(speed: 8.3, margin: 0.5), 10.75);
      expect(
        testEnvelope.maxSpeedBoostGap(speed: 0, margin: 0.5),
        closeTo(10.75 * 15.5 / 23.8, 1e-9),
      );
      expect(testEnvelope.maxSpeedBoostGap(speed: 20, margin: 0.5), 10.75);
      expect(testEnvelope.maxGravityBoostGap(speed: 8.3, margin: 0.5), 14);
      expect(testEnvelope.maxGravityBoostGap(speed: 4.15, margin: 0.5), 7);
      expect(testEnvelope.maxDoubleJumpClimb(0.5), 2.65);
      expect(testEnvelope.maxDoubleJumpGap(speed: 8.3, margin: 0.5), 11);
      expect(testEnvelope.maxDoubleJumpGap(speed: 4.15, margin: 0.5), 5.5);
    });
  });
}
