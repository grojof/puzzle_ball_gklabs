import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

import '../helpers/envelope.dart';

void main() {
  group('MovementEnvelope', () {
    test('reproduces the measured running jump within tolerance', () {
      // Measured: 13.55 m at 7.94 m/s, 3.72 m high, about 1.71 s of air.
      const measured = MovementEnvelope(
        jumpHeight: 3.72,
        flightTime: 1.706,
        topSpeed: 7.94,
        timeToTopSpeed: 2.4,
        jumpBoostHeight: 6.69,
        speedBoostJumpDistance: 24.5,
        gravityBoostJumpDistance: 31,
      );
      expect(
        measured.maxGap(speed: 7.94, rise: 0, margin: 1),
        closeTo(13.55, 0.1),
      );
    });

    test('speed grows with the run-up and caps at top speed', () {
      expect(testEnvelope.acceleration, closeTo(3.25, 0.01));
      expect(testEnvelope.speedAfter(0), 0);
      expect(testEnvelope.speedAfter(2), lessThan(testEnvelope.topSpeed));
      expect(testEnvelope.speedAfter(100), testEnvelope.topSpeed);
      expect(
        testEnvelope.speedAfter(2, startSpeed: 3),
        greaterThan(testEnvelope.speedAfter(2)),
      );
    });

    test('air time is longer for lower landings and null out of reach', () {
      final level = testEnvelope.airTime(0)!;
      expect(level, closeTo(testEnvelope.flightTime, 1e-9));
      expect(testEnvelope.airTime(-3), greaterThan(level));
      expect(testEnvelope.airTime(2), lessThan(level));
      expect(testEnvelope.airTime(10), isNull);
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
      expect(testEnvelope.maxClimb(0.5), 1.8);
      expect(testEnvelope.maxBoostedClimb(0.5), 3.2);
      expect(testEnvelope.maxSpeedBoostGap(0.5), 11.5);
      expect(testEnvelope.maxGravityBoostGap(speed: 7.8, margin: 0.5), 14.5);
      expect(testEnvelope.maxGravityBoostGap(speed: 3.9, margin: 0.5), 7.25);
    });
  });
}
