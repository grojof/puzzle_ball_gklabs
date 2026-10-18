import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/game/visuals/world_look.dart';

/// A world's terrain textures, generated once when a level loads and drawn
/// with repeating image shaders (design D3).
///
/// [body] repeats in both directions; [surface] repeats horizontally and is
/// drawn along the top of floors and ramps, with its top [overhangFraction]
/// rising above the ground line (grass blades, snow bumps).
class TerrainTextures {
  new _(this.body, this.surface);

  /// Width and height of [body], and width of [surface], in pixels: two
  /// tiles, 3 m, so the pattern repeats only every 3 m.
  static const size = 512;

  /// Texture pixels per meter.
  static const double pixelsPerMeter = 256 / 1.5;

  /// Height of [surface] in pixels: 0.375 m.
  static const surfaceHeight = 64;

  /// The part of [surface] above the ground line.
  static const overhangFraction = 0.25;

  final ui.Image body;
  final ui.Image surface;

  /// Draws the textures of [look].
  static Future<TerrainTextures> generate(WorldLook look) async {
    final seed = fnv1a32('${look.biome.name}/${look.variant}');
    final palette = look.palette;
    final body = await _render(size, size, (canvas) {
      _Body(canvas, palette, Mulberry32(seed)).paint(look.biome);
    });
    final surface = await _render(size, surfaceHeight, (canvas) {
      _Surface(
        canvas,
        palette,
        Mulberry32(seed ^ 0x5bd1e995),
      ).paint(look.biome);
    });
    return TerrainTextures._(body, surface);
  }

  static Future<ui.Image> _render(
    int width,
    int height,
    void Function(Canvas canvas) paint,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    );
    paint(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return image;
  }

  void dispose() {
    body.dispose();
    surface.dispose();
  }
}

/// Keeps the textures of the last two looks, so moving between levels of a
/// world, or back and forth across a world's edge, pays nothing.
class TerrainTextureCache {
  final _entries = <WorldLook, Future<TerrainTextures>>{};

  /// The textures of [look], generated on first use.
  Future<TerrainTextures> get(WorldLook look) {
    final cached = _entries.remove(look);
    final textures = cached ?? TerrainTextures.generate(look);
    _entries[look] = textures;
    while (_entries.length > 2) {
      final oldest = _entries.keys.first;
      unawaitedDispose(_entries.remove(oldest)!);
    }
    return textures;
  }

  /// Releases every texture.
  void clear() {
    _entries.values.forEach(unawaitedDispose);
    _entries.clear();
  }

  static void unawaitedDispose(Future<TerrainTextures> textures) {
    textures.then((t) => t.dispose()).ignore();
  }
}

const double _size = TerrainTextures.size * 1.0;

/// How many 256 px tiles fit across a texture: recipes scale their counts
/// by it, so features keep their size.
const int _tiles = TerrainTextures.size ~/ 256;

/// [count] features per 256 × 256 px, for the whole body texture.
int _perBody(int count) => count * _tiles * _tiles;

/// [count] features per 256 px of width, for the whole surface strip.
int _perStrip(int count) => count * _tiles;

/// Shared helpers for drawing seamless shapes.
abstract class _Painter {
  new(this.canvas, this.palette, this.random);

  final Canvas canvas;
  final BiomePalette palette;
  final Mulberry32 random;

  /// Draws [draw] at [x] and, near the edges, again one tile left or right
  /// (and up or down when [wrapY]), so the texture repeats seamlessly.
  void wrapped(
    double x,
    double y,
    double reach,
    void Function(double x, double y) draw, {
    double height = _size,
    bool wrapY = false,
  }) {
    for (final dx in [-_size, 0.0, _size]) {
      if (x + dx < -reach || x + dx > _size + reach) continue;
      for (final dy in wrapY ? [-height, 0.0, height] : [0.0]) {
        if (y + dy < -reach || y + dy > height + reach) continue;
        draw(x + dx, y + dy);
      }
    }
  }

  /// A height profile across the tile that repeats seamlessly: a sum of
  /// sines with whole numbers of periods per tile.
  double Function(double x) wave(double amplitude) {
    final harmonics = [
      for (var j = 1; j <= 4; j++)
        (
          j * _tiles,
          random.range(0, 2 * math.pi),
          amplitude / j * random.range(0.5, 1),
        ),
    ];
    return (x) {
      var y = 0.0;
      for (final (k, phase, a) in harmonics) {
        y += a * math.sin(2 * math.pi * k * x / _size + phase);
      }
      return y;
    };
  }

