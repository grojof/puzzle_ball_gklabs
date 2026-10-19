# Spec Delta

## ADDED Requirements

### Requirement: Trampolines bounce the ball
Touching a trampoline from above SHALL throw the ball up to the same height every time, whatever speed it fell at.
Its horizontal speed SHALL be kept.

#### Scenario: Two different falls
- **WHEN** the ball lands on a trampoline once from a small hop and once from a long fall
- **THEN** it rises to the same height both times

### Requirement: Surfaces change how the ball moves
- A conveyor belt SHALL carry a ball on it forwards or backwards: resting on a belt, the ball moves with it, and a
  push adds to or works against it.
- On ice, the ball SHALL speed up and slow down much more slowly than on plain ground.
- On mud, the ball SHALL be held to a low top speed, and its jump SHALL be weaker.
- Leaving the surface SHALL end its effect.

#### Scenario: Resting on a belt
- **WHEN** the ball rests on a forward conveyor belt and the player does not push
- **THEN** the ball travels forwards with the belt

#### Scenario: Jumping from mud
- **WHEN** the ball jumps from a run of mud
- **THEN** it rises lower than from plain ground

### Requirement: Loops carry a fast ball around
A ball entering a loop at the speed its boost gives SHALL go around the loop along its inside and leave it on the run
after it. A ball that enters too slowly SHALL fall back out of the loop onto the run before it, without being sent
back. A ball SHALL never be trapped inside a loop: heading back SHALL always take it out of the entry.

#### Scenario: Through the loop
- **WHEN** the ball enters a loop at the boosted speed
- **THEN** it goes around and continues on the run after the loop

#### Scenario: Too slow
- **WHEN** the ball enters a loop slowly
- **THEN** it rolls back out of the loop's entry and can try again

#### Scenario: Falling in from above
- **WHEN** the ball falls into a loop from above and the player heads back
- **THEN** it rolls out of the loop's entry
