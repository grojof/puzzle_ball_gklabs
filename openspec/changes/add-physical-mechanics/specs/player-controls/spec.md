# Spec Delta

## MODIFIED Requirements

### Requirement: Jump
The jump button, the `Space` key, and in tilt mode a quick flick of the device towards the player SHALL make the ball
jump when it is touching the ground or left it less than 150 ms ago. A jump SHALL NOT be possible in mid-air outside
that window, unless a double-jump orb's charge is held. Touching the ground means resting on the top of a floor or a
ramp: touching the side of a ledge or a wall SHALL NOT allow a jump. One flick SHALL request one jump; tilting to
steer SHALL NOT request a jump.

#### Scenario: Jump from the ground
- **WHEN** the ball rests on the ground and the player presses the jump button
- **THEN** the ball jumps and the jump sound plays

#### Scenario: No double jump
- **WHEN** the ball is in mid-air for more than 150 ms, holds no orb charge, and the player presses jump
- **THEN** nothing happens

#### Scenario: Air jump with an orb charge
- **WHEN** the ball holds an orb charge and the player presses jump in mid-air
- **THEN** the ball jumps again and the charge is spent

#### Scenario: No wall jump
- **WHEN** the ball in mid-air touches the side of a ledge and the player presses jump
- **THEN** nothing happens

#### Scenario: Gentle flick in tilt mode
- **WHEN** in tilt mode the player gives the phone a short, gentle flick towards themselves
- **THEN** the ball jumps once

#### Scenario: Steering is not a jump
- **WHEN** in tilt mode the player tilts the phone to steer, even quickly
- **THEN** no jump is requested

### Requirement: On-screen controls fit the thumb
In joystick mode, the joystick SHALL sit in the bottom-left corner and the jump button in the bottom-right corner,
mirroring each other. Each SHALL be at least 72 logical pixels across, growing with the screen's shorter side, with a
margin from the screen edges. Both SHALL be drawn in the game's visual style, with depth. The jump button SHALL show
an up-arrow icon and a visible pressed state, and SHALL show a distinct indicator while a double-jump orb's charge is
held.

#### Scenario: Landscape phone
- **WHEN** the game runs on a landscape phone screen in joystick mode
- **THEN** the joystick and the jump button sit in the bottom corners, each at least 72 logical pixels across, and the
  jump button shows an up arrow

#### Scenario: Pressing the jump button
- **WHEN** the player presses the jump button
- **THEN** the ball jumps if it can, and the button shows that it is pressed until released

#### Scenario: Orb charge held
- **WHEN** the ball collects a double-jump orb
- **THEN** the jump button shows the charged indicator until the charge is spent or lost