  /// Soft blotches of [colors] for depth.
  void blotches(List<Color> colors, int count, {double height = _size}) {
    for (var i = 0; i < count; i++) {
      final radius = random.range(18, 56);
      final color = colors[i % colors.length];
      final paint = Paint()
        ..color = color.withValues(alpha: random.range(0.10, 0.22))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius / 3);
      wrapped(
        random.range(0, _size),
        random.range(0, height),
        radius * 1.5,
        (x, y) => canvas.drawCircle(Offset(x, y), radius, paint),
        height: height,
        wrapY: height == _size,
      );
    }
  }

  /// A pebble or stone with a highlight at the top left.
  void stone(double x, double y, double radius, Color color) {
    final rect = Rect.fromCenter(
      center: Offset(x, y),
      width: radius * 2,
      height: radius * random.range(1.1, 1.6),
    );
    canvas
      ..drawOval(
        rect.shift(const Offset(1.5, 2)),
        Paint()..color = const Color(0x55000000),
      )
      ..drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.4, -0.5),
            colors: [Color.lerp(color, const Color(0xFFFFFFFF), 0.35)!, color],
          ).createShader(rect),
      );
  }
}

/// The body texture: what lies below the surface.
class _Body extends _Painter {
  new(super.canvas, super.palette, super.random);

  void paint(Biome biome) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _size, _size),
      Paint()..color = palette.body,
    );
    final ember = Color.lerp(palette.body, palette.bodyDetail, 0.2)!;
    blotches(
      biome == Biome.volcano
          ? [palette.bodyShade, ember]
          : [palette.bodyShade, palette.bodyDetail],
      _perBody(34),
    );
    switch (biome) {
      case Biome.nightForest:
        _strata(4 * _tiles, palette.bodyShade, 5);
        _stones(_perBody(18), 3, 7, palette.bodyDetail);
        _roots(_perBody(6));
      case Biome.desertDusk:
        _strata(7 * _tiles, palette.bodyDetail, 6);
        _strata(5 * _tiles, palette.bodyShade, 3);
        _stones(_perBody(10), 2, 5, palette.bodyDetail);
      case Biome.snowyPeaks:
        _strata(3 * _tiles, palette.bodyShade, 3);
        _speckles(_perBody(220), palette.bodyDetail);
        _cracks(_perBody(3), palette.bodyShade, glow: false);
      case Biome.crystalCaves:
        _speckles(_perBody(120), palette.bodyShade);
        _crystals(_perBody(4));
      case Biome.volcano:
        _speckles(_perBody(160), palette.bodyShade);
        _cracks(_perBody(3), palette.bodyDetail, glow: true);
    }
  }

  void _strata(int count, Color color, double width) {
    for (var i = 0; i < count; i++) {
      final base = (i + random.range(0.2, 0.8)) * _size / count;
      final profile = wave(random.range(3, 9));
      final path = Path()..moveTo(0, base + profile(0));
      for (var x = 4.0; x <= _size; x += 4) {
        path.lineTo(x, base + profile(x));
      }
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * random.range(0.6, 1.2)
        ..color = color.withValues(alpha: random.range(0.25, 0.45));
      for (final dy in [-_size, 0.0, _size]) {
        canvas.drawPath(path.shift(Offset(0, dy)), paint);
      }
    }
  }

  void _stones(int count, double min, double max, Color color) {
    for (var i = 0; i < count; i++) {
      final radius = random.range(min, max);
      final shade = Color.lerp(color, palette.bodyShade, random.range(0, 0.5))!;
      wrapped(
        random.range(0, _size),
        random.range(0, _size),
        radius * 2,
        (x, y) => stone(x, y, radius, shade),
        wrapY: true,
      );
    }
  }

  void _speckles(int count, Color color) {
    final paint = Paint()..color = color.withValues(alpha: 0.6);
    for (var i = 0; i < count; i++) {
      final radius = random.range(0.6, 1.8);
      wrapped(
        random.range(0, _size),
        random.range(0, _size),
        2,
        (x, y) => canvas.drawCircle(Offset(x, y), radius, paint),
        wrapY: true,
      );
    }
  }

  void _roots(int count) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6
      ..color = palette.bodyShade.withValues(alpha: 0.7);
    for (var i = 0; i < count; i++) {
      final x0 = random.range(0, _size);
      final y0 = random.range(0, _size);
      final path = Path()..moveTo(0, 0);
      var x = 0.0;
      var y = 0.0;
      for (var s = 0; s < 6; s++) {
        x += random.range(-8, 8);
        y += random.range(4, 10);
        path.lineTo(x, y);
      }
      wrapped(
        x0,
        y0,
        70,
        (cx, cy) => canvas.drawPath(path.shift(Offset(cx, cy)), paint),
        wrapY: true,
      );
    }
  }

  void _cracks(int count, Color color, {required bool glow}) {
    for (var i = 0; i < count; i++) {
      // A vein of gentle curves, wider in the middle.
      final path = Path()..moveTo(0, 0);
      var x = 0.0;
      var y = 0.0;
      var heading = random.range(-0.6, 0.6);
      for (var s = 0; s < 5; s++) {
        heading += random.range(-0.5, 0.5);
        final length = random.range(10, 18);
        final nx = x + math.sin(heading) * length;
        final ny = y + math.cos(heading) * length;
        path.quadraticBezierTo(
          (x + nx) / 2 + random.range(-4, 4),
          (y + ny) / 2,
          nx,
          ny,
        );
        x = nx;
        y = ny;
      }
      final x0 = random.range(0, _size);
      final y0 = random.range(0, _size);
      void draw(double cx, double cy) {
        final shifted = path.shift(Offset(cx, cy));
        if (glow) {
          canvas
            ..drawPath(
              shifted,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 5
                ..strokeCap = StrokeCap.round
                ..color = color.withValues(alpha: 0.4)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
            )
            ..drawPath(
              shifted,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.4
                ..strokeCap = StrokeCap.round
                ..color = const Color(0xFFFFC266),
            );
        } else {
          canvas.drawPath(
            shifted,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.4
              ..color = color.withValues(alpha: 0.8),
          );
        }
      }

      wrapped(x0, y0, 100, draw, wrapY: true);
    }
  }

  void _crystals(int count) {
    for (var i = 0; i < count; i++) {
      final height = random.range(16, 36);
      final width = height * random.range(0.35, 0.5);
      final tilt = random.range(-0.6, 0.6);
      void draw(double x, double y) {
        canvas
          ..save()
          ..translate(x, y)
          ..rotate(tilt);
        final shard = Path()
          ..moveTo(0, -height)
          ..lineTo(width / 2, -height * 0.6)
          ..lineTo(width / 2, 0)
          ..lineTo(-width / 2, 0)
          ..lineTo(-width / 2, -height * 0.6)
          ..close();
        final bounds = shard.getBounds();
        canvas
          ..drawPath(
            shard,
            Paint()
              ..color = palette.accent.withValues(alpha: 0.35)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
          )
          ..drawPath(
            shard,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(palette.accent, const Color(0xFFFFFFFF), 0.5)!,
                  palette.bodyDetail,
                  palette.bodyShade,
                ],
              ).createShader(bounds),
          )
          ..drawLine(
            Offset(-width / 4, -height * 0.55),
            Offset(-width / 4, -height * 0.1),
            Paint()
              ..color = const Color(0x99FFFFFF)
              ..strokeWidth = 1.2,
          )
          ..restore();
      }

      final cx = random.range(0, _size);
      final cy = random.range(20, _size);
      for (var shard = random.intIn(2, 4); shard > 0; shard--) {
        wrapped(
          cx + random.range(-8, 8),
          cy + random.range(-3, 3),
          50,
          draw,
          wrapY: true,
        );
      }
    }
  }
}

