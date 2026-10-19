# Spec Delta

## MODIFIED Requirements

### Requirement: Vibration feedback
On Android, when vibration is enabled in the settings, the device SHALL vibrate when something happens to the ball,
with a different feel for each event:
- a short light pulse when the ball actually jumps;
- a strong pulse when a boost starts;
- a double pulse when a checkpoint activates;
- a heartbeat, two soft pulses, when an adrenaline rush starts.

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

#### Scenario: Vibration disabled
- **WHEN** vibration is disabled and the ball jumps, takes a boost, activates a checkpoint or starts a rush
- **THEN** the device does not vibrate

## ADDED Requirements

### Requirement: A ball with weight
The ball SHALL fall about a fifth faster than before, so it leaves slopes and crests less and lands sooner. Its jump,
a jump boost's launch and a trampoline's bounce SHALL still reach the heights they reached before.

#### Scenario: Same jump, quicker fall
- **WHEN** the ball jumps from the ground
- **THEN** it rises about as high as before, about 2.7 m, and is back on the ground sooner than before

#### Scenario: Over a crest
- **WHEN** the ball rolls fast over a hill's crest
- **THEN** it stays on the ground at speeds at which it used to take off
