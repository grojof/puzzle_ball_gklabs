import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'savegame_state.dart';

class SavegameCubit extends Cubit<SavegameState> {
  SavegameCubit() : super(const SavegameState.initial()) {
    loadGames();
  }

  static const _key = 'savedGames';

  Future<void> loadGames() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final games = list
        .map((e) => SavedGame.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    emit(state.copyWith(games: games));
  }

  Future<void> addGame(SavedGame game) async {
    final games = List<SavedGame>.from(state.games)..add(game);
    await _saveGames(games);
  }

  Future<void> updateGame(SavedGame updated) async {
    final games =
        state.games.map((g) => g.id == updated.id ? updated : g).toList();
    await _saveGames(games);
  }

  Future<void> deleteGame(String id) async {
    final games = state.games.where((g) => g.id != id).toList();
    await _saveGames(games);
  }

  Future<void> _saveGames(List<SavedGame> games) async {
    final prefs = await SharedPreferences.getInstance();
    final list = games.map((g) => jsonEncode(g.toJson())).toList();
    await prefs.setStringList(_key, list);
    emit(state.copyWith(games: games));
  }
}

class SavedGame extends Equatable {
  const SavedGame({
    required this.id,
    required this.seed,
    required this.totalLevels,
    required this.currentLevel,
    required this.createdAt,
    required this.lastPlayed,
  });

  SavedGame.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        seed = json['seed'] as String,
        totalLevels = json['totalLevels'] as int,
        currentLevel = json['currentLevel'] as int,
        createdAt = DateTime.parse(json['createdAt'] as String),
        lastPlayed = DateTime.parse(json['lastPlayed'] as String);

  final String id;
  final String seed;
  final int totalLevels;
  final int currentLevel;
  final DateTime createdAt;
  final DateTime lastPlayed;

  Map<String, dynamic> toJson() => {
        'id': id,
        'seed': seed,
        'totalLevels': totalLevels,
        'currentLevel': currentLevel,
        'createdAt': createdAt.toIso8601String(),
        'lastPlayed': lastPlayed.toIso8601String(),
      };

  @override
  List<Object> get props =>
      [id, seed, totalLevels, currentLevel, createdAt, lastPlayed];
}
