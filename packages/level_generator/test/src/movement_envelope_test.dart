import 'package:level_generator/level_generator.dart';
import 'package:test/test.dart';

import '../helpers/envelope.dart';

void main() {
  group('MovementEnvelope', () {
    test('reproduces the measured running jump within tolerance', () {
      // Measured: 11.77 m at 8.48 m/s, 2.69 m high, about 1.39 s of air.
      expect(
        testEnvelope.maxGap(speed: 8.48, rise: 0, margin: 1),
        closeTo(11.77, 0.4),
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
      expect(testEnvelope.maxSpeedBoostGap(speed: 8.3, margin: 0.5), 10);
      expect(
        testEnvelope.maxSpeedBoostGap(speed: 0, margin: 0.5),
        closeTo(10 * 15.5 / 23.8, 1e-9),
      );
      expect(testEnvelope.maxSpeedBoostGap(speed: 20, margin: 0.5), 10);
      expect(testEnvelope.maxGravityBoostGap(speed: 8.3, margin: 0.5), 13.75);
      expect(testEnvelope.maxGravityBoostGap(speed: 4.15, margin: 0.5), 6.875);
      expect(testEnvelope.maxDoubleJumpClimb(0.5), 2.65);
      expect(testEnvelope.maxDoubleJumpGap(speed: 8.3, margin: 0.5), 10);
      expect(testEnvelope.maxDoubleJumpGap(speed: 4.15, margin: 0.5), 5);
    });
  });

  group('MovementEnvelope on the new physics', () {
    const envelope = testEnvelope;

    test('each surface has its own speed curve', () {
      final plain = envelope.speedAfter(6);
      expect(envelope.speedOn(FloorSurface.plain, 6), plain);
      expect(envelope.speedOn(FloorSurface.conveyorForward, 6), plain);
      expect(
        envelope.speedOn(FloorSurface.ice, 6),
        envelope.speedAfter(6 * envelope.iceGrip),
      );
      expect(envelope.speedOn(FloorSurface.mud, 60), envelope.mudTopSpeed);
      expect(
        envelope.speedOn(FloorSurface.conveyorBackward, 60),
        closeTo(envelope.speedCurve.last - envelope.beltSpeed, 1e-9),
      );
      expect(envelope.speedOn(FloorSurface.conveyorBackward, 0), 0);
    });

    test('a rush scales the speed curve', () {
      expect(envelope.rushSpeedAfter(0), 0);
      expect(
        envelope.rushSpeedAfter(10),
        closeTo(
          envelope.rushGain * envelope.speedAfter(10 / envelope.rushGain),
          1e-12,
        ),
      );
      expect(
        envelope.rushSpeedAfter(500, startSpeed: 2),
        closeTo(envelope.rushGain * envelope.speedCurve.last, 1e-9),
      );
    });

    test('mud weakens the jump', () {
      expect(
        envelope.maxClimb(1, surface: FloorSurface.mud),
        envelope.mudJumpHeight,
      );
      expect(envelope.mudAirTime(0), closeTo(envelope.mudFlightTime, 1e-9));
      expect(
        envelope.maxGap(
          speed: 3,
          rise: 0,
          margin: 1,
          surface: FloorSurface.mud,
        ),
        closeTo(3 * envelope.mudFlightTime, 1e-9),
      );
      // Beyond the mud jump, nothing is reachable.
      expect(
        envelope.maxGap(
          speed: 3,
          rise: 2,
          margin: 1,
          surface: FloorSurface.mud,
        ),
        0,
      );
      // A margin past 1 lets the climb check pass a landing the arc misses.
      expect(
        envelope.maxGap(
          speed: 3,
          rise: 1.9,
          margin: 1.2,
          surface: FloorSurface.mud,
        ),
        0,
      );
    });

    test('a trampoline throws to its height and as far as speed or push '
        'carries', () {
      expect(envelope.maxTrampolineClimb(0.5), envelope.trampolineHeight / 2);
      expect(
        envelope.trampolineAirTime(0),
        closeTo(envelope.trampolineFlightTime, 1e-9),
      );
      // At rest, the push in the air carries it.
      expect(
        envelope.maxTrampolineGap(speed: 0, rise: 0, margin: 1),
        closeTo(envelope.trampolineDistance, 1e-9),
      );
      // Landing higher shortens the air time, and the push's distance by
      // its square; landing lower lengthens both in proportion.
      final higher = envelope.trampolineAirTime(2)!;
      expect(
        envelope.maxTrampolineGap(speed: 0, rise: 2, margin: 1),
        closeTo(
          envelope.trampolineDistance *
              (higher / envelope.trampolineFlightTime) *
              (higher / envelope.trampolineFlightTime),
          1e-9,
        ),
      );
      final lower = envelope.trampolineAirTime(-2)!;
      expect(
        envelope.maxTrampolineGap(speed: 0, rise: -2, margin: 1),
        closeTo(
          envelope.trampolineDistance * lower / envelope.trampolineFlightTime,
          1e-9,
        ),
      );
      // Fast enough, the carried speed reaches farther.
      expect(
        envelope.maxTrampolineGap(speed: 8, rise: 0, margin: 1),
        closeTo(8 * envelope.trampolineFlightTime, 1e-9),
      );
      expect(envelope.maxTrampolineGap(speed: 8, rise: 6, margin: 1), 0);
      expect(envelope.maxTrampolineGap(speed: 8, rise: 5, margin: 1.2), 0);
    });
  });
}
