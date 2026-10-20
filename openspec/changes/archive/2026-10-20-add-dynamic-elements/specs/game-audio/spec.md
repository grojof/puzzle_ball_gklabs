# Spec Delta

## MODIFIED Requirements

### Requirement: Effects play reliably and evenly
Every game event with a sound (jump, jump boost, speed boost, gravity boost, the start of an adrenaline rush, a bumper
throwing the ball, a mace hitting it, the ball entering a fan's column) SHALL play it each time it happens, with no
audible delay, and all effects SHALL sound at a comparable loudness at the same effects volume.

#### Scenario: Rapid repeated jumps
- **WHEN** the ball jumps many times in quick succession
- **THEN** each jump plays its sound, and the number of audio players in use does not grow with the number of jumps

#### Scenario: Consistent loudness
- **WHEN** the jump sound, each boost sound, the heartbeat and the bumper, mace and updraft sounds play at the same
  effects volume
- **THEN** none is noticeably quieter or louder than the others

#### Scenario: A rush starts
- **WHEN** the ball enters an adrenaline zone with sound on
- **THEN** a heartbeat plays

#### Scenario: A bumper
- **WHEN** a bumper throws the ball with sound on
- **THEN** a bright ding plays
