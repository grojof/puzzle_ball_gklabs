import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/game/visuals/world_look.dart';

/// The backdrop of a generated biome: a sky gradient, silhouette layers that
/// move with the camera at different speeds, and ambient particles (design
/// D4). Drawn in screen space, behind the world.
///
/// Each layer is a band sized by the screen's short side, anchored at the
/// bottom (or the top, for hanging shapes), so shapes keep their proportions
/// in portrait and landscape. Bands are rasterized once, so a frame only
/// draws images.
class BiomeBackdrop extends Component {
  new({required this.look, required this.cameraX})
    : assert(look.biome != Biome.nightForest, 'The forest is painted');

  final WorldLook look;

  /// The camera's horizontal position, in meters.
  final double Function() cameraX;

  /// How far each layer moves for a meter of camera travel, in pixels, from
  /// the farthest to the nearest.
  static const List<double> parallax = [4, 10, 18];

  /// Each layer is generated this many screen widths wide and repeats.
  static const double layerWidths = 1.5;

  /// Rasterizing resolution, in pixels per logical pixel.
  static const double resolution = 1.5;

  final List<BackdropLayer> _layers = [];
  double _layerWidth = 0;
  Vector2 _screen = Vector2.zero();
  late Paint _sky;
  final Paint _image = Paint()..filterQuality = FilterQuality.medium;

  /// The silhouette layers, from the farthest; empty until sized.
  List<BackdropLayer> get layers => _layers;

  /// The horizontal offset of layer [index] for the current camera, in
  /// pixels, within one layer width.
  double offsetOf(int index) {
    if (_layerWidth == 0) return 0;
    return -(cameraX() * parallax[index]) % _layerWidth;
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size == _screen || size.x <= 0 || size.y <= 0) return;
    _screen = size.clone();
    _layerWidth = size.x * layerWidths;
    _disposeLayers();
    final band = math.min(size.y, math.min(size.x, size.y));
    final silhouettes = _Silhouettes(look, Size(_layerWidth, band));
    for (var depth = 0; depth < 3; depth++) {
      final picture = silhouettes.layer(depth);
      final top = silhouettes.hangs(depth) ? 0.0 : size.y - band;
      _layers.add(
        BackdropLayer(
          image: _rasterize(picture, _layerWidth, band),
          rect: Rect.fromLTWH(0, top, _layerWidth, band),
        ),
      );
      picture.dispose();
    }
    _sky = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [look.palette.skyTop, look.palette.skyBottom],
      ).createShader(Offset.zero & size.toSize());
  }

  static ui.Image _rasterize(ui.Picture picture, double width, double height) {
    final recorder = ui.PictureRecorder();
    Canvas(recorder)
      ..scale(resolution)
      ..drawPicture(picture);
    final scaled = recorder.endRecording();
    final image = scaled.toImageSync(
      (width * resolution).ceil(),
      (height * resolution).ceil(),
    );
    scaled.dispose();
    return image;
  }

  @override
  void render(Canvas canvas) {
    if (_layers.isEmpty) return;
    canvas.drawRect(Offset.zero & _screen.toSize(), _sky);
    for (var i = 0; i < _layers.length; i++) {
      final layer = _layers[i];
      final source = Rect.fromLTWH(
        0,
        0,
        layer.image.width.toDouble(),
        layer.image.height.toDouble(),
      );
      final offset = offsetOf(i);
      for (final x in [offset - _layerWidth, offset, offset + _layerWidth]) {
        if (x >= _screen.x || x + _layerWidth <= 0) continue;
        canvas.drawImageRect(
          layer.image,
          source,
          layer.rect.shift(Offset(x, 0)),
          _image,
        );
      }
    }
  }

  void _disposeLayers() {
    for (final layer in _layers) {
      layer.image.dispose();
    }
    _layers.clear();
  }

  @override
  void onRemove() {
    _disposeLayers();
    super.onRemove();
  }
}

/// A rasterized silhouette band and where it sits on the screen, before its
/// parallax offset.
class BackdropLayer {
  new({required this.image, required this.rect});

