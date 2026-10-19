import 'package:level_generator/level_generator.dart';

/// What the ball can do with the physics of `BallComponent` and the boosts,
/// under the world's gravity of 12 m/s².
///
/// Measured with real Box2D and rounded down:
/// - a 2.69 m jump carrying 11.8 m at 8.48 m/s top speed, and the speed curve
///   from rest (cut by 2 %);
/// - a 6.64 m jump-boost height, a 20.5 m speed-boost jump (the boost adds
///   15.9 m/s), a 28.1 m gravity-boost jump, and with an air jump at the
///   apex 5.38 m high and 20.6 m at a run;
/// - 3.93 m/s or more leaving any hill, half-pipe or rounded slope pushed
///   from rest;
/// - a trampoline throwing it 5.2 m up, 16.8 m along at top speed and 13.7 m
///   from rest pushing;
/// - a belt carrying it at 2.44 m/s; on ice about a third of the ground to
///   reach a speed; on mud 3.45 m/s at most and a 1.74 m jump;
/// - a 1.75 m loop taking 11.5 m/s.
///
/// `test/game/movement_envelope_test.dart` fails if the physics stops reaching
/// these numbers (level-generation spec).
const ballEnvelope = MovementEnvelope(
  jumpHeight: 2.65,
  flightTime: 1.4,
  topSpeed: 8.3,
  speedCurve: [
    3.03, 4.06, 4.71, 5.21, 5.60, 5.93, 6.19, 6.43, 6.64, 6.80, //
    6.97, 7.10, 7.22, 7.32, 7.42, 7.51, 7.59, 7.66, 7.73, 7.78, //
    7.83, 7.88, 7.92, 7.96, 7.99, 8.03, 8.05, 8.08, 8.10, 8.13, //
    8.15, 8.16, 8.18, 8.20, 8.21, 8.23, 8.24, 8.25, 8.26, 8.27, //
  ],
  jumpBoostHeight: 6.4,
  speedBoostJumpDistance: 20,
  speedBoostGain: 15.5,
  gravityBoostJumpDistance: 27.5,
  doubleJumpHeight: 5.3,
  doubleJumpDistance: 20,
  curveExitSpeed: 3.8,
  trampolineHeight: 4.8,
  trampolineFlightTime: 1.95,
  trampolineDistance: 13.5,
  beltSpeed: 2.5,
  iceGrip: 0.33,
  mudTopSpeed: 3.3,
  mudJumpHeight: 1.7,
  mudFlightTime: 1.1,
  loopEntrySpeed: 12,
  rushGain: 1.24,
);

/// Generates the game's levels within [ballEnvelope].
const levelGenerator = LevelGenerator(envelope: ballEnvelope);
