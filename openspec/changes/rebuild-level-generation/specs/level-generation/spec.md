# Spec Delta

## Purpose

Defines how Ball Odyssey produces its levels from a seed and a level number: infinite, deterministic, always
completable with the ball's real abilities, and steadily more demanding as the player climbs.

## ADDED Requirements

### Requirement: Deterministic levels
For a given seed and level number, generation SHALL produce exactly the same level on every device and platform,
Android and web included, in every app version that keeps the same generator version.

#### Scenario: Same seed on two platforms
- **WHEN** level 37 of seed "abc" is generated on Android and in a browser
- **THEN** both levels have identical terrain, boosts, checkpoints, start and goal

#### Scenario: Different seeds or levels
- **WHEN** two levels are generated with different seeds or different level numbers
- **THEN** their layouts differ

### Requirement: Infinite levels
Generation SHALL accept any level number from 1 upwards, with no last level.

#### Scenario: A very deep level
- **WHEN** level 10 000 is generated
- **THEN** a valid, completable level is produced

### Requirement: Start and goal
Every level SHALL start with a flat platform at least three tiles long with the ball above its middle, and SHALL end
with the goal on flat ground preceded by a run-in of at least two tiles.

#### Scenario: Starting a level
- **WHEN** a level loads
- **THEN** the ball rests on flat ground and can start moving without falling

#### Scenario: Reaching the goal
- **WHEN** the player crosses the last obstacle
- **THEN** flat ground leads to the goal

### Requirement: Every level is completable
Every gap, climb and drop SHALL be within what the ball can do. That means the movement envelope (jump height, speed
reachable from the available run-up, flight time and boost effects) with a safety margin. A player who moves right
and jumps at the right moments SHALL be able to reach the goal.

#### Scenario: Gap after a short run-up
- **WHEN** a gap follows a platform that is too short to reach top speed
- **THEN** the gap is no wider than the margin allows for the speed reachable on that platform

#### Scenario: Automated playthrough
- **WHEN** a scripted player that pushes right and jumps before edges and steps plays sampled levels from every
  stage
- **THEN** it reaches the goal of each one

### Requirement: Generation matches the ball's physics
The movement envelope the generator uses SHALL be reachable by the game's actual physics. A change to the physics
that makes the ball unable to reach it SHALL be detected before release.

#### Scenario: Weaker jump after tuning
- **WHEN** the jump impulse is lowered below what the envelope assumes
- **THEN** the envelope check fails

### Requirement: Coherent geometry
Ramps SHALL occupy their own horizontal span and join the floors at both ends at the right heights. No element SHALL
overlap the terrain, and boosts, checkpoints and the goal SHALL sit above walkable ground.

#### Scenario: Climb with a ramp
- **WHEN** the terrain rises with a ramp
- **THEN** the ramp starts at the end of the lower floor and ends at the start of the higher floor, without
  overlapping either

### Requirement: Stages introduce elements
Levels SHALL be grouped in stages of ten. The first stages SHALL introduce elements in this order:

1. flat ground, gentle ramps and small gaps;
2. drops and longer gaps;
3. jump steps and speed boosts;
4. jump boosts and chained gaps;
5. gravity boosts.

A stage SHALL NOT use elements that have not been introduced yet.

#### Scenario: Early levels
- **WHEN** levels 1 to 5 are generated
- **THEN** they contain only flat ground, gentle ramps and small gaps

#### Scenario: Element not introduced yet
- **WHEN** a level of the second stage is generated
- **THEN** it contains no boosts

### Requirement: Breather levels
Inside each stage, a gentler level SHALL recur every few levels, so that difficulty rises in a sawtooth.

#### Scenario: Breather inside a stage
- **WHEN** a stage's breather level is generated
- **THEN** its difficulty is lower than that of the levels just before and after it

### Requirement: Level length grows
The estimated duration of a level SHALL be about 30–45 seconds in the first stage and grow with the level number to
2–3 minutes in deep levels.

#### Scenario: First and deep levels
- **WHEN** level 3 and level 150 are generated
- **THEN** level 3 is estimated at 30–45 seconds and level 150 at 2–3 minutes

### Requirement: No difficulty ceiling
Past the scripted stages, obstacle density and required precision SHALL keep rising with the level number, always
within the movement envelope.

#### Scenario: Deep levels keep rising
- **WHEN** levels 100 and 300 are compared
- **THEN** level 300 has a higher obstacle density or tighter margins, and both remain completable

### Requirement: Boosts serve their section
Boosts SHALL be placed only where they enable or assist the section that follows them:

- speed boosts on the run-up before long gaps;
- jump boosts before climbs higher than a normal jump;
- gravity boosts before long floaty gaps.

#### Scenario: Climb higher than a jump
- **WHEN** a climb exceeds what a normal jump reaches
- **THEN** a jump boost is placed on the approach, and the climb is within the boosted jump height

### Requirement: Checkpoint placement
Checkpoints SHALL be placed on flat ground right after hard sections, from the second stage on. Their spacing SHALL
keep the replay after a fall short as levels get longer.

#### Scenario: Long deep level
- **WHEN** a level estimated at two minutes is generated
- **THEN** it has checkpoints so that no stretch between respawn points is much longer than about 40 seconds
