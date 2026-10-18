import 'package:level_generator/level_generator.dart';

/// What the ball can do with the physics of `BallComponent` and the boosts.
///
/// Measured with real Box2D and rounded down: 3.72 m jump, 1.71 s of air,
/// 7.94 m/s top speed, 6.69 m jump-boost height, 24.5 m speed-boost jump and
/// 31 m gravity-boost jump. `test/game/movement_envelope_test.dart` fails if
/// the physics stops reaching these numbers (level-generation spec).
const ballEnvelope = MovementEnvelope(
  jumpHeight: 3.6,
  flightTime: 1.65,
  topSpeed: 7.8,
  timeToTopSpeed: 2.4,
  jumpBoostHeight: 6.4,
  speedBoostJumpDistance: 23,
  gravityBoostJumpDistance: 29,
);

/// Generates the game's levels within [ballEnvelope].
const levelGenerator = LevelGenerator(envelope: ballEnvelope);
