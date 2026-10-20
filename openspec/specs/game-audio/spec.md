# game-audio Specification

## Purpose
Defines how the game plays background music and sound effects, how the player controls their volume, and how audio
behaves with the app lifecycle and across platforms.

## Requirements

### Requirement: Music starts with the app
When sound is not muted, the background music SHALL start as soon as the app has loaded its assets and the stored
settings, and loop continuously. On the web, where browsers block audio until the user interacts, it SHALL start at
the player's first interaction.

#### Scenario: Launch on Android with sound on
- **WHEN** the app starts on Android with sound not muted
- **THEN** the music starts after loading, without the player touching any sound control

#### Scenario: Launch on the web
- **WHEN** the game opens in a browser with sound not muted
- **THEN** the music starts at the player's first tap, click or key press

#### Scenario: Launch muted
- **WHEN** the app starts with sound muted
- **THEN** no music or effects play until the player unmutes

### Requirement: Separate music and effects volumes
Music and sound effects SHALL each have their own volume, from 0 to 100 %, applied immediately when changed and
persisted between launches.

#### Scenario: Lower the music only
- **WHEN** the player sets the music volume to 20 % and leaves effects at 100 %
- **THEN** the music plays quieter while jump and boost sounds keep their volume

#### Scenario: Volumes persist
- **WHEN** the player changes either volume and restarts the app
- **THEN** both volumes are restored to the chosen values

### Requirement: Quick mute
A quick sound toggle SHALL mute and unmute all audio without changing the stored volumes.

#### Scenario: Mute and unmute
- **WHEN** the player mutes, then unmutes
- **THEN** audio stops while muted and resumes at the previous music and effects volumes

### Requirement: Effects play reliably and evenly
Every game event with a sound (jump, jump boost, speed boost, gravity boost, the start of an adrenaline rush, a bumper
throwing the ball, a mace hitting it, the ball entering a fan's column) SHALL play it each time it happens, with no
audible delay, and all effects SHALL sound at a comparable loudness at the same effects volume.

#### Scenario: Rapid repeated jumps
- **WHEN** the ball jumps many times in quick succession
- **THEN** each jump plays its sound, and the number of audio players in use does not grow with the number of jumps

#### Scenario: Consistent loudness
- **WHEN** the jump sound, each boost sound, the heartbeat and the bumper, mace and updraft sounds play at the same
  effects volume
- **THEN** none is noticeably quieter or louder than the others

#### Scenario: A rush starts
- **WHEN** the ball enters an adrenaline zone with sound on
- **THEN** a heartbeat plays

#### Scenario: A bumper
- **WHEN** a bumper throws the ball with sound on
- **THEN** a bright ding plays

### Requirement: Audio follows the app lifecycle
Audio SHALL pause when the app goes to the background and resume when it returns, if sound is not muted.

#### Scenario: Background and return
- **WHEN** the app goes to the background and later returns to the foreground
- **THEN** the music is silent while in the background and resumes on return

### Requirement: Compact audio assets
The background track SHALL be no larger than 5 MB, so the web version loads quickly, without audible loss for the
player.

#### Scenario: Web load size
- **WHEN** the game's audio assets are measured
- **THEN** the background track is 5 MB or less
