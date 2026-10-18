# Spec Delta

## MODIFIED Requirements

### Requirement: Demanding start
The first level SHALL be about as demanding as level 50 was before this change: most sections are obstacles, and gaps
and climbs use most of the ball's abilities. No level, breather or introduction, SHALL fall back to a trivial
difficulty.

#### Scenario: First level
- **WHEN** level 1 is generated
- **THEN** most of its sections are obstacles, and its gaps and climbs need about 80–90 % of the reach available

#### Scenario: A breather early on
- **WHEN** level 4, a breather, is generated
- **THEN** it is easier than levels 3 and 5, but its gaps still need well over half of the reach

### Requirement: Stages introduce elements
Levels SHALL be grouped in stages of five for pacing. Elements SHALL first appear at these levels:

1. level 1: ramps, gaps, drops, jump steps, spikes, and the staircase, cascade, valley, tower and descent set pieces;
2. level 2: moving platforms;
3. level 3: speed boosts;
4. level 4: crumbling platforms;
5. level 5: island hops;
6. level 6: jump boosts;
7. level 7: gravity boosts;
8. level 8: double-jump orbs.

A level SHALL NOT use an element before the level where it first appears. From level 2 on, the level where an element
first appears SHALL use it at least once and feature it, and the element SHALL appear more often in the five levels
from its first appearance.

#### Scenario: Early levels
- **WHEN** level 1 is generated
- **THEN** it mixes ramps, gaps, drops, steps, spikes and the set pieces, and contains no boosts, moving platforms,
  crumbling platforms or orbs

#### Scenario: First appearance
- **WHEN** level 8 is generated, for any seed
- **THEN** it contains at least one double-jump orb

#### Scenario: Element not introduced yet
- **WHEN** a level from 3 to 5 is generated
- **THEN** it contains no jump boosts, gravity boosts or double-jump orbs

#### Scenario: Everything by level 10
- **WHEN** level 10 is generated
- **THEN** every element listed above may appear in it

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

### Requirement: Level length grows
The estimated duration of a level SHALL be about 1.5 minutes at level 1 and grow with the level number to about
4 minutes in deep levels.

#### Scenario: First and deep levels
- **WHEN** level 1 and level 300 are generated
- **THEN** level 1 is estimated at about 80–100 seconds and level 300 at about 3.5–4 minutes

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

## ADDED Requirements

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
