import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';

/// The steel of the on-screen controls: neutral, so the charged jump
/// button's color stands out (design D8 of add-physical-mechanics).
const controlSteel = Color(0xFF8C9BAA);

/// The joystick's base: a dark glass disc with a rim light and an inner
/// shadow, recorded once.
class JoystickBase extends PositionComponent {
  new({required double radius}) : super(size: Vector2.all(radius * 2));

  Picture? _art;

  Picture _record() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final r = size.x / 2;
    final center = Offset(r, r);
    final disc = Rect.fromCircle(center: center, radius: r);
    canvas
      // Dark glass, darker towards the centre.
      ..drawCircle(
        center,
        r,
        Paint()
          ..shader = const RadialGradient(
            colors: [Color(0x88101622), Color(0x660E0B16)],
          ).createShader(disc),
      )
      // Inner shadow along the top.
      ..drawArc(
        disc.deflate(r * 0.08),
        3.4,
        2.6,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.12
          ..color = const Color(0x55000000),
      )
      // Rim light.
      ..drawCircle(
        center,
        r - r * 0.03,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.05
          ..color = const Color(0x99FFFFFF),
      );
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) => canvas.drawPicture(_art ??= _record());

  @override
  void onRemove() {
    _art?.dispose();
    _art = null;
    super.onRemove();
  }
}

/// The joystick's knob: a glossy steel orb, recorded once.
class JoystickKnob extends PositionComponent {
  new({required double radius}) : super(size: Vector2.all(radius * 2));

  Picture? _art;

  Picture _record() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final r = size.x / 2;
    canvas.translate(r, r);
    ElementPainter.orb(canvas, r, controlSteel);
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) => canvas.drawPicture(_art ??= _record());

  @override
  void onRemove() {
    _art?.dispose();
    _art = null;
    super.onRemove();
  }
}
