import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:settings_repository/settings_repository.dart';

part 'settings_state.dart';

/// The player's preferences (player-settings spec).
///
/// Every change is emitted at once, so audio and the game react while the
/// player drags a slider; `persist: false` lets a slider skip storage until
/// the drag ends.
class SettingsCubit extends Cubit<SettingsState> {
  new(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  /// Reads the stored settings; until then the defaults apply.
  Future<void> load() async {
    final settings = await _repository.load();
    emit(SettingsState(settings: settings, isLoaded: true));
  }

  Future<void> setMusicVolume(double volume, {bool persist = true}) => _update(
    state.settings.copyWith(musicVolume: volume.clamp(0, 1).toDouble()),
    persist: persist,
  );

  Future<void> setEffectsVolume(double volume, {bool persist = true}) =>
      _update(
        state.settings.copyWith(effectsVolume: volume.clamp(0, 1).toDouble()),
        persist: persist,
      );

  Future<void> toggleMuted() =>
      _update(state.settings.copyWith(muted: !state.settings.muted));

  Future<void> setControlMode(ControlMode mode) =>
      _update(state.settings.copyWith(controlMode: mode));

  /// Turns the vibration on jumps, boosts and checkpoints on or off.
  Future<void> setVibration({required bool enabled}) =>
      _update(state.settings.copyWith(vibration: enabled));

  /// Sets the interface language, or follows the device when [code] is null.
  Future<void> setLanguage(String? code) => _update(
    code == null
        ? state.settings.copyWith(followDeviceLanguage: true)
        : state.settings.copyWith(languageCode: code),
  );

  Future<void> _update(PlayerSettings settings, {bool persist = true}) async {
    emit(state.copyWith(settings: settings));
    if (persist) await _repository.save(settings);
  }
}
