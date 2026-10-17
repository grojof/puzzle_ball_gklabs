import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_generator.dart';

/// Generates level [level] of a savegame with [totalLevels] levels, on
/// demand, so a session never builds levels it does not play.
///
/// The difficulty curve is the baseline one; the next change replaces it.
LevelData predefinedLevel(int level, int totalLevels) {
  final t = level / totalLevels * 10;
  return LevelGenerator.generate(
    level,
    segmentCount: 20 + (t * 60).toInt(),
    maxFlatSegmentLength: 3 + (t * 3).toInt(),
    flatSegmentChance: (1.0 - t) * 0.6 + 0.2,
    maxHorizontalGap: 0.5 + t * 2.0,
    dropChance: 0.1 + t * 0.3,
    maxDropHeight: 1.5 + t * 1.5,
    maxHeightChange: 1.0 + t * 2.5,
    heightVariationChance: 0.2 + t * 0.5,
  );
}
