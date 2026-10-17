import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_value_store/key_value_store.dart';
import 'package:puzzle_ball_gklabs/settings/settings.dart';
import 'package:settings_repository/settings_repository.dart';

void main() {
  late InMemoryKeyValueStore store;
  late SettingsRepository repository;

  setUp(() {
    store = InMemoryKeyValueStore();
    repository = SettingsRepository(store);
  });

  group('SettingsCubit', () {
    test('starts with defaults, not loaded', () {
      expect(SettingsCubit(repository).state, const SettingsState());
    });

    blocTest<SettingsCubit, SettingsState>(
      'load emits the stored settings',
      setUp: () => store = InMemoryKeyValueStore({'languageCode': 'ca'}),
      build: () => SettingsCubit(SettingsRepository(store)),
      act: (cubit) => cubit.load(),
      expect: () => [
        const SettingsState(
          settings: PlayerSettings(languageCode: 'ca'),
          isLoaded: true,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'volumes clamp, apply at once and persist only when asked',
      build: () => SettingsCubit(repository),
      act: (cubit) async {
        await cubit.setMusicVolume(0.3, persist: false);
        expect(await store.getDouble('musicVolume'), isNull);
        await cubit.setMusicVolume(1.5);
        await cubit.setEffectsVolume(-1);
      },
      expect: () => [
        const SettingsState(settings: PlayerSettings(musicVolume: 0.3)),
        const SettingsState(),
        const SettingsState(settings: PlayerSettings(effectsVolume: 0)),
      ],
      verify: (_) async {
        expect(await store.getDouble('musicVolume'), 1);
        expect(await store.getDouble('effectsVolume'), 0);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'mute, control mode and language persist',
      build: () => SettingsCubit(repository),
      act: (cubit) async {
        await cubit.toggleMuted();
        await cubit.setControlMode(ControlMode.tilt);
        await cubit.setLanguage('es');
        await cubit.setLanguage(null);
      },
      expect: () => [
        const SettingsState(settings: PlayerSettings(muted: true)),
        const SettingsState(
          settings: PlayerSettings(muted: true, controlMode: ControlMode.tilt),
        ),
        const SettingsState(
          settings: PlayerSettings(
            muted: true,
            controlMode: ControlMode.tilt,
            languageCode: 'es',
          ),
        ),
        const SettingsState(
          settings: PlayerSettings(muted: true, controlMode: ControlMode.tilt),
        ),
      ],
      verify: (_) async {
        final stored = await repository.load();
        expect(stored.muted, isTrue);
        expect(stored.controlMode, ControlMode.tilt);
        expect(stored.languageCode, isNull);
      },
    );
  });
}
