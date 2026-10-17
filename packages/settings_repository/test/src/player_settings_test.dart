import 'package:settings_repository/settings_repository.dart';
import 'package:test/test.dart';

void main() {
  group(PlayerSettings, () {
    test('has the documented defaults', () {
      const settings = PlayerSettings();

      expect(settings.musicVolume, 1);
      expect(settings.effectsVolume, 1);
      expect(settings.muted, isFalse);
      expect(settings.controlMode, ControlMode.joystick);
      expect(settings.languageCode, isNull);
    });

    test('copyWith replaces the given fields only', () {
      const settings = PlayerSettings(languageCode: 'es');

      expect(
        settings.copyWith(
          musicVolume: 0.2,
          effectsVolume: 0.3,
          muted: true,
          controlMode: ControlMode.tilt,
        ),
        const PlayerSettings(
          musicVolume: 0.2,
          effectsVolume: 0.3,
          muted: true,
          controlMode: ControlMode.tilt,
          languageCode: 'es',
        ),
      );
      expect(settings.copyWith(), settings);
      expect(settings.copyWith(languageCode: 'ca').languageCode, 'ca');
    });

    test('copyWith can return to the device language', () {
      const settings = PlayerSettings(languageCode: 'es');

      expect(
        settings.copyWith(followDeviceLanguage: true).languageCode,
        isNull,
      );
    });

    test('compares by value', () {
      expect(
        const PlayerSettings(musicVolume: 0.5),
        const PlayerSettings(musicVolume: 0.5),
      );
      expect(
        const PlayerSettings(musicVolume: 0.5).hashCode,
        const PlayerSettings(musicVolume: 0.5).hashCode,
      );
      expect(const PlayerSettings(muted: true), isNot(const PlayerSettings()));
    });

    test('describes itself', () {
      expect(
        const PlayerSettings().toString(),
        'PlayerSettings(musicVolume: 1.0, effectsVolume: 1.0, muted: false, '
        'controlMode: ControlMode.joystick, languageCode: null)',
      );
    });
  });
}
