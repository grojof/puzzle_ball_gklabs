# Spec Delta

## MODIFIED Requirements

### Requirement: Stages introduce elements
Levels SHALL be grouped in stages of five for pacing. Elements SHALL first appear at these levels:

1. level 1: ramps, hills, half-pipes, gaps, drops, jump steps, spikes, and the staircase, cascade, valley, tower and
   descent set pieces;
2. level 2: moving platforms;
3. level 3: speed boosts;
4. level 4: crumbling platforms;
5. level 5: island hops and the adrenaline rush;
6. level 6: jump boosts;
7. level 7: gravity boosts;
8. level 8: double-jump orbs;
9. level 9: trampolines;
10. level 11: conveyor belts, ice and mud;
11. level 13: loops;
12. level 15: fans;
13. level 17: bumpers;
14. level 19: pendulums;
15. level 21: seesaws.

A level SHALL NOT use an element before the level where it first appears. From level 2 on, the level where an element
first appears SHALL use it at least once and feature it, and the element SHALL appear more often in the five levels
from its first appearance.

#### Scenario: Early levels
- **WHEN** level 1 is generated
- **THEN** it mixes ramps, hills, half-pipes, gaps, drops, steps, spikes and the set pieces, and contains no boosts,
  moving platforms, crumbling platforms, orbs, trampolines, surfaces, loops, adrenaline rushes, fans, bumpers,
  pendulums or seesaws

#### Scenario: First appearance
- **WHEN** level 13 is generated, for any seed
- **THEN** it contains at least one loop

#### Scenario: The first rush
- **WHEN** level 5 is generated, for any seed
- **THEN** it contains at least one adrenaline rush, and levels 1 to 4 contain none

#### Scenario: Element not introduced yet
- **WHEN** a level from 3 to 5 is generated
- **THEN** it contains no jump boosts, gravity boosts or double-jump orbs

#### Scenario: Everything by level 10
- **WHEN** level 10 is generated
- **THEN** every element introduced up to level 9 may appear in it

#### Scenario: The dynamic elements
- **WHEN** levels 15, 17, 19 and 21 are generated, for any seed
- **THEN** level 15 contains a fan, level 17 a bumper, level 19 a pendulum and level 21 a seesaw, and no level uses
  one of them before its own

### Requirement: No difficulty ceiling
Past the scripted introductions, obstacle density and required precision SHALL keep rising with the level number,
always within the movement envelope. Deeper levels SHALL also have shorter rest stretches, more break points, and more
boosts, orbs, trampolines, loops, surfaces, fans, bumpers, pendulums and seesaws among their obstacles, so long
courses stay full.

#### Scenario: Deep levels keep rising
- **WHEN** levels 100 and 300 are compared
- **THEN** level 300 has a higher obstacle density or demands more precision, and both remain completable

#### Scenario: Deep levels stay full
- **WHEN** level 60 and level 15 are compared
- **THEN** level 60 has shorter rest stretches, and a larger share of its obstacles use boosts, orbs, trampolines,
  loops or surfaces

#### Scenario: Deep levels use the dynamic elements
- **WHEN** levels past 60 are generated
- **THEN** fans, bumpers, pendulums and seesaws appear among their obstacles

## ADDED Requirements

### Requirement: Fans serve their section
Fans SHALL stand in pits wider than a jump reaches, so the ball floats across them, or in the floor at the foot of a
wall higher than a jump boost reaches, so the ball rises to the ledge. A fan's column SHALL hold the ball high enough
that the bank or ledge it serves lies clearly below the hover height, and SHALL reach deep enough to catch a ball that
falls in from a jump. Columns over one pit SHALL leave no stretch without wind wider than the ball can glide across at
the hover height.

#### Scenario: A pit too wide to jump
- **WHEN** a pit wider than a jump is crossed by fans
- **THEN** a player who floats in the columns and pushes forwards reaches the far bank

#### Scenario: A wall beyond a jump boost
- **WHEN** a fan stands at the foot of a wall higher than a jump boost reaches
- **THEN** its column lifts the ball above the wall's top, and pushing forwards lands it on the ledge

### Requirement: Bumper roofs
A bumper roof SHALL hang over a drop gap and the end of the run before it: low enough that a jump from that run hits
it, and high enough that a ball rolling along the run passes under it. The gap SHALL be cleared by rolling off the
edge, within the reach of a ball leaving the edge at the speed it can carry there, with the level's precision.

#### Scenario: Rolling off
- **WHEN** a player keeps pushing and rolls off the edge under a bumper roof
- **THEN** the ball falls clear of the roof and lands on the far side

#### Scenario: Jumping into the roof
- **WHEN** a player jumps from the run under a bumper roof
- **THEN** the ball hits the roof and is thrown down

### Requirement: Pendulums leave a way through
Pendulums SHALL hang over floor runs, with room on the run before and after each mace's reach where the ball can wait
without being hit. Each mace SHALL leave the lane clear, on every swing, for long enough that a ball starting from rest
at the waiting spot before it crosses its reach, with the level's precision. Deeper levels MAY hang two or three maces
over one run, each with its own waiting room.

#### Scenario: Waiting for the gap
- **WHEN** the player waits at the waiting spot before a mace and goes as soon as the mace leaves the lane
- **THEN** the ball crosses the mace's reach before it comes back

#### Scenario: A gauntlet
- **WHEN** a deep level hangs several maces over one run
- **THEN** each has a waiting spot before it, out of every mace's reach

### Requirement: Seesaws over pits
A seesaw SHALL bridge part of a pit with its near end resting at the height of the run before it, so the ball rolls
onto it. The far bank SHALL be reachable by a jump from the plank's far end once tipped, sized from the speed and jump
a pushing ball is measured to have there, with the level's precision.

#### Scenario: Riding a seesaw
- **WHEN** a player rolls onto a seesaw, rides it as it tips and jumps from its far end
- **THEN** the ball reaches the far bank
