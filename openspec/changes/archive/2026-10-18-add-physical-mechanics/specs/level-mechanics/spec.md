# Spec Delta

## Purpose

Defines how the level elements beyond terrain and boosts behave in play: spikes, moving platforms, crumbling
platforms and double-jump orbs, and what a respawn restores.

## ADDED Requirements

### Requirement: Spikes send the ball back
When the ball touches spikes, it SHALL be sent back as after a fall: it SHALL respawn at rest above the last active
checkpoint, or the level SHALL restart when no checkpoint is active.

#### Scenario: Spikes after a checkpoint
- **WHEN** the ball touches spikes after passing a checkpoint
- **THEN** it reappears at rest above that checkpoint

#### Scenario: Spikes before any checkpoint
- **WHEN** the ball touches spikes with no checkpoint active
- **THEN** the level restarts

### Requirement: Moving platforms carry the ball
A moving platform SHALL travel back and forth along its path at a steady speed, pausing briefly at each end. A ball
resting on it SHALL be carried along without sliding off while the player does not push.

#### Scenario: Riding a ferry
- **WHEN** the ball rolls onto a moving platform and the player stops pushing
- **THEN** the ball travels with the platform to the far edge

### Requirement: Crumbling platforms collapse
A crumbling platform SHALL start shaking when the ball stands on it, and collapse shortly after (about 0.6 seconds),
leaving no ground. It SHALL NOT collapse before the ball touches it.

#### Scenario: Standing too long
- **WHEN** the ball stops on a crumbling platform
- **THEN** the platform shakes, collapses after about 0.6 seconds, and the ball falls

### Requirement: Double-jump orbs grant one air jump
Collecting a double-jump orb SHALL charge one jump that the player can use in mid-air, once. Using it SHALL make the
ball jump from its current height, whatever its vertical speed. The charge SHALL be lost when the level ends or the
ball respawns, and an orb SHALL disappear when collected.

#### Scenario: Using the charge
- **WHEN** the ball has collected an orb and the player presses jump in mid-air
- **THEN** the ball jumps again, and the charge is spent

### Requirement: Respawns restore the course
When the ball respawns at a checkpoint, crumbled platforms and collected orbs SHALL be restored, so every section
ahead can be attempted again as it was.

#### Scenario: Falling after an orb
- **WHEN** the ball collects an orb, misses the gap it served and respawns at the checkpoint before it
- **THEN** the orb is back in its place
