# game-session Specification

## Purpose
Defines how a play session runs from entering the game to leaving it: levels restart and advance without rebuilding the
game, and resources are released so long sessions stay smooth.

## Requirements

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

### Requirement: Level resources are released
When a level is unloaded (restart, advance or leaving the game), every resource it created SHALL be released: physics
bodies and world, input subscriptions, timers and visual effects.

#### Scenario: Leaving the game releases everything
- **WHEN** the player leaves the game screen during a level
- **THEN** no physics world, input subscription or pending timer from that session remains active

#### Scenario: Pending boost ends with the level
- **WHEN** a level is unloaded while a timed boost is active
- **THEN** the boost's timer is discarded and has no effect on the next level

### Requirement: Stable memory over long sessions
Memory use SHALL NOT grow with the number of levels played. After 30 consecutive level loads, the app's memory SHALL
stay within 10 % of its value after the first load.

#### Scenario: Repeated level loads
- **WHEN** the player restarts or advances 30 times in a row
- **THEN** total app memory after the 30th load is within 10 % of the memory after the first load

#### Scenario: Ten-minute session
- **WHEN** the game is played continuously for 10 minutes, including falls, restarts and boosts
- **THEN** memory does not show sustained growth and the frame rate does not degrade over the session

### Requirement: Pause during play
The game SHALL offer a pause action during play. While paused, the simulation and timers SHALL stop, and the player
SHALL be able to resume, restart the level, open settings, or return to the level selector.

#### Scenario: Pause stops the simulation
- **WHEN** the player pauses during a level
- **THEN** the ball and timers stop until the player resumes

#### Scenario: Settings from pause
- **WHEN** the player opens settings from the pause menu and returns
- **THEN** the level is still paused at the same state, with the new settings applied

#### Scenario: App sent to background
- **WHEN** the app goes to the background during a level
- **THEN** the game pauses and stays paused when the app returns to the foreground

### Requirement: Navigation survives a language change
Changing the language SHALL update the visible texts in place, without restarting navigation or reloading assets.

#### Scenario: Language change from settings
- **WHEN** the player changes the language in the settings screen
- **THEN** the texts switch to the new language and the player stays on the current screen

### Requirement: Checkpoints
Passing a checkpoint SHALL activate it, with visible feedback. Its activation area SHALL cover the whole flag, from
the ground to the top of the post, so touching any part of it counts. When the ball falls after a checkpoint has been
activated, the ball SHALL respawn at rest above the last activated checkpoint, with any running boost cancelled, and
the level SHALL NOT be rebuilt.

#### Scenario: Touching the top of the flag
- **WHEN** the ball jumps over a checkpoint and touches only the top of its post
- **THEN** the checkpoint activates

#### Scenario: Respawn at the last checkpoint
- **WHEN** the ball passes two checkpoints and then falls
- **THEN** it reappears at rest above the second checkpoint, and the rest of the level is unchanged

#### Scenario: Fall during a boost
- **WHEN** the ball falls while a gravity boost is running and a checkpoint is active
- **THEN** it respawns at the checkpoint with normal gravity

### Requirement: Prompt fall detection
A fall SHALL be detected as soon as no ground is left below the ball that it could still reach, given how fast it can
fall and travel sideways, and SHALL NOT be detected while such a landing is still possible. So long jumps and drops
onto real ground stay possible, and a hopeless fall does not leave the player waiting.

#### Scenario: A long drop onto distant ground
- **WHEN** the ball jumps off a high platform towards ground 15 m lower and 12 m ahead
- **THEN** no fall is detected, and the ball can land there

#### Scenario: A hopeless fall from high up
- **WHEN** the ball drops into a pit 40 m above the level's lowest ground, with no ground it could reach below
- **THEN** the fall is detected within about a second, not after the ball has fallen to the level's lowest point
