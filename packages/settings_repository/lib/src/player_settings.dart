import 'package:meta/meta.dart';

/// How the player moves the ball.
enum ControlMode {
  /// On-screen joystick, or the keyboard.
  joystick,

  /// Tilting the device.
  tilt,
}

/// The player's preferences.
@immutable
class PlayerSettings {
  /// Creates settings; omitted fields take their defaults.
  const new({
    this.musicVolume = defaultVolume,
    this.effectsVolume = defaultVolume,
    this.muted = false,
    this.controlMode = ControlMode.joystick,
    this.vibration = true,
    this.languageCode,
  });

  /// The volume of music and effects on first launch.
  static const double defaultVolume = 1;

  /// The languages the game is translated into.
  static const supportedLanguageCodes = {'en', 'es', 'ca'};

  /// Music volume, from 0 to 1.
  final double musicVolume;

  /// Sound effects volume, from 0 to 1.
  final double effectsVolume;

  /// Whether all audio is silenced, keeping both volumes.
  final bool muted;

  /// How the player moves the ball.
  final ControlMode controlMode;

  /// Whether the device vibrates on jumps, boosts and checkpoints.
  final bool vibration;

  /// The chosen language, or `null` to follow the device.
  final String? languageCode;

  /// A copy with the given fields replaced.
  ///
  /// Pass [followDeviceLanguage] to clear [languageCode].
  PlayerSettings copyWith({
    double? musicVolume,
    double? effectsVolume,
    bool? muted,
    ControlMode? controlMode,
    bool? vibration,
    String? languageCode,
    bool followDeviceLanguage = false,
  }) {
    return PlayerSettings(
      musicVolume: musicVolume ?? this.musicVolume,
      effectsVolume: effectsVolume ?? this.effectsVolume,
      muted: muted ?? this.muted,
      controlMode: controlMode ?? this.controlMode,
      vibration: vibration ?? this.vibration,
      languageCode: followDeviceLanguage
          ? null
          : languageCode ?? this.languageCode,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PlayerSettings &&
      other.musicVolume == musicVolume &&
      other.effectsVolume == effectsVolume &&
      other.muted == muted &&
      other.controlMode == controlMode &&
      other.vibration == vibration &&
      other.languageCode == languageCode;

  @override
  int get hashCode => Object.hash(
    musicVolume,
    effectsVolume,
    muted,
    controlMode,
    vibration,
    languageCode,
  );

  @override
  String toString() =>
      'PlayerSettings(musicVolume: $musicVolume, '
      'effectsVolume: $effectsVolume, muted: $muted, '
      'controlMode: $controlMode, vibration: $vibration, '
      'languageCode: $languageCode)';
}
