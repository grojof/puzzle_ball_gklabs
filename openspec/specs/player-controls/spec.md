# player-controls Specification

## Purpose
Defines how the player moves and jumps the ball with tilt, the on-screen joystick and jump button, or the keyboard, and
which inputs are active in each control mode.

## Requirements

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

### Requirement: Joystick and keyboard movement
In joystick mode, moving the joystick knob or holding `A` or `D` SHALL push the ball left or right at full strength.
Movement is horizontal only.

#### Scenario: Keyboard
- **WHEN** the player holds `D`
- **THEN** the ball is pushed to the right until the key is released

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

### Requirement: Vibration feedback
On Android, when vibration is enabled in the settings, the device SHALL vibrate when something happens to the ball,
with a different feel for each event:
- a short light pulse when the ball actually jumps;
- a strong pulse when a boost starts;
- a double pulse when a checkpoint activates;
- a heartbeat, two soft pulses, when an adrenaline rush starts;
- a sharp pulse when a bumper or a mace hits the ball.

A jump request that does not make the ball jump SHALL NOT vibrate.

#### Scenario: Jump with vibration enabled
- **WHEN** vibration is enabled and the ball jumps from the ground
- **THEN** the device gives a short light pulse

#### Scenario: Press in mid-air
- **WHEN** the player presses the jump button while the ball is in mid-air and cannot jump
- **THEN** the device does not vibrate

#### Scenario: Boost and checkpoint
- **WHEN** vibration is enabled and the ball takes a boost, then activates a checkpoint
- **THEN** the device gives a strong pulse for the boost and a double pulse for the checkpoint

#### Scenario: Adrenaline rush
- **WHEN** vibration is enabled and the ball enters an adrenaline zone
- **THEN** the device gives a heartbeat

#### Scenario: A hit
- **WHEN** vibration is enabled and a bumper or a mace hits the ball
- **THEN** the device gives a sharp pulse

#### Scenario: Vibration disabled
- **WHEN** vibration is disabled and the ball jumps, takes a boost, activates a checkpoint, starts a rush or is hit
- **THEN** the device does not vibrate

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

### Requirement: A ball with weight
The ball SHALL fall about a fifth faster than before, so it leaves slopes and crests less and lands sooner. Its jump,
a jump boost's launch and a trampoline's bounce SHALL still reach the heights they reached before.

#### Scenario: Same jump, quicker fall
- **WHEN** the ball jumps from the ground
- **THEN** it rises about as high as before, about 2.7 m, and is back on the ground sooner than before

#### Scenario: Over a crest
- **WHEN** the ball rolls fast over a hill's crest
- **THEN** it stays on the ground at speeds at which it used to take off
