import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/shared/storage/shared_preferences_key_value_store.dart';
import 'package:savegame_repository/savegame_repository.dart';
import 'package:settings_repository/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferencesKeyValueStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    store = SharedPreferencesKeyValueStore();
  });

  group('SharedPreferencesKeyValueStore', () {
    test('round-trips every supported type', () async {
      await store.setString('s', 'text');
      await store.setBool('b', value: true);
      await store.setDouble('d', 0.5);
      await store.setInt('i', 3);
      await store.setStringList('l', ['a', 'b']);

      expect(await store.getString('s'), 'text');
      expect(await store.getBool('b'), isTrue);
      expect(await store.getDouble('d'), 0.5);
      expect(await store.getInt('i'), 3);
      expect(await store.getStringList('l'), ['a', 'b']);
    });

    test('returns null for missing keys and for values of another type', () {
      SharedPreferences.setMockInitialValues({'n': 1});

      expect(store.getString('missing'), completion(isNull));
      expect(store.getString('n'), completion(isNull));
      expect(store.getBool('n'), completion(isNull));
      expect(store.getDouble('n'), completion(isNull));
      expect(store.getStringList('n'), completion(isNull));
      expect(store.getInt('missing'), completion(isNull));
    });

    test('reports and removes keys', () async {
      await store.setInt('k', 1);
      expect(await store.containsKey('k'), isTrue);

      await store.remove('k');
      expect(await store.containsKey('k'), isFalse);
    });
  });

  group('data stored by earlier versions', () {
    test('reads back through both repositories', () async {
      const savedGame =
          '{"id":"1","seed":"42","totalLevels":50,"currentLevel":3,'
          '"createdAt":"2025-05-01T10:00:00.000",'
          '"lastPlayed":"2025-05-02T10:00:00.000"}';
      SharedPreferences.setMockInitialValues({
        'languageCode': 'ca',
        'soundEnabled': false,
        'useSensorControl': true,
        'currentLevel': 7,
        'savedGames': <String>[savedGame],
      });

      final settings = await SettingsRepository(store).load();
      final games = await SavegameRepository(store).loadAll();

      expect(settings.languageCode, 'ca');
      expect(settings.muted, isTrue);
      expect(settings.controlMode, ControlMode.tilt);
      expect(settings.musicVolume, 1);
      expect(games.single.seed, '42');
      expect(games.single.currentLevel, 3);
    });
  });
}
