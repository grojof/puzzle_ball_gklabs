# Spec Delta

## MODIFIED Requirements

### Requirement: Stages introduce elements
Levels SHALL be grouped in stages of five for pacing. Elements SHALL first appear at these levels:

1. level 1: ramps, hills, half-pipes, gaps, drops, jump steps, spikes, and the staircase, cascade, valley, tower and
   descent set pieces;
2. level 2: moving platforms;
3. level 3: speed boosts;
4. level 4: crumbling platforms;
5. level 5: island hops;
6. level 6: jump boosts;
7. level 7: gravity boosts;
8. level 8: double-jump orbs;
9. level 9: trampolines;
10. level 11: conveyor belts, ice and mud;
11. level 13: loops.

A level SHALL NOT use an element before the level where it first appears. From level 2 on, the level where an element
first appears SHALL use it at least once and feature it, and the element SHALL appear more often in the five levels
from its first appearance.

#### Scenario: Early levels
- **WHEN** level 1 is generated
- **THEN** it mixes ramps, hills, half-pipes, gaps, drops, steps, spikes and the set pieces, and contains no boosts,
  moving platforms, crumbling platforms, orbs, trampolines, surfaces or loops

#### Scenario: First appearance
- **WHEN** level 13 is generated, for any seed
- **THEN** it contains at least one loop

#### Scenario: Element not introduced yet
- **WHEN** a level from 3 to 5 is generated
- **THEN** it contains no jump boosts, gravity boosts or double-jump orbs

#### Scenario: Everything by level 10
- **WHEN** level 10 is generated
- **THEN** every element introduced up to level 9 may appear in it

## ADDED Requirements

### Requirement: Curved terrain
Levels SHALL include hills of one to three bumps and half-pipes, and every slope between two heights SHALL be
rounded, never straight. Curves SHALL be no steeper than a ramp, so a player who keeps pushing climbs any of them,
even from rest. What follows a curve SHALL
be sized from the speed a pushing ball is measured to leave it at. Curves SHALL be smooth, with no step a ball catches
on.

#### Scenario: A hill after a short run-up
- **WHEN** a hill follows a short run-up
- **THEN** a player who keeps pushing climbs over it

#### Scenario: A way down
- **WHEN** the course goes down from one run to a lower one by a slope
- **THEN** the slope is rounded at both ends, with no straight ramp

#### Scenario: Through a half-pipe
- **WHEN** the player rolls into a half-pipe and keeps pushing
- **THEN** the ball climbs out of the far side

### Requirement: Trampolines serve their section
A trampoline SHALL be placed only on islands across a pit, each within a bounce of the next, beyond what a jump
reaches. The ground after it SHALL be reachable from the trampoline's bounce with the precision of the level. Climbs
beyond a jump are left to the jump boost.

#### Scenario: Islands across a pit
- **WHEN** a pit is crossed by trampoline islands
- **THEN** each bounce reaches the next island or the landing, and a plain jump would not

### Requirement: Surfaces stay fair
Conveyor belts, ice and mud SHALL be placed on floor runs, and every gap or climb after them SHALL be sized from the
speed and jump the ball has on that surface. A backward conveyor SHALL NOT run so fast that pushing cannot beat it.

#### Scenario: A gap after mud
- **WHEN** a gap follows a run of mud
- **THEN** it is within the weaker jump and lower speed the mud allows

### Requirement: Loops
A loop SHALL be entered from a flat run with a speed boost before it, so the ball enters fast enough to go around, and
SHALL be followed by a landing. Nothing SHALL stand on the loop's path.

#### Scenario: Going around
- **WHEN** the player keeps pushing through a speed boost into a loop
- **THEN** the ball goes around the loop and leaves it on the run after it
