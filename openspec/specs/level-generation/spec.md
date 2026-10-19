# level-generation Specification

## Purpose
Defines how Ball Odyssey produces its levels from a seed and a level number: infinite, deterministic, always
completable with the ball's real abilities, and steadily more demanding as the player climbs.

## Requirements

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

#### Scenario: Short landing after a drop or a gap
- **WHEN** an obstacle lands on a short run, so that a fast player must brake in the air to land on it
- **THEN** the next obstacle is sized for the speed that player can still have, not for the speed before braking

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

### Requirement: Demanding start
The first level SHALL be a little more demanding than the old level 50: most sections are obstacles, and gaps and
climbs use most of the ball's abilities. It SHALL still teach the game's rhythm: no longer than before, and with the
flow phrases a player learns to chain. No level, breather or introduction, SHALL fall back to a trivial difficulty.

#### Scenario: First level
- **WHEN** level 1 is generated
- **THEN** most of its sections are obstacles, more than before this change, and its gaps and climbs need about
  80–90 % of the reach available

#### Scenario: A breather early on
- **WHEN** level 4, a breather, is generated
- **THEN** it is easier than levels 3 and 5, but its gaps still need well over half of the reach

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
11. level 13: loops.

A level SHALL NOT use an element before the level where it first appears. From level 2 on, the level where an element
first appears SHALL use it at least once and feature it, and the element SHALL appear more often in the five levels
from its first appearance.

#### Scenario: Early levels
- **WHEN** level 1 is generated
- **THEN** it mixes ramps, hills, half-pipes, gaps, drops, steps, spikes and the set pieces, and contains no boosts,
  moving platforms, crumbling platforms, orbs, trampolines, surfaces, loops or adrenaline rushes

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

### Requirement: Set pieces
Besides single obstacles, levels SHALL use set pieces built from the same elements:

- staircases: two or three steps up with a short tread between them;
- cascades: two or three drops with a short tread between them;
- valleys: a ramp down, a gap and a ramp up;
- island hops: chained gaps whose platforms change height;
- towers: a climb of about 8–14 m by four to six tall steps with short treads, some with a gap before the step;
- descents: a long way down, about 8–16 m, by three to five drops, ramps down and gaps.

Every part of a set piece SHALL respect the same envelope limits as a single obstacle.

#### Scenario: Staircase
- **WHEN** a staircase is generated
- **THEN** it climbs two or three steps, each within a jump, with a tread between consecutive steps

#### Scenario: Tower
- **WHEN** a tower is generated
- **THEN** it climbs at least 8 m over four to six steps, each step and each gap within a jump

### Requirement: Level character
Each level SHALL feature two or three of the sections and set pieces available to it, which appear clearly more often
than the rest. Obstacles SHALL come in phrases of several back-to-back obstacles separated by short rest stretches:
flow phrases, taken without stopping, alternate with challenge phrases. So consecutive levels feel different from each
other, and every level has a rhythm.

#### Scenario: Consecutive levels
- **WHEN** ten consecutive levels of a seed are generated
- **THEN** they do not all feature the same sections

#### Scenario: Featured sections dominate
- **WHEN** a level is generated
- **THEN** its featured sections make up most of its obstacles

#### Scenario: Rhythm
- **WHEN** a level of about two minutes is generated
- **THEN** it has both flow phrases and challenge phrases

### Requirement: Breather levels
Inside each stage, a gentler level SHALL recur every few levels, so that difficulty rises in a sawtooth.

#### Scenario: Breather inside a stage
- **WHEN** a stage's breather level is generated
- **THEN** its difficulty is lower than that of the levels just before and after it

### Requirement: Level length grows
The estimated duration of a level SHALL be about 1.5 minutes at level 1 and grow with the level number to about
4 minutes in deep levels.

#### Scenario: First and deep levels
- **WHEN** level 1 and level 300 are generated
- **THEN** level 1 is estimated at about 80–100 seconds and level 300 at about 3.5–4 minutes

### Requirement: No difficulty ceiling
Past the scripted introductions, obstacle density and required precision SHALL keep rising with the level number,
always within the movement envelope. Deeper levels SHALL also have shorter rest stretches, more break points, and more
boosts, orbs, trampolines, loops and surfaces among their obstacles, so long courses stay full.

#### Scenario: Deep levels keep rising
- **WHEN** levels 100 and 300 are compared
- **THEN** level 300 has a higher obstacle density or demands more precision, and both remain completable

#### Scenario: Deep levels stay full
- **WHEN** level 60 and level 15 are compared
- **THEN** level 60 has shorter rest stretches, and a larger share of its obstacles use boosts, orbs, trampolines,
  loops or surfaces

### Requirement: Boosts serve their section
Boosts and orbs SHALL be placed only where they enable or assist the section that follows them:

- speed boosts on the run-up before gaps longer than a jump reaches;
- jump boosts before climbs higher than a normal jump;
- gravity boosts before long floaty gaps;
- double-jump orbs before gaps or climbs beyond one jump and within reach of two.

#### Scenario: Climb higher than a jump
- **WHEN** a climb exceeds what a normal jump reaches
- **THEN** a jump boost or an orb is placed on the approach, and the climb is within its boosted reach

