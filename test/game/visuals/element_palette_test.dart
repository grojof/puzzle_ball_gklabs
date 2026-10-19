import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart' show BoostType;
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';
import 'package:puzzle_ball_gklabs/game/visuals/world_look.dart';

void main() {
  group('ElementPalette', () {
    test('each element stands out against every biome', () {
      // An element's fill, dark outline or light rim contrasts with every
      // color: the fill or rim against dark scenes, the outline against
      // light ones, the rim against mid tones.
      const fills = [
        ElementPalette.jump,
        ElementPalette.speed,
        ElementPalette.gravity,
        ElementPalette.checkpointIdle,
        ElementPalette.checkpointActive,
        ElementPalette.portal,
        ElementPalette.orb,
        ElementPalette.hazard,
        ElementPalette.trampoline,
        ElementPalette.beltMark,
        ElementPalette.ice,
        ElementPalette.mud,
        ElementPalette.track,
        ElementPalette.rush,
      ];
      for (final palette in BiomePalette.reference.values) {
        for (final background in palette.all) {
          for (final fill in fills) {
            final best = [
              ElementPalette.contrast(fill, background),
              ElementPalette.contrast(ElementPalette.outline, background),
              ElementPalette.contrast(ElementPalette.rim, background),
            ].reduce(math.max);
            expect(
              best,
              greaterThanOrEqualTo(3),
              reason: '$fill on $background',
            );
          }
        }
      }
    });

    test('boost hues are at least 60 degrees apart', () {
      final hues = [
        for (final type in BoostType.values)
          HSLColor.fromColor(ElementPalette.boost(type)).hue,
      ];
      for (var i = 0; i < hues.length; i++) {
        for (var j = i + 1; j < hues.length; j++) {
          final apart = (hues[i] - hues[j]).abs() % 360;
          expect(math.min(apart, 360 - apart), greaterThanOrEqualTo(60));
        }
      }
    });

    test('contrast follows the WCAG formula', () {
      expect(
        ElementPalette.contrast(
          const Color(0xFF000000),
          const Color(0xFFFFFFFF),
        ),
        closeTo(21, 0.01),
      );
      expect(ElementPalette.memory.a, lessThan(1));
      expect(ElementPalette.hazard, isNot(ElementPalette.logicA));
      expect(ElementPalette.logicB, isNot(ElementPalette.gravity));
    });
  });
}
