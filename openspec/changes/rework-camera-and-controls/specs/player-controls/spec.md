# Spec Delta

## MODIFIED Requirements

### Requirement: Proportional tilt
In tilt mode, the push on the ball SHALL grow with the tilt angle, reaching full strength at about 30°, and tilts
smaller than a dead zone of a few degrees SHALL not move the ball. The tilt SHALL be measured relative to the screen
as the player holds it: in portrait and in either landscape orientation, tilting the device like a steering wheel
towards the right of the screen pushes the ball right.

#### Scenario: Device held almost flat
- **WHEN** the device is tilted by less than the dead zone
- **THEN** the ball is not pushed

#### Scenario: Gentle tilt
- **WHEN** the device is tilted by about half of the full-strength angle
- **THEN** the ball is pushed at about half strength in the tilt direction

#### Scenario: Landscape tilt
- **WHEN** the player holds the phone in landscape, with either side up, and tilts it towards the right of the screen
- **THEN** the ball is pushed to the right

## ADDED Requirements

### Requirement: Vibration feedback
On Android, when vibration is enabled in the settings, the device SHALL vibrate when something happens to the ball,
with a different feel for each event: a short light pulse when the ball actually jumps, a strong pulse when a boost
starts, and a double pulse when a checkpoint activates. A jump request that does not make the ball jump SHALL NOT
vibrate.

#### Scenario: Jump with vibration enabled
- **WHEN** vibration is enabled and the ball jumps from the ground
- **THEN** the device gives a short light pulse

#### Scenario: Press in mid-air
- **WHEN** the player presses the jump button while the ball is in mid-air and cannot jump
- **THEN** the device does not vibrate

#### Scenario: Boost and checkpoint
- **WHEN** vibration is enabled and the ball takes a boost, then activates a checkpoint
- **THEN** the device gives a strong pulse for the boost and a double pulse for the checkpoint

#### Scenario: Vibration disabled
- **WHEN** vibration is disabled and the ball jumps, takes a boost or activates a checkpoint
- **THEN** the device does not vibrate

### Requirement: On-screen controls fit the thumb
In joystick mode, the joystick SHALL sit in the bottom-left corner and the jump button in the bottom-right corner,
mirroring each other. Each SHALL be at least 72 logical pixels across, growing with the screen's shorter side, with a
margin from the screen edges. The jump button SHALL show an up-arrow icon and a visible pressed state.

#### Scenario: Landscape phone
- **WHEN** the game runs on a landscape phone screen in joystick mode
- **THEN** the joystick and the jump button sit in the bottom corners, each at least 72 logical pixels across, and the
  jump button shows an up arrow

#### Scenario: Pressing the jump button
- **WHEN** the player presses the jump button
- **THEN** the ball jumps if it can, and the button shows that it is pressed until released
