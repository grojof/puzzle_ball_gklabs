# Spec Delta

## Purpose

Defines the in-game indicators and messages that report the player's state during play: checkpoints reached,
running boosts, the double-jump orb's charge and pickups, kept small so the course stays in view.

## ADDED Requirements

### Requirement: Checkpoint track
During play, the HUD SHALL show one small flag per checkpoint of the level, in a row at the top left under the
pause button, in course order. A checkpoint not yet reached SHALL show as pending, in grey, and a reached one as gold.
The row SHALL update when a checkpoint activates and SHALL keep reached checkpoints after a respawn. A level without
checkpoints SHALL show no row.

#### Scenario: Reaching the second checkpoint
- **WHEN** the ball activates the second of three checkpoints
- **THEN** the first two flags of the row are gold and the third is grey

#### Scenario: Level without checkpoints
- **WHEN** a short level without checkpoints starts
- **THEN** no checkpoint row is shown

### Requirement: Active boosts and orb charge
While a boost runs, the HUD SHALL show its icon, in the boost's color, in a short column at the top right under the
sound button, with a ring that empties over the boost's remaining time. The icon SHALL disappear when the boost ends,
is replaced by another, or the ball respawns. While a double-jump orb's charge is held, the column SHALL show the orb's icon, until the charge is
spent or lost.

#### Scenario: Gravity boost running
- **WHEN** the ball passes a gravity boost
- **THEN** the gravity icon appears at the top right with a full ring, which empties over two seconds, and then the
  icon disappears

#### Scenario: Orb charge held
- **WHEN** the ball collects a double-jump orb and has not used the charge
- **THEN** the orb's icon shows at the top right, and it disappears once the air jump is used

### Requirement: Pickup messages
Collecting a double-jump orb or reaching a checkpoint SHALL show a short message above the ball, with the element's
icon and color, in the player's language. The message SHALL rise slightly and fade out within one second, SHALL be
smaller than the level-start banner and styled differently, and SHALL NOT block input.

#### Scenario: Collecting an orb in Spanish
- **WHEN** the language is Spanish and the ball collects a double-jump orb
- **THEN** a small message with the orb's icon and the Spanish text for "Double jump!" rises above the ball and fades
  within one second

#### Scenario: Reaching a checkpoint
- **WHEN** the ball activates a checkpoint
- **THEN** a small "Checkpoint" message in the checkpoint's gold appears above the ball and fades

### Requirement: Unobtrusive HUD
Indicators SHALL be sized from the screen's shorter side within fixed limits, and fixed ones (the checkpoint track)
SHALL be smaller than temporary ones (boosts, the orb's charge, messages). They SHALL stay in the top corners, under
the pause and sound buttons, clear of the controls and the middle of the screen.

#### Scenario: Smooth play with the HUD
- **WHEN** a deep level is played on the reference phone with the HUD showing
- **THEN** the frame time stays within a few milliseconds of the build before this change

#### Scenario: Portrait phone
- **WHEN** the game runs on a portrait phone with a boost running and two checkpoints reached
- **THEN** the checkpoint flags sit under the pause button and the boost icon under the sound button, clear of the
  controls, and the flags are smaller than the boost icon

### Requirement: Clear of the system's cutouts
The indicators and the pause and sound buttons SHALL stay clear of the system's status bar and camera cutout, in
portrait and landscape.

#### Scenario: Camera cutout at the top centre
- **WHEN** the game runs on a portrait phone whose camera cutout and status bar take the top of the screen
- **THEN** the pause and sound buttons, the checkpoint flags and the boost icons all sit below them
