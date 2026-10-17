import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:savegame_repository/savegame_repository.dart';

export 'package:savegame_repository/savegame_repository.dart' show SavedGame;

part 'savegame_state.dart';

/// The stored savegames, kept in sync with the repository.
class SavegameCubit extends Cubit<SavegameState> {
  new(this._repository) : super(const SavegameState());

  final SavegameRepository _repository;

  Future<void> load() async =>
      emit(SavegameState(games: await _repository.loadAll(), isLoaded: true));

  Future<void> add(SavedGame game) async =>
      emit(state.copyWith(games: await _repository.add(game)));

  /// Records that [level] was reached; progress never goes back.
  Future<void> recordProgress(String id, int level) async {
    final game = state.byId(id);
    if (game == null) return;
    final games = await _repository.update(game.copyWith(currentLevel: level));
    emit(state.copyWith(games: games));
  }

  Future<void> delete(String id) async =>
      emit(state.copyWith(games: await _repository.delete(id)));
}
