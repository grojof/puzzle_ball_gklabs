# Spec Delta

## MODIFIED Requirements

### Requirement: One game per play session
A play session SHALL keep a single running game from the moment the player enters a level until the player leaves the
game screen. Restarting a level and advancing to the next level SHALL NOT recreate the game screen or change the route.

#### Scenario: Restart after a fall keeps the session
- **WHEN** the ball falls out of the level and no checkpoint of that level has been activated
- **THEN** the same level restarts with the ball at its start position, the game screen stays mounted and the route is unchanged

#### Scenario: Advance after reaching the goal keeps the session
- **WHEN** the ball reaches the goal and the level is not the last of the savegame
- **THEN** the next level loads in the same game screen and the savegame records the new current level

#### Scenario: Last level returns to the menu
- **WHEN** the ball reaches the goal of the savegame's last level
- **THEN** the session ends and the player returns to the title screen

## ADDED Requirements

### Requirement: Checkpoints
Passing a checkpoint SHALL activate it, with visible feedback. When the ball falls after a checkpoint has been
activated, the ball SHALL respawn at rest above the last activated checkpoint, with any running boost cancelled, and
the level SHALL NOT be rebuilt.

#### Scenario: Respawn at the last checkpoint
- **WHEN** the ball passes two checkpoints and then falls
- **THEN** it reappears at rest above the second checkpoint, and the rest of the level is unchanged

#### Scenario: Fall during a boost
- **WHEN** the ball falls while a gravity boost is running and a checkpoint is active
- **THEN** it respawns at the checkpoint with normal gravity
