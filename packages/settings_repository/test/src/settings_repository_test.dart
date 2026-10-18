import 'package:key_value_store/key_value_store.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:test/test.dart';

void main() {
  group(SettingsRepository, () {
    test('loads defaults from an empty store', () async {
      final repository = SettingsRepository(InMemoryKeyValueStore());

      expect(await repository.load(), const PlayerSettings());
    });

    test('round-trips every setting', () async {
      final repository = SettingsRepository(InMemoryKeyValueStore());
      const settings = PlayerSettings(
        musicVolume: 0.2,
        effectsVolume: 0.7,
        muted: true,
        controlMode: ControlMode.tilt,
        vibration: false,
        languageCode: 'ca',
      );

      await repository.save(settings);

      expect(await repository.load(), settings);
    });

    test('removes the language when following the device', () async {
      final store = InMemoryKeyValueStore({'languageCode': 'es'});
      final repository = SettingsRepository(store);

      await repository.save(const PlayerSettings());

      expect(await store.containsKey('languageCode'), isFalse);
      expect((await repository.load()).languageCode, isNull);
    });

    test('keeps the legacy sound switch in sync for rollback', () async {
      final store = InMemoryKeyValueStore();
      final repository = SettingsRepository(store);

      await repository.save(const PlayerSettings(muted: true));
      expect(await store.getBool('soundEnabled'), isFalse);

      await repository.save(const PlayerSettings());
      expect(await store.getBool('soundEnabled'), isTrue);
    });

    group('upgrade from earlier versions', () {
      test('maps sound off to muted and keeps language and control', () async {
        final repository = SettingsRepository(
          InMemoryKeyValueStore({
            'soundEnabled': false,
            'languageCode': 'es',
            'useSensorControl': true,
          }),
        );

        expect(
          await repository.load(),
          const PlayerSettings(
            muted: true,
            controlMode: ControlMode.tilt,
            languageCode: 'es',
          ),
        );
      });

      test('maps sound on to not muted', () async {
        final repository = SettingsRepository(
          InMemoryKeyValueStore({'soundEnabled': true}),
        );

        expect((await repository.load()).muted, isFalse);
      });

      test('prefers the new mute key over the legacy switch', () async {
        final repository = SettingsRepository(
          InMemoryKeyValueStore({'muted': false, 'soundEnabled': false}),
        );

        expect((await repository.load()).muted, isFalse);
      });

      test('drops the legacy current level', () async {
        final store = InMemoryKeyValueStore({'currentLevel': 7});

        await SettingsRepository(store).load();

        expect(await store.containsKey('currentLevel'), isFalse);
      });
    });

    group('invalid stored values fall back per field', () {
      test('volumes out of range or not a number', () async {
        for (final bad in [-0.1, 1.5, double.nan]) {
          final repository = SettingsRepository(
            InMemoryKeyValueStore({
              'musicVolume': bad,
              'effectsVolume': 0.4,
              'languageCode': 'ca',
            }),
          );

          final settings = await repository.load();

          expect(settings.musicVolume, 1, reason: '$bad');
          expect(settings.effectsVolume, 0.4);
          expect(settings.languageCode, 'ca');
        }
      });

      test('values of the wrong type', () async {
        final repository = SettingsRepository(
          InMemoryKeyValueStore({
            'musicVolume': 'loud',
            'effectsVolume': 1,
            'muted': 'yes',
            'useSensorControl': 1,
            'vibration': 'on',
            'languageCode': 3,
          }),
        );

        expect(await repository.load(), const PlayerSettings());
      });

      test('unsupported language', () async {
        final repository = SettingsRepository(
          InMemoryKeyValueStore({'languageCode': 'de'}),
        );

        expect((await repository.load()).languageCode, isNull);
      });
    });
  });
}
