# Spec Delta

## MODIFIED Requirements

### Requirement: Active boosts and orb charge
While a boost runs, the HUD SHALL show its icon, in the boost's color, in a short column at the top right under the
sound button, with a ring that empties over the boost's remaining time. The icon SHALL disappear when the boost ends,
is replaced by another, or the ball respawns. While a double-jump orb's charge is held, the column SHALL show the orb's
icon, until the charge is spent or lost. During an adrenaline rush, the column SHALL show a red heart that beats, until
the rush ends.

#### Scenario: Gravity boost running
- **WHEN** the ball passes a gravity boost
- **THEN** the gravity icon appears at the top right with a full ring, which empties over two seconds, and then the
  icon disappears

#### Scenario: Orb charge held
- **WHEN** the ball collects a double-jump orb and has not used the charge
- **THEN** the orb's icon shows at the top right, and it disappears once the air jump is used

#### Scenario: Adrenaline rush
- **WHEN** the ball enters an adrenaline zone
- **THEN** a beating red heart shows in the column, and it disappears when the ball leaves the zone or respawns
