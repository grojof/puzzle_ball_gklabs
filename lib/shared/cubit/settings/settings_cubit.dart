import 'package:bloc/bloc.dart';
import 'package:puzzle_ball_gklabs/game/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState.initial()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final currentLevel = prefs.getInt('currentLevel') ?? 1;
    final languageCode = prefs.getString('languageCode') ?? 'es';
    final soundEnabled = prefs.getBool('soundEnabled') ?? true;
    final useSensor = prefs.getBool('useSensorControl') ?? false;
    emit(
      state.copyWith(
        currentLevel: currentLevel,
        languageCode: languageCode,
        soundEnabled: soundEnabled,
        useSensorControl: useSensor,
      ),
    );
  }

  Future<void> changeLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', code);
    emit(state.copyWith(languageCode: code));
  }

  Future<void> setCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', level);
    emit(state.copyWith(currentLevel: level));
  }

  Future<void> resetProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('currentLevel', 1);
    emit(state.copyWith(currentLevel: 1));
  }

  Future<void> toggleSound({
    required bool enabled,
    AudioCubit? audioCubit,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('soundEnabled', enabled);
    emit(state.copyWith(soundEnabled: enabled));

    if (audioCubit != null) {
      if (enabled) {
        await audioCubit.enableAndPlay();
      } else {
        await audioCubit.disable();
      }
    }
  }

  Future<void> toggleControlMode({required bool useSensor}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSensorControl', useSensor);
    emit(state.copyWith(useSensorControl: useSensor));
  }

  Future<void> updateMaxLevelIfNeeded(int reachedLevel) async {
    if (reachedLevel > state.currentLevel) {
      await setCurrentLevel(reachedLevel);
    }
  }
}
