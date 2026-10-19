# Spec Delta

## ADDED Requirements

### Requirement: Loops stay in view
While the ball rides a loop, the camera SHALL keep the whole loop in view, steadily, without following each turn of
the ball.

#### Scenario: Riding a loop
- **WHEN** the ball goes around a loop
- **THEN** the whole loop stays on screen and the view does not spin or jerk
