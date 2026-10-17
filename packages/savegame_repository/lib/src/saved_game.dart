import 'package:meta/meta.dart';

/// A savegame: a seed, how many levels it has and how far the player got.
@immutable
class SavedGame {
  /// Creates a savegame.
  const new({
    required this.id,
    required this.seed,
    required this.totalLevels,
    required this.currentLevel,
    required this.createdAt,
    required this.lastPlayed,
  });

  /// Reads a savegame from its stored JSON form.
  ///
  /// Throws a [TypeError] or [FormatException] when a field is missing or
  /// malformed.
  new fromJson(Map<String, dynamic> json)
    : id = json['id'] as String,
      seed = json['seed'] as String,
      totalLevels = json['totalLevels'] as int,
      currentLevel = json['currentLevel'] as int,
      createdAt = DateTime.parse(json['createdAt'] as String),
      lastPlayed = DateTime.parse(json['lastPlayed'] as String);

  /// Unique identifier.
  final String id;

  /// The seed the levels are generated from.
  final String seed;

  /// How many levels the savegame has.
  final int totalLevels;

  /// The furthest level unlocked, starting at 1.
  final int currentLevel;

  /// When the savegame was created.
  final DateTime createdAt;

  /// When the savegame was last played.
  final DateTime lastPlayed;

  /// The stored JSON form, compatible with earlier versions of the game.
  Map<String, dynamic> toJson() => {
    'id': id,
    'seed': seed,
    'totalLevels': totalLevels,
    'currentLevel': currentLevel,
    'createdAt': createdAt.toIso8601String(),
    'lastPlayed': lastPlayed.toIso8601String(),
  };

  /// A copy with the given fields replaced.
  SavedGame copyWith({int? currentLevel, DateTime? lastPlayed}) => SavedGame(
    id: id,
    seed: seed,
    totalLevels: totalLevels,
    currentLevel: currentLevel ?? this.currentLevel,
    createdAt: createdAt,
    lastPlayed: lastPlayed ?? this.lastPlayed,
  );

  @override
  bool operator ==(Object other) =>
      other is SavedGame &&
      other.id == id &&
      other.seed == seed &&
      other.totalLevels == totalLevels &&
      other.currentLevel == currentLevel &&
      other.createdAt == createdAt &&
      other.lastPlayed == lastPlayed;

  @override
  int get hashCode =>
      Object.hash(id, seed, totalLevels, currentLevel, createdAt, lastPlayed);

  @override
  String toString() => 'SavedGame($id, level $currentLevel/$totalLevels)';
}