  final ui.Image image;
  final Rect rect;
}

/// The silhouette recipes of the generated biomes: up to three layers, each
/// repeating seamlessly across its width.
class _Silhouettes {
  new(this.look, this.size)
    : random = Mulberry32(fnv1a32('${look.biome.name}/sky/${look.variant}'));

  final WorldLook look;
  final Size size;
  final Mulberry32 random;

  BiomePalette get palette => look.palette;

  /// Whether layer [depth] hangs from the top of the screen.
  bool hangs(int depth) => look.biome == Biome.crystalCaves && depth < 2;

  /// Layer [depth], from 0 (farthest), drawn in its band.
  ui.Picture layer(int depth) {
    _depth = depth;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Offset.zero & size);
    final color = palette.silhouettes[depth];
    switch (look.biome) {
      case Biome.desertDusk:
        if (depth == 1) {
          _fill(canvas, _mesas(0.62), color);
        } else {
          _fill(canvas, _ridge(depth == 0 ? 0.6 : 0.78, 0.05, 3), color);
        }
      case Biome.snowyPeaks:
        if (depth < 2) {
          final peaks = _peaks(depth == 0 ? 0.42 : 0.55, depth == 0 ? 7 : 10);
          _fill(canvas, peaks.$1, color);
          _snowCaps(canvas, peaks.$2, depth == 0 ? 0.47 : 0.6);
        } else {
          _pines(canvas, 0.82, color);
        }
      case Biome.crystalCaves:
        if (depth < 2) {
          _fill(canvas, _stalactites(depth == 0 ? 0.32 : 0.22), color);
          _glints(canvas, depth == 0 ? 10 : 16);
        } else {
          _fill(canvas, _stalagmites(0.8), color);
        }
      case Biome.volcano:
        if (depth == 0) {
          _volcanoes(canvas, color);
        } else {
          _fill(canvas, _peaks(depth == 1 ? 0.66 : 0.8, 14).$1, color);
        }
      case Biome.nightForest:
        throw StateError('The forest is painted');
    }
    return recorder.endRecording();
  }

  double get w => size.width;
  double get h => size.height;

  /// The layer being drawn, from 0 (farthest) to 2 (nearest).
  int _depth = 0;

  /// Fills [shape] with [color], lighter at its top and paler with
  /// distance, like air, with a light rim along its profile.
  void _fill(Canvas canvas, Path shape, Color color) {
    final bounds = shape.getBounds();
    final haze = const [0.5, 0.3, 0.12][_depth];
    canvas
      ..drawPath(
        shape,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(color, palette.skyBottom, haze + 0.2)!,
              Color.lerp(color, palette.skyBottom, haze)!,
            ],
          ).createShader(bounds),
      )
      ..drawPath(
        shape,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Color.lerp(
            color,
            const Color(0xFFFFFFFF),
            0.5,
          )!.withValues(alpha: 0.35),
      );
  }

  /// A smooth repeating ridge around [base] (a fraction of the height) with
  /// [amplitude] (a fraction too) and [waves] crests across the layer.
  Path _ridge(double base, double amplitude, int waves) {
    final phase = random.range(0, 2 * math.pi);
    final path = Path()..moveTo(0, h);
    for (var x = 0.0; x <= w; x += 6) {
      final t = x / w * 2 * math.pi;
      final y =
          math.sin(t * waves + phase) * 0.7 +
          math.sin(t * waves * 2 + phase * 1.7) * 0.3;
      path.lineTo(x, h * (base - amplitude * y));
    }
    return path
      ..lineTo(w, h)
      ..close();
  }

  /// Flat-topped plateaus with steep sides.
  Path _mesas(double base) {
    final path = Path()..moveTo(0, h);
    var x = 0.0;
    path.lineTo(0, h * base);
    while (x < w) {
      final gap = random.range(0.05, 0.12) * w;
      final width = random.range(0.08, 0.16) * w;
      final top = h * (base - random.range(0.08, 0.16));
      final slope = width * 0.15;
      if (x + gap + width + 2 * slope > w) break;
      x += gap;
      path
        ..lineTo(x, h * base)
        ..lineTo(x + slope, top)
        ..lineTo(x + slope + width, top)
        ..lineTo(x + 2 * slope + width, h * base);
      x += 2 * slope + width;
    }
    return path
      ..lineTo(w, h * base)
      ..lineTo(w, h)
      ..close();
  }

  /// A jagged range of [count] peaks around [base]; also returns the peaks.
  (Path, List<Offset>) _peaks(double base, int count) {
    final step = w / count;
    final valley = h * (base + 0.12);
    final points = <Offset>[];
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, valley);
    for (var i = 0; i < count; i++) {
      final peak = Offset(
        i * step + step * random.range(0.3, 0.7),
        h * (base - random.range(0, 0.1)),
      );
      points.add(peak);
      path
        ..lineTo(peak.dx, peak.dy)
        ..lineTo((i + 1) * step, valley - random.range(0, 0.05) * h);
    }
    path
      ..lineTo(w, valley)
      ..lineTo(w, h)
      ..close();
    return (path, points);
  }

  /// White caps on the peaks, down to [line] (a fraction of the height).
  void _snowCaps(Canvas canvas, List<Offset> peaks, double line) {
    final paint = Paint()..color = const Color(0xE6FFFFFF);
    for (final peak in peaks) {
      final depth = h * line - peak.dy;
      if (depth <= 0) continue;
      final half = depth * 0.8;
      canvas.drawPath(
        Path()
          ..moveTo(peak.dx, peak.dy)
          ..lineTo(peak.dx + half, peak.dy + depth)
          ..lineTo(peak.dx + half * 0.3, peak.dy + depth * 0.8)
          ..lineTo(peak.dx, peak.dy + depth)
          ..lineTo(peak.dx - half * 0.4, peak.dy + depth * 0.75)
          ..lineTo(peak.dx - half, peak.dy + depth)
          ..close(),
        paint,
      );
    }
  }

  /// A row of pine trees standing on [base].
  void _pines(Canvas canvas, double base, Color color) {
    final ground = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * base)
      ..lineTo(w, h * base)
      ..lineTo(w, h)
      ..close();
    _fill(canvas, ground, color);
    final paint = Paint()..color = color;
    var x = random.range(0, 20);
    while (x < w - 20) {
      final height = h * random.range(0.1, 0.18);
      final width = height * 0.45;
      for (var tier = 0; tier < 3; tier++) {
        final top = h * base - height + tier * height * 0.25;
        canvas.drawPath(
          Path()
            ..moveTo(x, top)
            ..lineTo(x + width / 2 * (0.6 + tier * 0.2), top + height * 0.45)
            ..lineTo(x - width / 2 * (0.6 + tier * 0.2), top + height * 0.45)
            ..close(),
          paint,
        );
      }
      x += width * random.range(0.8, 1.6);
    }
  }

  /// Stalactites hanging from the top, down to [reach] of the height.
  Path _stalactites(double reach) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, h * 0.06);
    var x = 0.0;
    while (x < w) {
      final width = random.range(0.1, 0.22) * h;
      final length = h * random.range(reach * 0.4, reach);
      final end = math.min(w, x + width);
      path
        ..lineTo(x + (end - x) / 2, length)
        ..lineTo(end, h * 0.06);
      x = end;
    }
    return path
      ..lineTo(w, 0)
      ..close();
  }

  /// Stalagmites and columns rising from [base].
  Path _stalagmites(double base) {
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * base);
    var x = 0.0;
    while (x < w) {
      final width = random.range(0.12, 0.26) * h;
      final height = h * random.range(0.05, 0.2);
      final end = math.min(w, x + width);
      path
        ..lineTo(x + (end - x) / 2, h * base - height)
        ..lineTo(end, h * base);
      x = end;
    }
    return path
      ..lineTo(w, h)
      ..close();
  }

  /// Faint glowing crystal points.
  void _glints(Canvas canvas, int count) {
    for (var i = 0; i < count; i++) {
      final center = Offset(random.range(0, w), random.range(0.05, 0.3) * h);
      final radius = random.range(2, 5);
      canvas
        ..drawCircle(
          center,
          radius * 2,
          Paint()..color = palette.accent.withValues(alpha: 0.06),
        )
        ..drawCircle(
          center,
          radius,
          Paint()..color = palette.accent.withValues(alpha: 0.7),
        );
    }
  }

  /// Distant volcano cones with glowing craters.
  void _volcanoes(Canvas canvas, Color color) {
    const count = 2;
    for (var i = 0; i < count; i++) {
      final cx = w * (i + random.range(0.3, 0.7)) / count;
      final top = h * random.range(0.3, 0.42);
      final base = h * 0.75;
      final half = (base - top) * random.range(1.2, 1.6);
      final crater = (base - top) * 0.12;
      final cone = Path()
        ..moveTo(cx - half, base)
        ..lineTo(cx - crater, top)
        ..lineTo(cx + crater, top)
        ..lineTo(cx + half, base)
        ..close();
      // The glow behind the crater, then the cone.
      canvas.drawCircle(
        Offset(cx, top),
        crater * 4,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  palette.accent.withValues(alpha: 0.55),
                  palette.accent.withValues(alpha: 0),
                ],
              ).createShader(
                Rect.fromCircle(center: Offset(cx, top), radius: crater * 4),
              ),
      );
      _fill(canvas, cone, color);
      canvas.drawLine(
        Offset(cx - crater, top),
        Offset(cx + crater, top),
        Paint()
          ..color = palette.accent
          ..strokeWidth = 2,
      );
    }
    _fill(canvas, _ridge(0.78, 0.03, 4), color);
  }
}

