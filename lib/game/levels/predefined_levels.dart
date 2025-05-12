import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_generator.dart';

final predefinedLevels = List<LevelData>.generate(
  20,
  (index) => LevelGenerator.generate(index + 1),
);
