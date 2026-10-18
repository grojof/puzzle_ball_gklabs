import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_textures.dart';
import 'package:puzzle_ball_gklabs/game/visuals/world_look.dart';

/// The mean color difference between columns [a] and [b] of [pixels].
double _columnDifference(
  List<int> pixels,
  int width,
  int height,
  int a,
  int b,
) {
  var total = 0;
  for (var y = 0; y < height; y++) {
    for (var c = 0; c < 4; c++) {
      total +=
          (pixels[(y * width + a) * 4 + c] - pixels[(y * width + b) * 4 + c])
              .abs();
    }
  }
  return total / (height * 4);
}

/// Whether [image] wraps horizontally: the jump from its last column to its
/// first is no bigger than between neighboring columns inside it.
Future<void> _expectWraps(ui.Image image) async {
  final bytes = await image.toByteData();
  final pixels = bytes!.buffer.asUint8List();
  final width = image.width;
  final height = image.height;
  var inside = 0.0;
  for (var x = 1; x < width; x++) {
    inside += _columnDifference(pixels, width, height, x - 1, x);
  }
  inside /= width - 1;
  final seam = _columnDifference(pixels, width, height, width - 1, 0);
  expect(seam, lessThanOrEqualTo(inside * 3 + 1));
}

void main() {
  group('TerrainTextures', () {
    for (final level in [1, 11, 21, 31, 41, 51]) {
      test('level $level has seamless textures of the right size', () async {
        final look = WorldLook.forLevel('textures', level);
        final textures = await TerrainTextures.generate(look);
        expect(textures.body.width, TerrainTextures.size);
        expect(textures.body.height, TerrainTextures.size);
        expect(textures.surface.width, TerrainTextures.size);
        expect(textures.surface.height, TerrainTextures.surfaceHeight);
        await _expectWraps(textures.body);
        await _expectWraps(textures.surface);
        textures.dispose();
      });
    }
  });

  group('TerrainTextureCache', () {
    test('reuses a look and keeps only the last two', () async {
      final cache = TerrainTextureCache();
      final forest = WorldLook.forLevel('cache', 1);
      final desert = WorldLook.forLevel('cache', 11);
      final snow = WorldLook.forLevel('cache', 21);

      final first = cache.get(forest);
      expect(cache.get(forest), same(first));
      await first;
      await cache.get(desert);
      await cache.get(snow);
      expect(cache.get(forest), isNot(same(first)));
      await cache.get(forest);
      cache.clear();
    });
  });
}
