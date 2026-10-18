import 'package:key_value_store/key_value_store.dart';
import 'package:settings_repository/src/player_settings.dart';

/// Loads and saves [PlayerSettings] in a [KeyValueStore].
///
/// Every stored value is validated on its own: a missing, mistyped or
/// out-of-range value falls back to its default without affecting the others.
/// Values written by earlier versions of the game are read as well.
class SettingsRepository {
  /// Creates a repository backed by the given store.
  new(this._store);

  final KeyValueStore _store;

  /// Storage keys. `useSensorControl`, `languageCode` and `soundEnabled` are
  /// the keys earlier versions used.
  static const musicVolumeKey = 'musicVolume';

  /// See [musicVolumeKey].
  static const effectsVolumeKey = 'effectsVolume';

  /// See [musicVolumeKey].
  static const mutedKey = 'muted';

  /// See [musicVolumeKey].
  static const useSensorControlKey = 'useSensorControl';

  /// See [musicVolumeKey].
  static const languageCodeKey = 'languageCode';

  /// Key of [PlayerSettings.vibration].
  static const vibrationKey = 'vibration';

  /// Legacy sound switch, kept in sync with [mutedKey] for rollback.
  static const soundEnabledKey = 'soundEnabled';

  /// Legacy progress counter, superseded by savegames.
  static const legacyCurrentLevelKey = 'currentLevel';

  /// Reads the stored settings, with defaults for anything missing or invalid.
  Future<PlayerSettings> load() async {
    if (await _store.containsKey(legacyCurrentLevelKey)) {
      await _store.remove(legacyCurrentLevelKey);
    }

    final muted =
        await _store.getBool(mutedKey) ??
        await _legacyMuted() ??
        const PlayerSettings().muted;
    final useSensor = await _store.getBool(useSensorControlKey) ?? false;
    final languageCode = await _store.getString(languageCodeKey);

    return PlayerSettings(
      musicVolume: _volume(await _store.getDouble(musicVolumeKey)),
      effectsVolume: _volume(await _store.getDouble(effectsVolumeKey)),
      muted: muted,
      controlMode: useSensor ? ControlMode.tilt : ControlMode.joystick,
      vibration:
          await _store.getBool(vibrationKey) ??
          const PlayerSettings().vibration,
      languageCode: PlayerSettings.supportedLanguageCodes.contains(languageCode)
          ? languageCode
          : null,
    );
  }

  /// Stores [settings].
  Future<void> save(PlayerSettings settings) async {
    await _store.setDouble(musicVolumeKey, settings.musicVolume);
    await _store.setDouble(effectsVolumeKey, settings.effectsVolume);
    await _store.setBool(mutedKey, value: settings.muted);
    await _store.setBool(soundEnabledKey, value: !settings.muted);
    await _store.setBool(
      useSensorControlKey,
      value: settings.controlMode == ControlMode.tilt,
    );
    await _store.setBool(vibrationKey, value: settings.vibration);
    final languageCode = settings.languageCode;
    if (languageCode == null) {
      await _store.remove(languageCodeKey);
    } else {
      await _store.setString(languageCodeKey, languageCode);
    }
  }

  Future<bool?> _legacyMuted() async {
    final soundEnabled = await _store.getBool(soundEnabledKey);
    return soundEnabled == null ? null : !soundEnabled;
  }

  static double _volume(double? stored) {
    if (stored == null || stored.isNaN || stored < 0 || stored > 1) {
      return PlayerSettings.defaultVolume;
    }
    return stored;
  }
}
