import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_generator.dart';

const int totalLevels = 100;

final predefinedLevels = List<LevelData>.generate(
  totalLevels,
  (index) {
    final level = index + 1;

    // 📈 Progresión de dificultad normalizada (0.0 → 1.0)
    final t = level / totalLevels;

    return LevelGenerator.generate(
      level,
      segmentCount: 20 + (t * 60).toInt(), // longitud total
      maxFlatSegmentLength: 3 + (t * 3).toInt(), // más largos al inicio
      flatSegmentChance: (1.0 - t) * 0.6 + 0.2, // menos descanso al avanzar
      maxHorizontalGap: 0.5 + t * 2.0, // mayor separación
      dropChance: 0.1 + t * 0.3, // más saltos
      maxDropHeight: 1.5 + t * 1.5, // saltos más peligrosos
      maxHeightChange: 1.0 + t * 2.5, // subidas/bajadas más intensas
      heightVariationChance: 0.2 + t * 0.5, // más variaciones verticales
    );
  },
);
