import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';

class FloorComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.position,
    required this.size,
    Paint? paint,
    this.sprite,
    this.friction = 0.8,
    this.restitution = 0.0,
  }) {
    this.paint = paint ?? (Paint()..color = const Color(0xFFE0E0E0));
  }

  @override
  final Vector2 position;
  final Vector2 size;
  final double friction;
  final double restitution;
  final Sprite? sprite;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final spriteComponent = SpriteComponent(
      sprite: sprite,
      size: size,
      anchor: Anchor.center,
    );
    add(spriteComponent);
  }

  @override
  Body createBody() {
    return world.createBody(
      BodyDef(position: position + size / 2),
    )..createShape(
      Polygon.box(size.x / 2, size.y / 2),
      ShapeDef(
        material: SurfaceMaterial(friction: friction, restitution: restitution),
        enableContactEvents: true,
        userData: this,
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    canvas.drawRect(rect, paint);
  }
}
