# Spec Delta

## MODIFIED Requirements

### Requirement: Stages introduce elements
Levels SHALL be grouped in stages of five for pacing. Elements SHALL first appear at these levels:

1. level 1: ramps, gaps, drops, jump steps, spikes, and the staircase, cascade and valley set pieces;
2. level 3: moving platforms;
3. level 6: speed boosts and crumbling platforms;
4. level 11: jump boosts and island hops;
5. level 16: gravity boosts;
6. level 21: double-jump orbs.

A level SHALL NOT use an element before the level where it first appears. From level 2 on, the level where an element
first appears SHALL use it at least once and feature it, and the element SHALL appear more often in the five levels
from its first appearance.

#### Scenario: Early levels
- **WHEN** levels 1 and 2 are generated
- **THEN** they mix ramps, gaps, drops, steps, spikes and the set pieces, and contain no boosts, moving platforms,
  crumbling platforms or orbs

#### Scenario: First appearance
- **WHEN** level 21 is generated, for any seed
- **THEN** it contains at least one double-jump orb

#### Scenario: Element not introduced yet
- **WHEN** a level from 6 to 10 is generated
- **THEN** it contains no jump boosts, gravity boosts or double-jump orbs

### Requirement: No difficulty ceiling
Past the scripted introductions, obstacle density and required precision SHALL keep rising with the level number,
always within the movement envelope.

#### Scenario: Deep levels keep rising
- **WHEN** levels 100 and 300 are compared
- **THEN** level 300 has a higher obstacle density or demands more precision, and both remain completable

### Requirement: Boosts serve their section
Boosts and orbs SHALL be placed only where they enable or assist the section that follows them:

- speed boosts on the run-up before gaps longer than a jump reaches;
- jump boosts before climbs higher than a normal jump;
- gravity boosts before long floaty gaps;
- double-jump orbs before gaps or climbs beyond one jump and within reach of two.

#### Scenario: Climb higher than a jump
- **WHEN** a climb exceeds what a normal jump reaches
- **THEN** a jump boost or an orb is placed on the approach, and the climb is within its boosted reach

## ADDED Requirements

### Requirement: Precision rises with the level
Each gap and climb SHALL use a share of the reach the ball can have at that point that grows with the level, from
about 70 % on the first levels to about 95 % in deep levels, never beyond it. The same SHALL apply to gaps and climbs
that need a boost or an orb, against their boosted reach. The reach SHALL be computed from the speed the ball can
actually build on the run-up available, calibrated against the real physics.

#### Scenario: First level
- **WHEN** level 1 is generated
- **THEN** its gaps and climbs need roughly 60–80 % of the reach available, so most jumps must be taken on purpose

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
