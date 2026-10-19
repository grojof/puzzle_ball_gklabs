import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show FloorSurface;
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/components/ground_surface.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_paint.dart';

/// A floor run: one static body for a whole run of ground (design D4 of the
/// level generator).
///
/// Drawn from the world's generated textures: the body below, darkening
/// with depth, and the surface material along the top (game-visuals spec).
/// A conveyor belt, ice or mud covers the top with its own look: a belt's
/// marks move in its direction.
class FloorComponent extends BodyComponent
    with ContactCallbacks
    implements GroundSurface {
  new({
    required this.position,
    required this.size,
    required this.terrain,
    this.friction = 0.8,
    this.surface = FloorSurface.plain,
    this.seamless = false,
  }) : super(renderBody: false);

  /// Top-left corner, in meters.
  @override
  final Vector2 position;

  /// Width and height, in meters.
  final Vector2 size;
  final TerrainPaint terrain;
  final double friction;

  /// What the top is made of.
  final FloorSurface surface;

  /// Whether a run at the same height or a curve touches this one: then its
  /// top is a chain whose ghost ends continue level, with the box just below
  /// it, so a fast ball rolls across the seam instead of catching on the
  /// next box's corner.
  final bool seamless;

  /// How far below a seamless run's top its box stops, in meters.
  static const seamDepth = 0.03;

  /// How thick a surface's cover is, and how far apart a belt's marks are,
  /// in meters.
  static const coverHeight = 0.2;
  static const markSpacing = 0.6;

  /// Seconds since the floor appeared, to move a belt's marks.
  double _time = 0;

  late final Rect _rect = Rect.fromLTWH(
    -size.x / 2,
    -size.y / 2,
    size.x,
    size.y,
  );
  late final Paint _body = terrain.body(position + size / 2);
  late final Rect _strip = Rect.fromLTWH(
    _rect.left,
    _rect.top - TerrainPaint.surfaceOverhang,
    size.x,
    TerrainPaint.surfaceHeight,
  );
  late final Paint _surface = terrain.surface(
    left: _strip.left,
    top: _strip.top,
    originX: position.x + size.x / 2,
  );
  late final Paint _depth = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0x00000000), Color(0x73000000)],
    ).createShader(_rect);
  static final _edge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.04
    ..color = const Color(0x59000000);

  @override
  FloorSurface get floorSurface => surface;

  @override
  bool supports(Vector2 center) =>
      center.x >= position.x - GroundSurface.edgeTolerance &&
      center.x <= position.x + size.x + GroundSurface.edgeTolerance &&
      center.y < position.y;

  @override
  Body createBody() {
    final body = world.createBody(BodyDef(position: position + size / 2));
    if (!seamless) {
      return body..createShape(
        Polygon.box(size.x / 2, size.y / 2),
        ShapeDef(
          material: SurfaceMaterial(friction: friction),
          enableContactEvents: true,
          userData: this,
        ),
      );
    }
    body
      ..userData = this
      ..createShape(
        Polygon.offsetBox(
          size.x / 2,
          size.y / 2 - seamDepth / 2,
          center: Vector2(0, seamDepth / 2),
        ),
        ShapeDef(
          material: SurfaceMaterial(friction: friction),
          enableContactEvents: true,
          userData: this,
        ),
      );
    final top = -size.y / 2;
    final chain = body.createChain(
      ChainDef(
        points: [
          Vector2(-size.x / 2 - 1, top),
          Vector2(-size.x / 2, top),
          Vector2(size.x / 2, top),
          Vector2(size.x / 2 + 1, top),
        ],
        materials: [SurfaceMaterial(friction: friction)],
      ),
    );
    for (final segment in chain.segments) {
      segment.contactEventsEnabled = true;
    }
    return body;
  }

  /// The drawn area in world coordinates, to skip drawing when off screen.
  late final Rect _worldBounds = _strip
      .expandToInclude(_rect)
      .shift(Offset(position.x + size.x / 2, position.y + size.y / 2));

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  /// The cover over the top of a belt, ice or mud.
  late final Rect _cover = Rect.fromLTWH(
    _rect.left,
    _rect.top - coverHeight / 2,
    size.x,
    coverHeight,
  );
  late final RRect _coverShape = RRect.fromRectAndRadius(
    _cover,
    const Radius.circular(coverHeight / 2),
  );
  late final Paint _coverPaint = Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: switch (surface) {
        FloorSurface.ice => [
          const Color(0xFFFFFFFF),
          ElementPalette.ice,
          ElementPalette.ice.withValues(alpha: 0.7),
        ],
        FloorSurface.mud => [
          Color.lerp(ElementPalette.mud, const Color(0xFFFFFFFF), 0.15)!,
          ElementPalette.mud,
          Color.lerp(ElementPalette.mud, ElementPalette.outline, 0.4)!,
        ],
        _ => [
          Color.lerp(ElementPalette.belt, const Color(0xFFFFFFFF), 0.2)!,
          ElementPalette.belt,
          Color.lerp(ElementPalette.belt, ElementPalette.outline, 0.5)!,
        ],
      },
    ).createShader(_cover);
  static final _coverEdge = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.035
    ..color = ElementPalette.outline;
  static final _markPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.06
    ..strokeCap = StrokeCap.round
    ..color = ElementPalette.beltMark;
  static final _gleam = Paint()
    ..strokeWidth = 0.04
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xCCFFFFFF);
  static final _blob = Paint()
    ..color = Color.lerp(ElementPalette.mud, ElementPalette.outline, 0.5)!;

  void _renderCover(Canvas canvas) {
    canvas
      ..drawRRect(_coverShape, _coverPaint)
      ..drawRRect(_coverShape, _coverEdge);
    final top = _cover.top;
    final middle = _cover.center.dy;
    switch (surface) {
      case FloorSurface.plain:
        return;
      case FloorSurface.conveyorForward || FloorSurface.conveyorBackward:
        // Chevrons drifting with the belt, clipped to it.
        final direction = surface == FloorSurface.conveyorForward ? 1 : -1;
        final shift = (_time * BallComponent.beltSpeed) % markSpacing;
        const half = coverHeight * 0.3;
        canvas
          ..save()
          ..clipRRect(_coverShape);
        for (
          var x = _cover.left - markSpacing + direction * shift;
          x < _cover.right + markSpacing;
          x += markSpacing
        ) {
          canvas
            ..drawLine(
              Offset(x - direction * half, middle - half),
              Offset(x, middle),
              _markPaint,
            )
            ..drawLine(
              Offset(x, middle),
              Offset(x - direction * half, middle + half),
              _markPaint,
            );
        }
        canvas.restore();
      case FloorSurface.ice:
        // Glints along the glassy top.
        for (var x = _cover.left + 0.3; x < _cover.right - 0.3; x += 1.1) {
          canvas.drawLine(
            Offset(x, top + 0.05),
            Offset(x + 0.3, top + 0.05),
            _gleam,
          );
        }
      case FloorSurface.mud:
        // Dark lumps in the soft top.
        for (var x = _cover.left + 0.35; x < _cover.right - 0.2; x += 0.7) {
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(x, middle + 0.02),
              width: 0.22,
              height: 0.08,
            ),
            _blob,
          );
        }
    }
  }

  @override
  void render(Canvas canvas) {
    if (!game.camera.visibleWorldRect.overlaps(_worldBounds)) return;
    canvas
      ..drawRect(_rect, _body)
      ..drawRect(_rect, _depth)
      ..drawLine(_rect.topLeft, _rect.bottomLeft, _edge)
      ..drawLine(_rect.topRight, _rect.bottomRight, _edge)
      ..drawRect(_strip, _surface);
    if (surface != FloorSurface.plain) _renderCover(canvas);
  }
}
