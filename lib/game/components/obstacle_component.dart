import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';

class ObstacleComponent extends BodyComponent {
  ObstacleComponent({
    required this.position,
    required this.size,
    Paint? paint,
    this.friction = 0.5,
    this.restitution = 0.3,
  }) {
    this.paint = paint ?? (Paint()..color = const Color(0xFFD32F2F));
  }

  @override
  final Vector2 position;
  final Vector2 size;
  final double friction;
  final double restitution;

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(
        size.x / 2,
        size.y / 2,
        Vector2.zero(),
        0,
      );

    final fixtureDef = FixtureDef(shape)
      ..friction = friction
      ..restitution = restitution;

    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = position;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
      paint,
    );
  }
}