### Requirement: Checkpoint placement
Checkpoints SHALL be placed on flat ground right after hard sections. Their spacing SHALL keep the replay after a
fall short, at about 35 seconds between respawn points at most.

#### Scenario: First level
- **WHEN** level 1 is generated
- **THEN** it has checkpoints, so that no stretch between respawn points is much longer than about 35 seconds

#### Scenario: Long deep level
- **WHEN** a level estimated at four minutes is generated
- **THEN** it has checkpoints so that no stretch between respawn points is much longer than about 35 seconds

### Requirement: Precision rises with the level
Each gap and climb SHALL use a share of the reach the ball can have at that point that grows with the level, from
about 80–90 % on the first level to about 90–95 % in deep levels, never beyond it. The same SHALL apply to gaps and
climbs that need a boost or an orb, against their boosted reach. The reach SHALL be computed from the speed the ball
can actually build on the run-up available, calibrated against the real physics.

#### Scenario: First level
- **WHEN** level 1 is generated
- **THEN** its gaps and climbs need about 80–90 % of the reach available, so the player must take off close to the
  edge

#### Scenario: Deep level
- **WHEN** level 300 is generated
- **THEN** its hardest gaps need over 90 % of the reach available, so the player must take off near the edge at full
  speed, and they remain within the reach

### Requirement: Spikes
Spike strips SHALL lie on flat floor, with flat floor to run up before them and to land on after them, and SHALL be no
wider than the margin allows to jump over from the run-up before them. They SHALL NOT lie on ramps, under boosts or
checkpoints, or at the start or the goal.

#### Scenario: Spikes after a short run-up
- **WHEN** spikes follow a short platform
- **THEN** they are no wider than a jump from that platform clears

### Requirement: Moving platforms
A moving platform SHALL shuttle across a gap too wide to jump, between a position next to the near edge and a
position next to the far edge, leaving at each end a step the ball can make without jumping far. Its travel SHALL be
slow enough to board and ride, and nothing SHALL block its path.

#### Scenario: Ferry over a wide gap
- **WHEN** a gap wider than a jump is bridged by a moving platform
- **THEN** the platform comes within a short step of each edge on every trip

### Requirement: Crumbling platforms
Crumbling platforms SHALL be short islands within a series of gaps, each reachable like any island of an island hop,
so a player who keeps moving crosses them before they collapse.

#### Scenario: Crossing crumbling islands
- **WHEN** a series of crumbling islands is generated
- **THEN** each gap between them is within the reach available, and each island is long enough to land and take off

### Requirement: Barriers guard shortcuts
Laser barriers SHALL hang over descents and below high stretches, where long jumps and drops would skip part of the
course. Their lower end SHALL stay above the highest point any jump of the intended route can reach there,
including boosted and double jumps, so the intended route never meets them. Consecutive barriers SHALL alternate, so
a shortcut needs timing.

#### Scenario: Following the route
- **WHEN** the player follows a descent's drops, ramps and gaps
- **THEN** no jump of the route reaches a laser barrier

#### Scenario: Trying a long shortcut
- **WHEN** the player leaps from the top of a descent towards its bottom
- **THEN** the flight crosses the laser barriers hanging over the descent

### Requirement: Vertical variety
A level SHALL climb and descend over a large range of heights, about 65 m between its highest and lowest ground at
most, instead of staying near its start height. Towers and descents SHALL give long climbs and drops, while the
course SHALL NOT grow into an endless tower or pit.

#### Scenario: A long level
- **WHEN** a level of about two minutes is generated
- **THEN** its ground spans well over 15 m of height, and stays within about 65 m

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

### Requirement: Flow phrases and break points
A flow phrase SHALL be a run of sections a player can take one after another without stopping, each sized for the
speed a player who keeps pushing carries there. As levels deepen, more flow phrases SHALL end in a break point, where
carrying that speed fails: the landing is short and blocked by a wall, spikes lie just past it, or a gap opens right
after a crest. A player who brakes in time SHALL always get through a break point, within the movement envelope.

#### Scenario: A flow phrase
- **WHEN** a player keeps pushing through a flow phrase
- **THEN** every gap and landing in it works at the speed they carry, with no need to stop

#### Scenario: A break point
- **WHEN** a player reaches a break point at full speed without braking
- **THEN** they overshoot or hit its hazard, while a player who brakes in time gets through

### Requirement: Varied climbs
As levels deepen, plain steps, staircases and towers SHALL become less common. Two plain climbs SHALL NOT follow each
other, and deep towers SHALL mix in climbs that need an orb or a jump boost.

#### Scenario: No repeated plain climbs
- **WHEN** any level is generated
- **THEN** no plain step up, staircase or tower directly follows another

#### Scenario: Deep towers
- **WHEN** towers in levels past 60 are generated
- **THEN** some of their climbs need an orb or a jump boost

### Requirement: Adrenaline zones
From level 5, the generator SHALL mark some tense phrases (spikes, crumbling islands, island hops, laser descents) as
adrenaline zones, more often in deeper levels. Every gap and climb inside a zone SHALL be sized from the speed and
reach the ball has during an adrenaline rush, with the level's precision.

#### Scenario: A zone's gaps
- **WHEN** a gap lies inside an adrenaline zone
- **THEN** it is within the reach of a jump at the rush's speed, and a share of it from the precision interval
