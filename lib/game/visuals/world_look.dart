import 'package:equatable/equatable.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart';

/// The biomes, in the order the worlds cycle through them (game-visuals
/// spec).
enum Biome { nightForest, desertDusk, snowyPeaks, crystalCaves, volcano }

/// A biome's colors: sky, terrain, backdrop silhouettes from far to near,
/// and its accent and ambient particles (design D2).
class BiomePalette extends Equatable {
  const new({
    required this.skyTop,
    required this.skyBottom,
    required this.surface,
    required this.surfaceShade,
    required this.body,
    required this.bodyShade,
    required this.bodyDetail,
    required this.silhouettes,
    required this.accent,
    required this.particle,
  });

  final Color skyTop;
  final Color skyBottom;
  final Color surface;
  final Color surfaceShade;
  final Color body;
  final Color bodyShade;
  final Color bodyDetail;

  /// Backdrop silhouettes, from the farthest to the nearest.
  final List<Color> silhouettes;
  final Color accent;
  final Color particle;

  /// Every color, for contrast checks.
  List<Color> get all => [
    skyTop,
    skyBottom,
    surface,
    surfaceShade,
    body,
    bodyShade,
    bodyDetail,
    ...silhouettes,
  ];

  /// The palette with every color's hue turned by [hue] degrees and its
  /// lightness moved by [lightness], and the sky tinted towards [skyTint].
  BiomePalette shifted({
    required double hue,
    required double lightness,
    Color? skyTint,
  }) {
    Color shift(Color color) {
      final hsl = HSLColor.fromColor(color);
      return hsl
          .withHue((hsl.hue + hue) % 360)
          .withLightness((hsl.lightness + lightness).clamp(0, 1))
          .toColor();
    }

    Color sky(Color color) {
      final shifted = shift(color);
      return skyTint == null ? shifted : Color.lerp(shifted, skyTint, 0.35)!;
    }

    return BiomePalette(
      skyTop: sky(skyTop),
      skyBottom: sky(skyBottom),
      surface: shift(surface),
      surfaceShade: shift(surfaceShade),
      body: shift(body),
      bodyShade: shift(bodyShade),
      bodyDetail: shift(bodyDetail),
      silhouettes: [for (final color in silhouettes) shift(color)],
      accent: shift(accent),
      particle: shift(particle),
    );
  }

  @override
  List<Object> get props => [
    skyTop,
    skyBottom,
    surface,
    surfaceShade,
    body,
    bodyShade,
    bodyDetail,
    silhouettes,
    accent,
    particle,
  ];

  /// The reference palette of each biome.
  static const Map<Biome, BiomePalette> reference = {
    Biome.nightForest: BiomePalette(
      skyTop: Color(0xFF0B1033),
      skyBottom: Color(0xFF2A2F6B),
      surface: Color(0xFF4CAF50),
      surfaceShade: Color(0xFF22662C),
      body: Color(0xFF5A3B26),
      bodyShade: Color(0xFF3B2516),
      bodyDetail: Color(0xFF8A6142),
      silhouettes: [Color(0xFF1C2452), Color(0xFF141A3C), Color(0xFF0C1028)],
      accent: Color(0xFF8FE3FF),
      particle: Color(0xFFE9FF8A),
    ),
    Biome.desertDusk: BiomePalette(
      skyTop: Color(0xFF3B1D5C),
      skyBottom: Color(0xFFF59A5C),
      surface: Color(0xFFF2C27B),
      surfaceShade: Color(0xFFC98E4B),
      body: Color(0xFFC46B3A),
      bodyShade: Color(0xFF8C4423),
      bodyDetail: Color(0xFFE59A60),
      silhouettes: [Color(0xFFB0607A), Color(0xFF7E3F5E), Color(0xFF4E2440)],
      accent: Color(0xFFFFD38A),
      particle: Color(0xFFFFE2B0),
    ),
    Biome.snowyPeaks: BiomePalette(
      skyTop: Color(0xFF3F6DAA),
      skyBottom: Color(0xFFCFE4F5),
      surface: Color(0xFFF4FAFF),
      surfaceShade: Color(0xFFB9D3EA),
      body: Color(0xFF6F7F92),
      bodyShade: Color(0xFF46525F),
      bodyDetail: Color(0xFFA3B1C1),
      silhouettes: [Color(0xFF9DB6D3), Color(0xFF6F8FB3), Color(0xFF2F4A5E)],
      accent: Color(0xFFFFFFFF),
      particle: Color(0xFFFFFFFF),
    ),
    Biome.crystalCaves: BiomePalette(
      skyTop: Color(0xFF0A0A1A),
      skyBottom: Color(0xFF241A3D),
      surface: Color(0xFF6EE7A8),
      surfaceShade: Color(0xFF2E9A6A),
      body: Color(0xFF3A2C55),
      bodyShade: Color(0xFF22193A),
      bodyDetail: Color(0xFF8E7BD6),
      silhouettes: [Color(0xFF2C2350), Color(0xFF1D1738), Color(0xFF120E24)],
      accent: Color(0xFFB9A8FF),
      particle: Color(0xFFE6DDFF),
    ),
    Biome.volcano: BiomePalette(
      skyTop: Color(0xFF1A0B0B),
      skyBottom: Color(0xFF6B1E12),
      surface: Color(0xFF5A4842),
      surfaceShade: Color(0xFF2A201D),
      body: Color(0xFF2B2523),
      bodyShade: Color(0xFF171312),
      bodyDetail: Color(0xFFFF6A1F),
      silhouettes: [Color(0xFF5A1F1A), Color(0xFF3A1512), Color(0xFF1E0C0A)],
      accent: Color(0xFFFF9A3C),
      particle: Color(0xFFFFB347),
    ),
  };
}

/// Sky tints a variant may add: dawn and dusk light.
const List<Color?> _skyTints = [null, Color(0xFFFFB38A), Color(0xFF7A5CFF)];

/// How a world looks: its biome, and the variation drawn from the seed
/// (design D1). The same for a seed and level on every platform.
class WorldLook extends Equatable {
  const new({
    required this.world,
    required this.biome,
    required this.variant,
    required this.palette,
  });

  /// The look of [level] (from 1) of [seed].
  factory forLevel(String seed, int level) {
    final world = (level - 1) ~/ levelsPerWorld;
    final biome = Biome.values[world % Biome.values.length];
    final reference = BiomePalette.reference[biome]!;
    // The first cycle shows every biome as designed.
    if (world < Biome.values.length) {
      return WorldLook(
        world: world,
        biome: biome,
        variant: 0,
        palette: reference,
      );
    }
    final random = Mulberry32(fnv1a32('$seed/world/$world'));
    final hue = random.intIn(-20, 20).toDouble();
    final lightness = random.intIn(-8, 8) / 100;
    final skyTint = _skyTints[random.intIn(0, _skyTints.length - 1)];
    return WorldLook(
      world: world,
      biome: biome,
      // Never 0, which marks the reference look.
      variant: random.nextUint32() | 1,
      palette: reference.shifted(
        hue: hue,
        lightness: lightness,
        skyTint: skyTint,
      ),
    );
  }

  /// Levels per world.
  static const levelsPerWorld = 10;

  /// The world, from 0.
  final int world;
  final Biome biome;

  /// 0 for the reference look; otherwise the seed of this world's textures,
  /// silhouettes and particles.
  final int variant;
  final BiomePalette palette;

  /// Whether [level] (from 1) starts a world.
  static bool startsWorld(int level) => (level - 1) % levelsPerWorld == 0;

  @override
  List<Object> get props => [world, biome, variant, palette];
}
