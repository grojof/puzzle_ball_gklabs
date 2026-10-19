# Spec Delta

## MODIFIED Requirements

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

## ADDED Requirements

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
