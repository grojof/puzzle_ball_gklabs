import 'package:level_generator/level_generator.dart';

/// What the ball can do with the physics of `BallComponent` and the boosts.
///
/// Measured with real Box2D and rounded down: 2.75 m jump, 1.55 s of air,
/// 8.54 m/s top speed and the speed curve from rest (cut by 2 %), 6.69 m
/// jump-boost height, 22.2 m speed-boost jump (the boost adds 15.9 m/s),
/// 29.3 m gravity-boost jump, and with an air jump at the apex 5.5 m high
/// and 22.9 m at a run.
/// `test/game/movement_envelope_test.dart` fails if the physics stops reaching
/// these numbers (level-generation spec).
const ballEnvelope = MovementEnvelope(
  jumpHeight: 2.65,
  flightTime: 1.5,
  topSpeed: 8.3,
  speedCurve: [
    3.03, 4.06, 4.71, 5.21, 5.60, 5.93, 6.19, 6.43, 6.64, 6.80, //
    6.97, 7.10, 7.22, 7.32, 7.42, 7.51, 7.59, 7.66, 7.73, 7.78, //
    7.83, 7.88, 7.92, 7.96, 7.99, 8.03, 8.05, 8.08, 8.10, 8.13, //
    8.15, 8.16, 8.18, 8.20, 8.21, 8.23, 8.24, 8.25, 8.26, 8.27, //
  ],
  jumpBoostHeight: 6.4,
  speedBoostJumpDistance: 21.5,
  speedBoostGain: 15.5,
  gravityBoostJumpDistance: 28,
  doubleJumpHeight: 5.3,
  doubleJumpDistance: 22,
);

/// Generates the game's levels within [ballEnvelope].
const levelGenerator = LevelGenerator(envelope: ballEnvelope);
