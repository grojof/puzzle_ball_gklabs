part of 'savegame_cubit.dart';

class SavegameState extends Equatable {
  const new({required this.games});

  const new initial() : games = const [];

  final List<SavedGame> games;

  SavegameState copyWith({List<SavedGame>? games}) {
    return SavegameState(games: games ?? this.games);
  }

  @override
  List<Object> get props => [games];
}
