# Spec Delta

## Purpose

Defines how the camera frames the ball and the course, so the player can always see the ground they are about to
reach and judge the next jump, in portrait and in landscape.

## ADDED Requirements

### Requirement: Framing by screen shape
At rest, the camera SHALL keep a visible world at least 16 m wide and 9 m tall in landscape, and at least 12 m wide
in portrait, where the screen's narrow side limits how far it can zoom out before the ball becomes too small. At
rest, the ball SHALL sit horizontally centred in the lower half of the screen.

#### Scenario: Landscape phone
- **WHEN** a level starts on a landscape phone screen
- **THEN** the ball is in the lower half of the screen, the ground under it is visible, and at least 16 m by 9 m of
  the world is in view

#### Scenario: Portrait phone
- **WHEN** a level starts on a portrait phone screen
- **THEN** at least 12 m of the course is visible horizontally, with the ball in the lower half

### Requirement: Look-ahead
The camera SHALL frame more of the course in the direction the ball travels, growing with its horizontal speed up to
a limit, and SHALL return to centered framing when the ball stops.

#### Scenario: Running right
- **WHEN** the ball runs right at top speed
- **THEN** more course is visible to the right of the ball than when it stands still

### Requirement: Steady view over uneven ground
The camera SHALL follow the height of the ground under and just ahead of the ball, smoothed over time, rather than
the ball's own bounces. The view SHALL move continuously, without sudden jumps or oscillation, when the ball rolls
over steps, ramps and small gaps.

#### Scenario: Rolling over steps
- **WHEN** the ball rolls over a sequence of small steps and gaps
- **THEN** the camera moves smoothly in one direction per change of ground height, without swinging back and forth

#### Scenario: Jump in place
- **WHEN** the ball jumps on flat ground
- **THEN** the camera height stays close to the ground's, keeping the ball in view, instead of following the whole
  jump

### Requirement: Anticipated zoom
The camera SHALL start zooming out before the ball reaches a boost, early enough to finish before the ball gets
there at its current speed, and SHALL zoom out at high speed. It SHALL zoom back in smoothly afterwards.

#### Scenario: Boost ahead
- **WHEN** the ball approaches a boost at top speed
- **THEN** the camera is already zoomed out when the ball reaches the boost

#### Scenario: Boost passed
- **WHEN** the ball has passed a boost and slowed down
- **THEN** the camera returns to its normal zoom without jumping

### Requirement: Camera follows respawns and new levels
On a new level or a respawn at a checkpoint, the camera SHALL frame the ball immediately, without sweeping across the
level.

#### Scenario: Respawn
- **WHEN** the ball respawns at a checkpoint far behind where it fell
- **THEN** the next frame shows the ball framed as at rest
