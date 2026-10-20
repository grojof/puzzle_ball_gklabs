import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show FloorSurface, Seesaw;
import 'package:puzzle_ball_gklabs/game/components/ground_surface.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A seesaw: a light plank on a pivot over a pit, resting leaning back with
/// its near end level with the run before it. Past the pivot, the ball's
/// weight tips it forwards until its far end stops at its tilt
/// (level-mechanics spec, design D4 of add-dynamic-elements).
///
/// A revolute joint to a static anchor at the pivot, limited to the two
/// tilts: balanced, the plank stays where the ball leaves it, so it rests
/// at its back limit until the ball passes the pivot, and a light plank
/// tips at once. Drawn as a banded wooden plank on a fulcrum with a post
/// down into the pit (game-visuals spec).
class SeesawComponent extends BodyComponent implements GroundSurface {
  new({required this.seesaw}) : super(renderBody: false);

  final Seesaw seesaw;

  /// The plank's thickness, in meters.
  static const thickness = 0.2;

  /// The plank's density: light, so it tips as soon as the ball passes the
  /// pivot.
  static const density = 0.5;

  /// How strongly the plank's turning is damped, per second.
  static const angularDamping = 0.5;

  /// The plank's friction, as the ground's.
  static const friction = 0.8;

  /// The angle at rest, near end down: negative turns the near end down.
  late final double restAngle = -math.asin(seesaw.rest / seesaw.halfLength);

  /// The angle when tipped forwards, far end down.
  late final double tipAngle = math.asin(seesaw.tip / seesaw.halfLength);

  late final Body _anchor;
  Picture? _plank;
  Picture? _fulcrum;

  @override
  FloorSurface get floorSurface => FloorSurface.plain;

  /// Whether the plank is tipped forwards, its far end down.
  bool get isTipped => body.angle > 0;

  @override
  bool supports(Vector2 center) {
    final local = body.localPoint(center);
    return local.y < -thickness / 2 &&
        local.x.abs() <= seesaw.halfLength + GroundSurface.edgeTolerance;
  }

  @override
  Body createBody() {
    // It turns about its centre of mass, half its thickness below the top
    // surface's pivot, so it stays balanced; its ends move by a millimetre.
    final pivot = Vector2(seesaw.pivot.x, seesaw.pivot.y + thickness / 2);
    _anchor = world.createBody(BodyDef(position: pivot));
    final half = seesaw.halfLength;
    final plank =
        world.createBody(
          BodyDef(
            type: BodyType.dynamic,
            position: pivot,
            rotation: Rot.fromAngle(restAngle),
            angularDamping: angularDamping,
          ),
        )..createShape(
          Polygon.box(half, thickness / 2),
          ShapeDef(
            density: density,
            material: SurfaceMaterial(friction: friction),
            enableContactEvents: true,
            userData: this,
          ),
        );
    world.physicsWorld.createRevoluteJoint(
      RevoluteJointDef(
        bodyA: _anchor,
        bodyB: plank,
        enableLimit: true,
        lowerAngle: restAngle,
        upperAngle: tipAngle,
      ),
    );
    return plank;
  }

  /// Puts the plank back at rest, still: a respawn (level-mechanics spec).
  void restore() {
    body
      ..setTransform(body.position, Rot.fromAngle(restAngle))
      ..linearVelocity = Vector2.zero()
      ..angularVelocity = 0;
  }

  Picture _recordPlank() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final half = seesaw.halfLength;
    final plank = RRect.fromRectAndRadius(
      Rect.fromLTWH(-half, -thickness / 2, 2 * half, thickness),
      const Radius.circular(0.05),
    );
    canvas
      ..drawRRect(
        plank.shift(const Offset(0.04, 0.08)),
        Paint()..color = const Color(0x55000000),
      )
      ..drawRRect(
        plank,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(ElementPalette.wood, const Color(0xFFFFFFFF), 0.3)!,
              ElementPalette.wood,
              Color.lerp(ElementPalette.wood, ElementPalette.outline, 0.45)!,
            ],
          ).createShader(plank.outerRect),
      );
    // Grain, and metal bands near the ends and at the pivot.
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.015
      ..color = Color.lerp(ElementPalette.wood, ElementPalette.outline, 0.3)!;
    canvas
      ..drawLine(Offset(-half + 0.1, -0.03), Offset(half - 0.1, -0.03), grain)
      ..drawLine(Offset(-half + 0.3, 0.03), Offset(half - 0.3, 0.03), grain);
    final band = Paint()..color = const Color(0xFF5E6E7C);
    for (final x in [-half + 0.25, -0.12, half - 0.37]) {
      canvas.drawRect(Rect.fromLTWH(x, -thickness / 2, 0.12, thickness), band);
    }
    ElementPainter.outline(canvas, Path()..addRRect(plank), 0.035);
    return recorder.endRecording();
  }

  Picture _recordFulcrum() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    // A post down into the pit, then the fulcrum's triangle.
    const post = Rect.fromLTWH(-0.12, 0.5, 0.24, 30);
    canvas.drawRect(
      post,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2A3138), Color(0xFF5E6E7C), Color(0xFF2A3138)],
        ).createShader(post),
    );
    final fulcrum = Path()
      ..moveTo(0, thickness / 2)
      ..lineTo(0.35, 0.6)
      ..lineTo(-0.35, 0.6)
      ..close();
    canvas.drawPath(fulcrum, Paint()..color = const Color(0xFF39444E));
    ElementPainter.outline(canvas, fulcrum, 0.03);
    canvas.drawCircle(
      Offset.zero,
      0.07,
      Paint()..color = const Color(0xFFB9C6D2),
    );
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    // The fulcrum stays upright while the plank turns.
    canvas
      ..save()
      ..rotate(-body.angle)
      ..drawPicture(_fulcrum ??= _recordFulcrum())
      ..restore()
      ..drawPicture(_plank ??= _recordPlank());
  }

  @override
  void onRemove() {
    _plank?.dispose();
    _plank = null;
    _fulcrum?.dispose();
    _fulcrum = null;
    if (_anchor.isValid) world.destroyBody(_anchor);
    super.onRemove();
  }
}
