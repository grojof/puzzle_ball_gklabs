# Spec Delta

## MODIFIED Requirements

### Requirement: Jump
The jump button, the `Space` key, and in tilt mode a sharp shake of the device SHALL make the ball jump when it is
touching the ground or left it less than 150 ms ago. A jump SHALL NOT be possible in mid-air outside that window.
Touching the ground means resting on the top of a floor or a ramp: touching the side of a ledge or a wall SHALL NOT
allow a jump.

#### Scenario: Jump from the ground
- **WHEN** the ball rests on the ground and the player presses the jump button
- **THEN** the ball jumps and the jump sound plays

#### Scenario: No double jump
- **WHEN** the ball is in mid-air for more than 150 ms and the player presses jump
- **THEN** nothing happens

#### Scenario: No wall jump
- **WHEN** the ball in mid-air touches the side of a ledge and the player presses jump
- **THEN** nothing happens
