import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/hud_layout.dart';
import 'package:puzzle_ball_gklabs/game/components/joystick_parts.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// The on-screen jump button: in the bottom-right corner, sized for the
/// thumb, a glossy orb with an up arrow and a pressed state. While a
/// double-jump charge is held, it takes the orb's color with a second arrow
/// and a ring (player-controls spec).
class JumpButtonComponent extends PositionComponent with TapCallbacks {
  new({required this.onPressed, bool Function()? isCharged})
    : _isCharged = isCharged ?? _never,
      super(anchor: Anchor.bottomRight);

  final VoidCallback onPressed;
  final bool Function() _isCharged;

  static bool _never() => false;

  static final _arrow = Paint()..color = const Color(0xFFFFFFFF);
  static final _arrowShadow = Paint()..color = const Color(0x66000000);

  bool _pressed = false;

  /// Each look, recorded for the current size.
  final Map<(bool, bool), Picture> _art = {};

  /// Whether the button is held down.
  bool get isPressed => _pressed;

  /// Whether the button shows the double-jump charge.
  bool get showsCharge => _isCharged();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final side = HudLayout.controlSize(size);
    if (this.size.x != side) _clearArt();
    this.size = Vector2.all(side);
    final margin = HudLayout.margin(size);
    position = Vector2(size.x - margin, size.y - margin);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _pressed = true;
    onPressed();
  }

  @override
  void onTapUp(TapUpEvent event) => _pressed = false;

  @override
  void onTapCancel(TapCancelEvent event) => _pressed = false;

  Picture _record({required bool pressed, required bool charged}) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final diameter = size.x;
    final r = diameter / 2;
    final base = charged ? ElementPalette.orb : controlSteel;
    final color = pressed
        ? Color.lerp(base, const Color(0xFFFFFFFF), 0.35)!
        : base;
    canvas
      ..save()
      ..translate(r, r);
    if (charged) {
      // A ring around the button, in the orb's color.
      canvas.drawCircle(
        Offset.zero,
        r * 1.08,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.1
          ..color = ElementPalette.orb,
      );
    }
    ElementPainter.orb(canvas, r * 0.94, color);
    canvas.restore();
    final arrow = charged ? doubleArrowPath(diameter) : arrowPath(diameter);
    canvas
      ..drawPath(
        arrow.shift(Offset(diameter * 0.015, diameter * 0.02)),
        _arrowShadow,
      )
      ..drawPath(arrow, _arrow);
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final charged = showsCharge;
    canvas.drawPicture(
      _art[(_pressed, charged)] ??= _record(
        pressed: _pressed,
        charged: charged,
      ),
    );
  }

  void _clearArt() {
    for (final picture in _art.values) {
      picture.dispose();
    }
    _art.clear();
  }

  @override
  void onRemove() {
    _clearArt();
    super.onRemove();
  }

  /// An up arrow centred in a button [diameter] across: a head over a
  /// shaft.
  static Path arrowPath(double diameter) {
    final c = diameter / 2;
    final unit = diameter / 10;
    return Path()
      ..moveTo(c, c - 3 * unit)
      ..lineTo(c + 2.5 * unit, c)
      ..lineTo(c + unit, c)
      ..lineTo(c + unit, c + 3 * unit)
      ..lineTo(c - unit, c + 3 * unit)
      ..lineTo(c - unit, c)
      ..lineTo(c - 2.5 * unit, c)
      ..close();
  }

  /// Two arrow heads stacked upwards, centred in a button [diameter]
  /// across: the jump and the charged air jump.
  static Path doubleArrowPath(double diameter) {
    final c = diameter / 2;
    final unit = diameter / 10;
    final path = Path();
    for (final top in [c - 3.2 * unit, c - 0.2 * unit]) {
      path
        ..moveTo(c, top)
        ..lineTo(c + 2.5 * unit, top + 2.4 * unit)
        ..lineTo(c + 1.4 * unit, top + 2.4 * unit)
        ..lineTo(c, top + 1.1 * unit)
        ..lineTo(c - 1.4 * unit, top + 2.4 * unit)
        ..lineTo(c - 2.5 * unit, top + 2.4 * unit)
        ..close();
    }
    return path;
  }
}
