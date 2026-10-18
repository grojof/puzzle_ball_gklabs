import 'package:level_generator/level_generator.dart';

/// The game's envelope, measured with real Box2D (design D3).
const testEnvelope = MovementEnvelope(
  jumpHeight: 3.6,
  flightTime: 1.65,
  topSpeed: 7.8,
  timeToTopSpeed: 2.4,
  jumpBoostHeight: 6.4,
  speedBoostJumpDistance: 23,
  gravityBoostJumpDistance: 29,
);
