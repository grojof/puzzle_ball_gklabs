# Spec Delta

## Purpose

Defines how the player moves and jumps the ball with tilt, the on-screen joystick and jump button, or the keyboard, and
which inputs are active in each control mode.

## ADDED Requirements

### Requirement: One active movement input
Movement SHALL come from tilt in tilt mode, and from the on-screen joystick or the keyboard in joystick mode. The
device's motion sensor SHALL only be read while tilt mode is selected and a level is running.

#### Scenario: Joystick mode ignores tilt
- **WHEN** the control mode is joystick and the player tilts the device
- **THEN** the ball does not move, and the motion sensor is not being read

#### Scenario: Switching modes during a session
- **WHEN** the player switches from joystick to tilt in the settings opened from the pause menu
- **THEN** on resuming, tilt moves the ball and the joystick no longer does

#### Scenario: Web has no tilt
- **WHEN** the game runs in a browser
- **THEN** joystick and keyboard control are available, and tilt mode is not offered

### Requirement: Proportional tilt
In tilt mode, the push on the ball SHALL grow with the tilt angle, reaching full strength at about 30°, and tilts
smaller than a dead zone of a few degrees SHALL not move the ball.

#### Scenario: Device held almost flat
- **WHEN** the device is tilted by less than the dead zone
- **THEN** the ball is not pushed

#### Scenario: Gentle tilt
- **WHEN** the device is tilted by about half of the full-strength angle
- **THEN** the ball is pushed at about half strength in the tilt direction

### Requirement: Joystick and keyboard movement
In joystick mode, moving the joystick knob or holding `A` or `D` SHALL push the ball left or right at full strength.
Movement is horizontal only.

#### Scenario: Keyboard
- **WHEN** the player holds `D`
- **THEN** the ball is pushed to the right until the key is released

### Requirement: Jump
The jump button, the `Space` key, and in tilt mode a sharp shake of the device SHALL make the ball jump when it is
touching the ground or left it less than 150 ms ago. A jump SHALL NOT be possible in mid-air outside that window.

#### Scenario: Jump from the ground
- **WHEN** the ball rests on the ground and the player presses the jump button
- **THEN** the ball jumps and the jump sound plays

#### Scenario: No double jump
- **WHEN** the ball is in mid-air for more than 150 ms and the player presses jump
- **THEN** nothing happens
