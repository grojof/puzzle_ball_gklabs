# Spec Delta

## ADDED Requirements

### Requirement: Laser barriers
A laser barrier SHALL be a vertical beam hanging in the air that switches on and off on a fixed rhythm, with a short
warning before it switches on. Touching it while it is on SHALL send the ball back as after a fall; while it is off,
the ball SHALL pass through. A respawn SHALL NOT change its rhythm.

#### Scenario: Flying into a lit barrier
- **WHEN** the ball touches a laser barrier while it is on
- **THEN** the ball is sent back to the last active checkpoint, or the level restarts with none

#### Scenario: Timing the gap
- **WHEN** the ball crosses a laser barrier while it is off
- **THEN** nothing happens to the ball
