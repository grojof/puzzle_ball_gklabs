part of 'savegame_cubit.dart';

class SavegameState extends Equatable {
  const new({this.games = const [], this.isLoaded = false});

  final List<SavedGame> games;

  /// Whether the stored savegames have been read.
  final bool isLoaded;

  /// The savegame with [id], or null when there is none.
  SavedGame? byId(String id) {
    for (final game in games) {
      if (game.id == id) return game;
    }
    return null;
  }

  /// The most recently played savegame, or null when there are none.
  SavedGame? get lastPlayed {
    SavedGame? latest;
    for (final game in games) {
      if (latest == null || game.lastPlayed.isAfter(latest.lastPlayed)) {
        latest = game;
      }
    }
    return latest;
  }

  SavegameState copyWith({List<SavedGame>? games}) =>
      SavegameState(games: games ?? this.games, isLoaded: isLoaded);

  @override
  List<Object> get props => [games, isLoaded];
}
