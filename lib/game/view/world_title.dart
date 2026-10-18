import 'package:puzzle_ball_gklabs/game/visuals/world_look.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';

/// "World N · biome", shown under the level label when [level] (from 1) of
/// [seed] starts a world; null otherwise (game-visuals spec).
String? worldTitle(AppLocalizations l10n, String seed, int level) {
  if (!WorldLook.startsWorld(level)) return null;
  final look = WorldLook.forLevel(seed, level);
  final biome = switch (look.biome) {
    Biome.nightForest => l10n.biomeNightForest,
    Biome.desertDusk => l10n.biomeDesertDusk,
    Biome.snowyPeaks => l10n.biomeSnowyPeaks,
    Biome.crystalCaves => l10n.biomeCrystalCaves,
    Biome.volcano => l10n.biomeVolcano,
  };
  return '${l10n.labelWorld(look.world + 1)} · $biome';
}
