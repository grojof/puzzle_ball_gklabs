import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A strip of spikes on the ground: a sensor that sends the ball back when
/// it touches them (level-mechanics spec), drawn as metal spikes with red
/// tips (game-visuals spec).
class SpikeComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.left,
    required this.ground,
    required this.width,
    required this.onTouched,
  }) : super(renderBody: false);

  /// How tall the spikes are drawn, in meters.
  static const height = 0.36;

  /// How tall the sensor is, in meters: lower than the drawn tips, so a
  /// ball clearing the strip by a hair is not sent back.
  static const sensorHeight = 0.15;

  /// How far the sensor stays inside each end of the strip, in meters: the
  /// ball's radius, so the strip is as wide to clear as a gap of its width.
  static const sensorInset = 0.2;

  /// The width of one spike at its base, in meters.
  static const spikeWidth = 0.3;

  /// The strip's left end, in meters.
  final double left;

  /// The ground the strip lies on, in world y.
  final double ground;

  /// The strip's length, in meters.
  final double width;

  /// Called when the ball touches the spikes.
  final VoidCallback onTouched;

  Picture? _art;

  late final Rect _worldBounds = Rect.fromLTWH(
    left,
    ground - height,
    width,
    height,
  );

  @override
  Body createBody() {
    final halfWidth = (width / 2 - sensorInset).clamp(0.05, width / 2);
    return world.createBody(
      BodyDef(position: Vector2(left + width / 2, ground - sensorHeight / 2)),
    )..createShape(
      Polygon.box(halfWidth, sensorHeight / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallComponent) onTouched();
  }

  /// The spikes, recorded once relative to the body's centre.
  Picture _record() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final count = (width / spikeWidth).round().clamp(1, 1000);
    final step = width / count;
    const base = sensorHeight / 2;
    final x0 = -width / 2;
    final spikes = Path();
    final tips = Path();
    for (var i = 0; i < count; i++) {
      final l = x0 + i * step;
      final tip = Offset(l + step / 2, base - height);
      spikes
        ..moveTo(l, base)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(l + step, base)
        ..close();
      // The top third of each spike is red.
      tips
        ..moveTo(tip.dx - step / 6, tip.dy + height / 3)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + step / 6, tip.dy + height / 3)
        ..close();
    }
    final bounds = Rect.fromLTRB(x0, base - height, -x0, base);
    canvas
      // Shadow on the ground.
      ..drawRect(
        Rect.fromLTRB(x0, base - 0.04, -x0, base + 0.02),
        Paint()..color = const Color(0x66000000),
      )
      // Metal, lit from the top left.
      ..drawPath(
        spikes,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE8EDF2), Color(0xFF8A96A3), Color(0xFF4A5560)],
          ).createShader(bounds),
      )
      ..drawPath(tips, Paint()..color = ElementPalette.hazard);
    ElementPainter.outline(canvas, spikes, 0.03);
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    if (!game.camera.visibleWorldRect.overlaps(_worldBounds)) return;
    canvas.drawPicture(_art ??= _record());
  }

  @override
  void onRemove() {
    _art?.dispose();
    _art = null;
    super.onRemove();
  }
}
