# Spec Delta

## MODIFIED Requirements

### Requirement: Settings screen
The game SHALL provide a settings screen with music volume, effects volume, control mode (tilt or joystick),
vibration and language, reachable from the title screen and from the in-game pause menu. Changes SHALL apply
immediately. Control mode and vibration SHALL only be offered on Android.

#### Scenario: Open from the title screen
- **WHEN** the player opens settings from the title screen
- **THEN** the settings screen shows the current values of every setting

#### Scenario: Return to where the player was
- **WHEN** the player closes the settings screen
- **THEN** the player is back on the screen that opened it (title screen or pause menu)

#### Scenario: Volume preview
- **WHEN** the player releases the effects volume slider
- **THEN** a sample effect plays at the new volume

#### Scenario: Turning vibration off during a session
- **WHEN** the player turns vibration off in the settings opened from the pause menu and resumes
- **THEN** jumps, boosts and checkpoints no longer vibrate

### Requirement: Default settings
On first launch, the music and effects volumes SHALL be 100 %, sound SHALL NOT be muted, the control mode SHALL be the
joystick, vibration SHALL be enabled, and the language SHALL be the device language if it is English, Spanish
or Catalan, or English otherwise.

#### Scenario: First launch on a Spanish device
- **WHEN** the app starts for the first time on a device set to Spanish
- **THEN** the game is in Spanish, with full volumes, sound on, joystick control and vibration on

#### Scenario: First launch on an unsupported language
- **WHEN** the app starts for the first time on a device set to German
- **THEN** the game is in English
