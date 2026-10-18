# player-settings Specification

## Purpose
Defines the player's persisted preferences (music volume, effects volume, mute, control mode, vibration and language)
and the settings screen where they are changed.

## Requirements

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

### Requirement: Settings persist
Every setting SHALL be stored on the device and restored on the next launch.

#### Scenario: Restore after restart
- **WHEN** the player changes any setting and restarts the app
- **THEN** the setting has the value the player chose

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

### Requirement: Existing preferences are kept
Preferences stored by earlier versions SHALL be kept: language, control mode, and the sound on or off choice, which
becomes the mute state.

#### Scenario: Upgrade with sound off
- **WHEN** a player who had turned sound off installs the new version
- **THEN** sound starts muted, with both volumes at 100 %, and the stored language and control mode are unchanged

### Requirement: Invalid stored values fall back to defaults
A stored value that is missing, of the wrong type or out of range SHALL be replaced by its default, without affecting
the other settings.

#### Scenario: Corrupted volume
- **WHEN** the stored music volume is outside 0–100 % or not a number
- **THEN** the music volume is 100 % and the other settings keep their stored values
