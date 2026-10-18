# Spec Delta

## ADDED Requirements

### Requirement: Readable mechanics
Spikes SHALL be drawn as metal spikes with the hazard red, so they read as danger in every biome. Moving platforms
SHALL look mechanical and distinct from static ground, and crumbling platforms SHALL look cracked and SHALL shake
before collapsing. Double-jump orbs SHALL have their own color and an icon of two stacked up arrows. All SHALL follow
the depth style of the other elements.

#### Scenario: Spikes in the volcano
- **WHEN** spikes appear in the volcano
- **THEN** they read as hazards, with red tips that stand out from the lava glow

#### Scenario: Telling platforms apart
- **WHEN** a moving platform and a crumbling platform appear in the same level
- **THEN** the player can tell them apart from static ground and from each other at a glance