/// A translucent color over the whole screen: a variant's light over the
/// painted forest.
class ScreenTint extends Component {
  new(this.color);

  final Color color;
  late final Paint _paint = Paint()..color = color.withValues(alpha: 0.18);
  Rect _screen = Rect.zero;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _screen = Offset.zero & size.toSize();
  }

  @override
  void render(Canvas canvas) => canvas.drawRect(_screen, _paint);
}

/// The kinds of ambient particle.
enum ParticleStyle { fireflies, sand, snow, sparkles, embers }

/// Ambient particles drifting over the screen: a fixed number, seeded, and
/// wrapped at the edges (design D4).
class ParticleField extends Component {
  new({
    required this.style,
    required this.color,
    required int seed,
    this.count = maxParticles,
  }) : assert(count <= maxParticles, 'Particle budget'),
       _random = Mulberry32(seed);

  /// The most particles a field may have.
  static const maxParticles = 48;

  /// How many particles a biome shows: few, so the backdrop stays calm.
  static const calmCount = 20;

  final ParticleStyle style;
  final Color color;
  final int count;
  final Mulberry32 _random;

  late final List<AmbientParticle> particles = [
    for (var i = 0; i < count; i++)
      AmbientParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.range(0.6, 1.4),
        phase: _random.range(0, 2 * math.pi),
        speed: _random.range(0.6, 1.4),
      ),
  ];

  Vector2 _screen = Vector2.zero();
  double _time = 0;

  /// The sprite every particle is drawn from, in white; tinted per particle.
  late final ui.Image _sprite = _drawSprite(style);
  static const Rect _spriteRect = Rect.fromLTWH(0, 0, _spriteSize, _spriteSize);
  late final List<RSTransform> _transforms = [
    for (var i = 0; i < count; i++) RSTransform(1, 0, 0, 0),
  ];
  late final List<Rect> _rects = List.filled(count, _spriteRect);
  late final List<Color> _colors = List.filled(count, color);
  final Paint _atlas = Paint()..filterQuality = FilterQuality.low;

  /// The sprite's size, in pixels.
  static const double _spriteSize = 32;

  /// Draws the white sprite of [style]: a soft glow, a flake or a twinkle.
  static ui.Image _drawSprite(ParticleStyle style) {
    const c = _spriteSize / 2;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const white = Color(0xFFFFFFFF);
    final glow =
        style == ParticleStyle.fireflies || style == ParticleStyle.embers;
    if (glow) {
      canvas.drawCircle(
        const Offset(c, c),
        c,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  white,
                  white,
                  white.withValues(alpha: 0.12),
                  white.withValues(alpha: 0),
                ],
                stops: const [0, 0.22, 0.45, 1],
              ).createShader(
                Rect.fromCircle(center: const Offset(c, c), radius: c),
              ),
      );
    } else if (style == ParticleStyle.sparkles) {
      final paint = Paint()
        ..color = white
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3;
      canvas
        ..drawLine(const Offset(2, c), const Offset(_spriteSize - 2, c), paint)
        ..drawLine(const Offset(c, 2), const Offset(c, _spriteSize - 2), paint)
        ..drawCircle(const Offset(c, c), 4, paint);
    } else {
      canvas.drawCircle(
        const Offset(c, c),
        c * 0.45,
        Paint()
          ..color = white
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
      );
    }
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_spriteSize.toInt(), _spriteSize.toInt());
    picture.dispose();
    return image;
  }

  /// The particle style for [biome].
  static ParticleStyle styleOf(Biome biome) => switch (biome) {
    Biome.nightForest => ParticleStyle.fireflies,
    Biome.desertDusk => ParticleStyle.sand,
    Biome.snowyPeaks => ParticleStyle.snow,
    Biome.crystalCaves => ParticleStyle.sparkles,
    Biome.volcano => ParticleStyle.embers,
  };

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _screen = size.clone();
  }

  @override
  void update(double dt) {
    _time += dt;
    for (final p in particles) {
      final (dx, dy) = switch (style) {
        ParticleStyle.fireflies => (
          math.cos(_time * 0.35 * p.speed + p.phase) * 0.0015,
          math.sin(_time * 0.45 * p.speed + p.phase) * 0.0015,
        ),
        ParticleStyle.sand => (
          -0.08 * p.speed,
          0.004 * math.sin(_time * 0.5 + p.phase),
        ),
        ParticleStyle.snow => (
          0.008 * math.sin(_time * 0.6 + p.phase),
          0.02 * p.speed,
        ),
        ParticleStyle.sparkles => (0.0, 0.0),
        ParticleStyle.embers => (
          0.006 * math.sin(_time * 0.8 + p.phase),
          -0.022 * p.speed,
        ),
      };
      p
        ..x = (p.x + dx * dt * (style == ParticleStyle.fireflies ? 60 : 1)) % 1
        ..y = (p.y + dy * dt * (style == ParticleStyle.fireflies ? 60 : 1)) % 1;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_screen.x == 0) return;
    // Every particle in one draw call, tinted and sized per particle.
    for (var i = 0; i < particles.length; i++) {
      final p = particles[i];
      // Gentle: dim and slow, so it never draws the eye from the course.
      final twinkle = 0.3 + 0.2 * math.sin(_time * 1.2 * p.speed + p.phase);
      final diameter = switch (style) {
        ParticleStyle.fireflies => 10.5 * p.size,
        ParticleStyle.sand => 5.4 * p.size,
        ParticleStyle.snow => 9.8 * p.size,
        ParticleStyle.sparkles => 8 * p.size * twinkle,
        ParticleStyle.embers => 8 * p.size,
      };
      final scale = diameter / _spriteSize;
      final steady = style == ParticleStyle.sand || style == ParticleStyle.snow;
      _transforms[i] = RSTransform.fromComponents(
        rotation: 0,
        scale: scale,
        anchorX: _spriteSize / 2,
        anchorY: _spriteSize / 2,
        translateX: p.x * _screen.x,
        translateY: p.y * _screen.y,
      );
      _colors[i] = color.withValues(alpha: steady ? 0.45 : twinkle);
    }
    canvas.drawAtlas(
      _sprite,
      _transforms,
      _rects,
      _colors,
      BlendMode.modulate,
      null,
      _atlas,
    );
  }

  @override
  void onRemove() {
    _sprite.dispose();
    super.onRemove();
  }
}

/// One ambient particle, in screen fractions.
class AmbientParticle {
  new({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
  });

  double x;
  double y;
  final double size;
  final double phase;
  final double speed;
}
