import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';

class GoalComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.position,
    required this.size,
    this.color = const Color(0xFF43A047),
    this.sprite,
  });

  @override
  final Vector2 position;
  final Vector2 size;
  final Color color;
  final Sprite? sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (sprite != null) {
      final spriteComponent = SpriteComponent(
        sprite: sprite,
        size: size,
        anchor: Anchor.center,
      );
      add(spriteComponent);
    }
  }

  @override
  Body createBody() {
    return world.createBody(BodyDef(position: position))..createShape(
      Polygon.box(size.x / 2, size.y / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void render(Canvas canvas) {
    if (sprite == null) {
      final paint = Paint()..color = color;
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
        paint,
      );
    }
  }
}
