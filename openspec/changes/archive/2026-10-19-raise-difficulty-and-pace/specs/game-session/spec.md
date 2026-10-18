# Spec Delta

## ADDED Requirements

### Requirement: Prompt fall detection
A fall SHALL be detected as soon as no ground is left below the ball that it could still reach, given how fast it can
fall and travel sideways, and SHALL NOT be detected while such a landing is still possible. So long jumps and drops
onto real ground stay possible, and a hopeless fall does not leave the player waiting.

#### Scenario: A long drop onto distant ground
- **WHEN** the ball jumps off a high platform towards ground 15 m lower and 12 m ahead
- **THEN** no fall is detected, and the ball can land there

#### Scenario: A hopeless fall from high up
- **WHEN** the ball drops into a pit 40 m above the level's lowest ground, with no ground it could reach below
- **THEN** the fall is detected within about a second, not after the ball has fallen to the level's lowest point
