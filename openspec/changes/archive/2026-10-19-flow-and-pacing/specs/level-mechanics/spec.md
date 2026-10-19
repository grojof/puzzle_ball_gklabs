# Spec Delta

## ADDED Requirements

### Requirement: Adrenaline rush
While the ball is inside an adrenaline zone, its push SHALL be 25 % stronger: it speeds up faster and reaches a higher
top speed, with the same jump. Leaving the zone, or a respawn, SHALL end the rush at once.

#### Scenario: Entering a zone
- **WHEN** the player keeps pushing into an adrenaline zone
- **THEN** the ball speeds up beyond its usual top speed

#### Scenario: Leaving a zone
- **WHEN** the ball leaves the zone
- **THEN** its push returns to normal and it slows back to its usual top speed
