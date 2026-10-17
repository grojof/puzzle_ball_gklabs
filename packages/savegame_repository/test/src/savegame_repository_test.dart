import 'dart:convert';

import 'package:key_value_store/key_value_store.dart';
import 'package:savegame_repository/savegame_repository.dart';
import 'package:test/test.dart';

SavedGame savedGame(String id, {int currentLevel = 1}) => SavedGame(
  id: id,
  seed: 'seed-$id',
  totalLevels: 50,
  currentLevel: currentLevel,
  createdAt: DateTime(2026, 10),
  lastPlayed: DateTime(2026, 10),
);

void main() {
  group(SavegameRepository, () {
    final now = DateTime(2026, 10, 17, 9);
    late InMemoryKeyValueStore store;
    late SavegameRepository repository;

    setUp(() {
      store = InMemoryKeyValueStore();
      repository = SavegameRepository(store, now: () => now);
    });

    test('is empty when nothing is stored', () async {
      expect(await repository.loadAll(), isEmpty);
    });

    test('adds savegames in order and persists them', () async {
      await repository.add(savedGame('a'));
      final games = await repository.add(savedGame('b'));

      expect(games.map((g) => g.id), ['a', 'b']);
      expect((await SavegameRepository(store).loadAll()).map((g) => g.id), [
        'a',
        'b',
      ]);
    });

    test('reads savegames stored by earlier versions', () async {
      store = InMemoryKeyValueStore({
        'savedGames': [jsonEncode(savedGame('old', currentLevel: 7).toJson())],
      });

      final games = await SavegameRepository(store).loadAll();

      expect(games.single, savedGame('old', currentLevel: 7));
    });

    test('skips malformed entries', () async {
      store = InMemoryKeyValueStore({
        'savedGames': [
          'not json',
          '[1, 2]',
          jsonEncode({'id': 'missing fields'}),
          jsonEncode({...savedGame('bad').toJson(), 'createdAt': 'yesterday'}),
          jsonEncode(savedGame('good').toJson()),
        ],
      });

      final games = await SavegameRepository(store).loadAll();

      expect(games.map((g) => g.id), ['good']);
    });

    group('update', () {
      test('raises the current level and stamps last played', () async {
        await repository.add(savedGame('a', currentLevel: 2));
        await repository.add(savedGame('b'));

        final games = await repository.update(savedGame('a', currentLevel: 5));

        expect(games.first.currentLevel, 5);
        expect(games.first.lastPlayed, now);
        expect(games.last, savedGame('b'));
      });

      test('never lowers the current level', () async {
        await repository.add(savedGame('a', currentLevel: 8));

        final games = await repository.update(savedGame('a', currentLevel: 3));

        expect(games.single.currentLevel, 8);
        expect(games.single.lastPlayed, now);
      });

      test('ignores unknown ids', () async {
        await repository.add(savedGame('a'));

        final games = await repository.update(
          savedGame('zzz', currentLevel: 9),
        );

        expect(games, [savedGame('a')]);
      });
    });

    test('deletes by id', () async {
      await repository.add(savedGame('a'));
      await repository.add(savedGame('b'));

      final games = await repository.delete('a');

      expect(games.map((g) => g.id), ['b']);
      expect((await repository.loadAll()).map((g) => g.id), ['b']);
    });

    test('defaults to the system clock', () async {
      final repository = SavegameRepository(store);
      await repository.add(savedGame('a'));
      final before = DateTime.now();

      final games = await repository.update(savedGame('a'));

      expect(games.single.lastPlayed.isBefore(before), isFalse);
    });
  });
}
