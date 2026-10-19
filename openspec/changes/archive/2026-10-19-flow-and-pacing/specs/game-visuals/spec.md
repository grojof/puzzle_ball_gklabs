# Spec Delta

## ADDED Requirements

### Requirement: Readable adrenaline rush
An adrenaline zone SHALL be visible before the ball enters it, marked on the ground with a red tint. During a rush, the
screen's edges SHALL glow red and pulse like a heartbeat, and the ball SHALL leave a short red trail. The glow SHALL
fade within half a second of leaving the zone. None of it SHALL hide the course or the HUD.

#### Scenario: Entering a rush
- **WHEN** the ball enters an adrenaline zone
- **THEN** the screen's edges glow red and pulse, and the ball leaves a red trail, while the course stays clear

#### Scenario: Leaving a rush
- **WHEN** the ball leaves the zone
- **THEN** the glow and the trail fade within half a second
