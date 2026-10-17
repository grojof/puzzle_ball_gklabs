# Spec Delta

## Purpose

Defines how a play session runs from entering the game to leaving it: levels restart and advance without rebuilding the
game, and resources are released so long sessions stay smooth.

## ADDED Requirements

### Requirement: One game per play session
A play session SHALL keep a single running game from the moment the player enters a level until the player leaves the
game screen. Restarting a level and advancing to the next level SHALL NOT recreate the game screen or change the route.

#### Scenario: Restart after a fall keeps the session
- **WHEN** the ball falls out of the level
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
