# Spec Delta

## MODIFIED Requirements

### Requirement: Respawns restore the course
When the ball respawns at a checkpoint, crumbled platforms and collected orbs SHALL be restored and seesaws SHALL
return to rest, so every section ahead can be attempted again as it was. Laser barriers and pendulums SHALL keep their
rhythm.

#### Scenario: Falling after an orb
- **WHEN** the ball collects an orb, misses the gap it served and respawns at the checkpoint before it
- **THEN** the orb is back in its place

#### Scenario: Falling off a seesaw
- **WHEN** the ball tips a seesaw, falls into the pit and respawns
- **THEN** the seesaw is back at rest, with its near end at the run's height

## ADDED Requirements

### Requirement: Fans lift the ball
A fan SHALL blow a column of air upwards, always on. Inside the column, the ball SHALL be lifted towards the column's
hover height and float there, bobbing less and less, while the player can still push it sideways. Above the column or
outside it, the fan SHALL have no effect.

#### Scenario: Floating
- **WHEN** the ball enters a fan's column and the player does not push
- **THEN** it rises to the hover height and floats there

#### Scenario: Leaving the column
- **WHEN** the player pushes the ball out of the column's side
- **THEN** the ball falls as usual

### Requirement: Bumpers throw the ball
Touching a bumper SHALL throw the ball straight away from the bumper's surface at a fixed speed, whatever speed it hit
at, keeping its speed along the surface. A bumper SHALL NOT send the ball back to a checkpoint by itself.

#### Scenario: Rolling into a post
- **WHEN** the ball rolls into a bumper post
- **THEN** it is thrown back at the bumper's speed

### Requirement: Pendulums knock the ball
A pendulum SHALL swing an iron mace on a rigid arm on a fixed rhythm, the same on every device. A mace that meets the
ball SHALL throw it straight away from the mace at a fixed, strong speed. It SHALL NOT send the ball back to a checkpoint
by itself.

#### Scenario: Hit by a mace
- **WHEN** a mace swinging forwards meets the ball
- **THEN** the ball is thrown forwards hard, and falls if it is thrown off the run

#### Scenario: Passing under a raised mace
- **WHEN** the ball crosses a mace's reach while the mace is high in its swing
- **THEN** nothing happens to the ball

### Requirement: Seesaws tip under the ball
A seesaw SHALL be a plank on a pivot that rests leaning back, with its near end down. Past the pivot, the ball's weight
SHALL tip it forwards until it stops at its forward tilt; heading back past the pivot SHALL tip it back. A ball left
still on the tipped plank SHALL roll off its low end.

#### Scenario: Crossing the pivot
- **WHEN** the ball rolls past a seesaw's pivot
- **THEN** the plank tips forwards and its far end drops

#### Scenario: Stalling on the plank
- **WHEN** the player stops pushing on a tipped plank
- **THEN** the ball rolls off its low end
