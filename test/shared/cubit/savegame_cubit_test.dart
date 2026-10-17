import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_value_store/key_value_store.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/cubit.dart';
import 'package:savegame_repository/savegame_repository.dart';

SavedGame game(String id, {int level = 1, int day = 1}) => SavedGame(
  id: id,
  seed: 'seed-$id',
  totalLevels: 10,
  currentLevel: level,
  createdAt: DateTime(2026, 10, day),
  lastPlayed: DateTime(2026, 10, day),
);

void main() {
  late SavegameRepository repository;

  setUp(() {
    repository = SavegameRepository(
      InMemoryKeyValueStore(),
      now: () => DateTime(2026, 10, 20),
    );
  });

  group('SavegameCubit', () {
    blocTest<SavegameCubit, SavegameState>(
      'loads, adds and deletes savegames',
      build: () => SavegameCubit(repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.add(game('a'));
        await cubit.delete('a');
      },
      expect: () => [
        const SavegameState(isLoaded: true),
        SavegameState(games: [game('a')], isLoaded: true),
        const SavegameState(isLoaded: true),
      ],
    );

    blocTest<SavegameCubit, SavegameState>(
      'records progress that never goes back',
      setUp: () => repository.add(game('a', level: 3)),
      build: () => SavegameCubit(repository),
      act: (cubit) async {
        await cubit.load();
        await cubit.recordProgress('a', 5);
        await cubit.recordProgress('a', 2);
        await cubit.recordProgress('missing', 9);
      },
      skip: 1,
      verify: (cubit) {
        expect(cubit.state.byId('a')!.currentLevel, 5);
        expect(cubit.state.byId('a')!.lastPlayed, DateTime(2026, 10, 20));
        expect(cubit.state.byId('missing'), isNull);
      },
    );
  });

  group('SavegameState', () {
    test('lastPlayed is the most recent savegame, or null', () {
      expect(const SavegameState().lastPlayed, isNull);
      final state = SavegameState(
        games: [game('a', day: 2), game('b', day: 5), game('c', day: 3)],
      );
      expect(state.lastPlayed!.id, 'b');
    });
  });
}
