import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/visuals/world_look.dart';

void main() {
  group('WorldLook', () {
    test('groups ten levels per world and cycles the biomes', () {
      Biome biomeOf(int level) => WorldLook.forLevel('seed', level).biome;
      expect(biomeOf(1), Biome.nightForest);
      expect(biomeOf(10), Biome.nightForest);
      expect(biomeOf(11), Biome.desertDusk);
      expect(biomeOf(21), Biome.snowyPeaks);
      expect(biomeOf(31), Biome.crystalCaves);
      expect(biomeOf(41), Biome.volcano);
      expect(biomeOf(51), Biome.nightForest);
      expect(WorldLook.forLevel('seed', 51).world, 5);
    });

    test('shows the reference look in the first cycle', () {
      for (final level in [1, 15, 49]) {
        final look = WorldLook.forLevel('seed', level);
        expect(look.variant, 0);
        expect(look.palette, BiomePalette.reference[look.biome]);
      }
    });

    test('varies the repeats by seed and world', () {
      final first = WorldLook.forLevel('seed', 1);
      final repeat = WorldLook.forLevel('seed', 51);
      expect(repeat.biome, first.biome);
      expect(repeat.variant, isNot(0));
      expect(repeat.palette, isNot(first.palette));
      expect(WorldLook.forLevel('other', 51).variant, isNot(repeat.variant));
      expect(WorldLook.forLevel('seed', 101).variant, isNot(repeat.variant));
    });

    test('is the same for the same seed and level', () {
      expect(WorldLook.forLevel('abc', 157), WorldLook.forLevel('abc', 157));
    });

    test('knows the first level of each world', () {
      expect(WorldLook.startsWorld(1), isTrue);
      expect(WorldLook.startsWorld(11), isTrue);
      expect(WorldLook.startsWorld(12), isFalse);
    });
  });

  group('BiomePalette', () {
    test('shifts hue and lightness and tints the sky', () {
      const palette = BiomePalette(
        skyTop: Color(0xFF0000FF),
        skyBottom: Color(0xFF0000FF),
        surface: Color(0xFFFF0000),
        surfaceShade: Color(0xFFFF0000),
        body: Color(0xFFFF0000),
        bodyShade: Color(0xFFFF0000),
        bodyDetail: Color(0xFFFF0000),
        silhouettes: [Color(0xFFFF0000)],
        accent: Color(0xFFFF0000),
        particle: Color(0xFFFF0000),
      );
      final shifted = palette.shifted(
        hue: 120,
        lightness: 0,
        skyTint: const Color(0xFFFFFFFF),
      );
      expect(HSLColor.fromColor(shifted.surface).hue, closeTo(120, 1));
      expect(shifted.skyTop, isNot(palette.skyTop));
      expect(palette.all, hasLength(8));
    });
  });
}
