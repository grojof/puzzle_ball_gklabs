import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/hud_layout.dart';

/// The on-screen jump button: in the bottom-right corner, sized for the
/// thumb, with an up arrow and a pressed state (player-controls spec).
class JumpButtonComponent extends PositionComponent with TapCallbacks {
  new({required this.onPressed}) : super(anchor: Anchor.bottomRight);

  final VoidCallback onPressed;

  static final _fill = Paint()..color = const Color(0xCC1E88E5);
  static final _pressedFill = Paint()..color = const Color(0xFF90CAF9);
  static final _arrow = Paint()..color = const Color(0xFFFFFFFF);

  bool _pressed = false;

  /// Whether the button is held down.
  bool get isPressed => _pressed;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = Vector2.all(HudLayout.controlSize(size));
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

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    canvas
      ..drawCircle(
        Offset(radius, radius),
        radius,
        _pressed ? _pressedFill : _fill,
      )
      ..drawPath(arrowPath(size.x), _arrow);
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
}
