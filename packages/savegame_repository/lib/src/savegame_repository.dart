import 'dart:convert';

import 'package:key_value_store/key_value_store.dart';
import 'package:savegame_repository/src/saved_game.dart';

/// Lists, adds, updates and deletes [SavedGame]s in a [KeyValueStore].
///
/// Savegames are stored as a list of JSON strings under [storageKey], the
/// format earlier versions of the game used. Entries that cannot be read are
/// skipped.
class SavegameRepository {
  /// Creates a repository backed by the given store, using the `now` clock for
  /// timestamps.
  new(this._store, {this._now = DateTime.now});

  final KeyValueStore _store;
  final DateTime Function() _now;

  /// The key the savegames are stored under.
  static const storageKey = 'savedGames';

  /// Every readable savegame, in stored order.
  Future<List<SavedGame>> loadAll() async {
    final stored = await _store.getStringList(storageKey) ?? const [];
    return [for (final entry in stored) ?_tryParse(entry)];
  }

  /// Appends [game] and returns the updated list.
  Future<List<SavedGame>> add(SavedGame game) async {
    final games = [...await loadAll(), game];
    await _saveAll(games);
    return games;
  }

  /// Records progress in the savegame with the id of [updated] and returns
  /// the updated list.
  ///
  /// The current level never goes back, and the last-played time is always
  /// set to now. Unknown ids leave the list unchanged.
  Future<List<SavedGame>> update(SavedGame updated) async {
    final games = [
      for (final game in await loadAll())
        if (game.id == updated.id)
          game.copyWith(
            currentLevel: updated.currentLevel > game.currentLevel
                ? updated.currentLevel
                : game.currentLevel,
            lastPlayed: _now(),
          )
        else
          game,
    ];
    await _saveAll(games);
    return games;
  }

  /// Deletes the savegame with [id] and returns the updated list.
  Future<List<SavedGame>> delete(String id) async {
    final games = [
      for (final game in await loadAll())
        if (game.id != id) game,
    ];
    await _saveAll(games);
    return games;
  }

  Future<void> _saveAll(List<SavedGame> games) => _store.setStringList(
    storageKey,
    [for (final game in games) jsonEncode(game.toJson())],
  );

  static SavedGame? _tryParse(String entry) {
    final Object? json;
    try {
      json = jsonDecode(entry);
    } on FormatException {
      return null;
    }
    if (json case {
      'id': final String id,
      'seed': final String seed,
      'totalLevels': final int totalLevels,
      'currentLevel': final int currentLevel,
      'createdAt': final String createdAt,
      'lastPlayed': final String lastPlayed,
    }) {
      final created = DateTime.tryParse(createdAt);
      final played = DateTime.tryParse(lastPlayed);
      if (created == null || played == null) return null;
      return SavedGame(
        id: id,
        seed: seed,
        totalLevels: totalLevels,
        currentLevel: currentLevel,
        createdAt: created,
        lastPlayed: played,
      );
    }
    return null;
  }
}
