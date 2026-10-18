import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/visuals/biome_backdrop.dart';
import 'package:puzzle_ball_gklabs/game/visuals/world_look.dart';

void main() {
  group('BiomeBackdrop', () {
    // The generated biomes of the first cycle, and a repeat with a variant.
    for (final level in [11, 21, 31, 41, 61]) {
      final look = WorldLook.forLevel('backdrop', level);
      test('builds and draws the ${look.biome.name} backdrop', () {
        var cameraX = 0.0;
        final backdrop = BiomeBackdrop(look: look, cameraX: () => cameraX)
          ..onGameResize(Vector2(800, 360));
        expect(backdrop.layers, hasLength(3));
        backdrop.render(Canvas(PictureRecorder()));

        // The far layers move less than the near ones.
        final before = [for (var i = 0; i < 3; i++) backdrop.offsetOf(i)];
        cameraX = 1;
        final moved = [
          for (var i = 0; i < 3; i++)
            (before[i] - backdrop.offsetOf(i)) %
                (800 * BiomeBackdrop.layerWidths),
        ];
        expect(moved[0], lessThan(moved[1]));
        expect(moved[1], lessThan(moved[2]));
        backdrop.onRemove();
      });
    }

    test('is not used for the painted forest', () {
      expect(
        () => BiomeBackdrop(
          look: WorldLook.forLevel('backdrop', 1),
          cameraX: () => 0,
        ),
        throwsAssertionError,
      );
    });
  });

  group('ParticleField', () {
    for (final style in ParticleStyle.values) {
      test('${style.name} stay on screen and draw', () {
        final field = ParticleField(
          style: style,
          color: const Color(0xFFFFFFFF),
          seed: 7,
        )..onGameResize(Vector2(800, 360));
        expect(field.particles, hasLength(ParticleField.maxParticles));
        for (var i = 0; i < 600; i++) {
          field.update(1 / 60);
        }
        for (final particle in field.particles) {
          expect(particle.x, inInclusiveRange(0, 1));
          expect(particle.y, inInclusiveRange(0, 1));
        }
        field.render(Canvas(PictureRecorder()));
      });
    }

    test('styles follow the biome', () {
      expect(ParticleField.styleOf(Biome.snowyPeaks), ParticleStyle.snow);
      expect(ParticleField.styleOf(Biome.volcano), ParticleStyle.embers);
    });
  });

  test('ScreenTint covers the screen', () {
    ScreenTint(const Color(0xFF336699))
      ..onGameResize(Vector2(100, 50))
      ..render(Canvas(PictureRecorder()));
  });
}
