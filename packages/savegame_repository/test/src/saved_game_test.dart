import 'package:savegame_repository/savegame_repository.dart';
import 'package:test/test.dart';

void main() {
  final game = SavedGame(
    id: '1',
    seed: '42',
    totalLevels: 50,
    currentLevel: 3,
    createdAt: DateTime(2026, 10, 1, 12),
    lastPlayed: DateTime(2026, 10, 2, 18, 30),
  );

  group(SavedGame, () {
    test('round-trips through JSON in the legacy format', () {
      final json = game.toJson();

      expect(json, {
        'id': '1',
        'seed': '42',
        'totalLevels': 50,
        'currentLevel': 3,
        'createdAt': '2026-10-01T12:00:00.000',
        'lastPlayed': '2026-10-02T18:30:00.000',
      });
      expect(SavedGame.fromJson(json), game);
    });

    test('copyWith replaces progress fields only', () {
      final later = DateTime(2026, 10, 3);
      final copy = game.copyWith(currentLevel: 4, lastPlayed: later);

      expect(copy.currentLevel, 4);
      expect(copy.lastPlayed, later);
      expect(copy.id, game.id);
      expect(copy.createdAt, game.createdAt);
      expect(game.copyWith(), game);
    });

    test('compares by value', () {
      expect(SavedGame.fromJson(game.toJson()).hashCode, game.hashCode);
      expect(game.copyWith(currentLevel: 9), isNot(game));
    });

    test('describes itself', () {
      expect(game.toString(), 'SavedGame(1, level 3/50)');
    });
  });
}
