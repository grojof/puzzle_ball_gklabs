import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';

class JumpButtonComponent extends PositionComponent
    with HasGameReference<Forge2DGame>, TapCallbacks {
  JumpButtonComponent({
    required this.onPressed,
    required Vector2 size,
    this.color = const Color(0xFF42A5F5),
    this.pressedColor = const Color(0xFF90CAF9),
    this.margin = const EdgeInsets.only(right: 20, bottom: 20),
    this.isEnabled = true,
  }) : _paint = Paint()..color = color {
    this.size = size;
    anchor = Anchor.bottomRight;
  }

  final VoidCallback onPressed;
  final Color color;
  final Color pressedColor;
  final EdgeInsets margin;

  bool isPressed = false;
  bool isEnabled;

  late final Paint _paint;

  @override
  void onTapDown(TapDownEvent event) {
    isPressed = true;
    onPressed();
  }

  @override
  void onTapUp(TapUpEvent event) {
    isPressed = false;
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    isPressed = false;
  }

  @override
  void update(double dt) {
    super.update(dt);

    final viewportSize = game.size;
    position = Vector2(
      viewportSize.x - margin.right,
      viewportSize.y - margin.bottom,
    );

    // Actualiza el color dinámicamente según estado
    final targetColor = isPressed ? pressedColor : color;
    _paint.color =
        isEnabled ? targetColor.withOpacity(1.0) : targetColor.withOpacity(0.3);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawCircle(size.toOffset() / 2, size.x / 2, _paint);
  }

  /// Puedes usar este setter desde el game para actualizar si puede saltar
  bool get enabled => isEnabled;
  set enabled(bool value) {
    isEnabled = value;
  }
}