/// The surface strip: the material on top of the ground.
class _Surface extends _Painter {
  new(super.canvas, super.palette, super.random);

  static const double _height = TerrainTextures.surfaceHeight * 1.0;

  /// The ground line, in strip pixels.
  static const double _ground =
      TerrainTextures.surfaceHeight * TerrainTextures.overhangFraction;

  void paint(Biome biome) {
    switch (biome) {
      case Biome.nightForest:
        _band(_ground - 2, 30, edge: 4);
        _blades(_perStrip(90));
      case Biome.desertDusk:
        _band(_ground - 3, 22, topWave: 3);
        _ripples(_perStrip(10));
        _sparkles(_perStrip(30), const Color(0xFFFFF4D6));
      case Biome.snowyPeaks:
        _band(_ground - 6, 24, edge: 2, topWave: 4);
        _bumps(_perStrip(14));
        _icicles(_perStrip(16));
      case Biome.crystalCaves:
        _band(_ground - 2, 24);
        _sparkles(_perStrip(26), palette.surface);
        _blades(_perStrip(40), short: true);
      case Biome.volcano:
        _band(_ground - 3, 28, edge: 4, topWave: 2);
        _bumps(_perStrip(10));
        _emberLine();
    }
  }

  /// The material band from [top] down [depth] pixels, with a wavy lower
  /// edge of [edge] pixels and an optional wavy top.
  void _band(double top, double depth, {double edge = 3, double topWave = 0}) {
    final topProfile = wave(topWave);
    final bottomProfile = wave(edge);
    final path = Path()..moveTo(0, top + topProfile(0));
    for (var x = 4.0; x <= _size; x += 4) {
      path.lineTo(x, top + topProfile(x));
    }
    for (var x = _size; x >= 0; x -= 4) {
      path.lineTo(x, top + depth + bottomProfile(x));
    }
    path.close();
    final rect = Rect.fromLTWH(0, top - topWave, _size, depth + edge + topWave);
    canvas
      // A soft shadow under the band, onto the body.
      ..drawPath(
        path.shift(const Offset(0, 3)),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(palette.surface, const Color(0xFFFFFFFF), 0.25)!,
              palette.surface,
              palette.surfaceShade,
            ],
            stops: const [0, 0.35, 1],
          ).createShader(rect),
      );
    // A light rim along the top edge.
    final rim = Path()..moveTo(0, top + topProfile(0));
    for (var x = 4.0; x <= _size; x += 4) {
      rim.lineTo(x, top + topProfile(x));
    }
    canvas.drawPath(
      rim,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0x66FFFFFF),
    );
  }

  void _blades(int count, {bool short = false}) {
    for (var i = 0; i < count; i++) {
      final height = short ? random.range(3, 7) : random.range(6, 13);
      final width = random.range(2, 4);
      final lean = random.range(-3, 3);
      final color = Color.lerp(
        palette.surface,
        random.chance(0.5) ? palette.surfaceShade : const Color(0xFFFFFFFF),
        random.range(0, 0.35),
      )!;
      final paint = Paint()..color = color;
      wrapped(random.range(0, _size), _ground + random.range(0, 3), 10, (x, y) {
        canvas.drawPath(
          Path()
            ..moveTo(x - width / 2, y)
            ..lineTo(x + lean, y - height)
            ..lineTo(x + width / 2, y)
            ..close(),
          paint,
        );
      }, height: _height);
    }
  }

  void _ripples(int count) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = palette.surfaceShade.withValues(alpha: 0.6);
    for (var i = 0; i < count; i++) {
      final width = random.range(16, 34);
      wrapped(
        random.range(0, _size),
        random.range(_ground + 4, _ground + 16),
        40,
        (x, y) {
          canvas.drawArc(
            Rect.fromCenter(center: Offset(x, y), width: width, height: 6),
            math.pi,
            math.pi,
            false,
            paint,
          );
        },
        height: _height,
      );
    }
  }

  void _sparkles(int count, Color color) {
    for (var i = 0; i < count; i++) {
      final radius = random.range(0.8, 2);
      final paint = Paint()
        ..color = color.withValues(alpha: random.range(0.5, 0.9))
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius);
      wrapped(random.range(0, _size), random.range(2, _ground + 14), 4, (x, y) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }, height: _height);
    }
  }

  void _bumps(int count) {
    for (var i = 0; i < count; i++) {
      final radius = random.range(6, 12);
      final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
      final paint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.5),
          colors: [
            Color.lerp(palette.surface, const Color(0xFFFFFFFF), 0.5)!,
            palette.surface,
          ],
        ).createShader(rect);
      wrapped(random.range(0, _size), _ground - 2, radius, (x, y) {
        canvas
          ..save()
          ..translate(x, y)
          ..drawArc(rect, math.pi, math.pi, true, paint)
          ..restore();
      }, height: _height);
    }
  }

  void _icicles(int count) {
    for (var i = 0; i < count; i++) {
      final length = random.range(6, 16);
      final width = random.range(3, 6);
      final bounds = Rect.fromLTWH(-width / 2, 0, width, length);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFFFFF), palette.surfaceShade],
        ).createShader(bounds);
      wrapped(random.range(0, _size), _ground + 18, 8, (x, y) {
        canvas.drawPath(
          Path()
            ..moveTo(x - width / 2, y)
            ..lineTo(x, y + length)
            ..lineTo(x + width / 2, y)
            ..close(),
          paint,
        );
      }, height: _height);
    }
  }

  void _emberLine() {
    final profile = wave(3);
    final path = Path()..moveTo(0, _ground + 20 + profile(0));
    for (var x = 4.0; x <= _size; x += 4) {
      path.lineTo(x, _ground + 20 + profile(x));
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = palette.bodyDetail.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFFFD27A),
      );
    _sparkles(_perStrip(18), palette.particle);
  }
}
