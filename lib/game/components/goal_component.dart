import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';

class GoalComponent extends BodyComponent {
  GoalComponent({
    required this.position,
    required this.size,
    required Paint paint,
  }) {
    _paint = paint;
  }

  @override
  final Vector2 position;
  final Vector2 size;

  late final Paint _paint;

  @override
  Paint get paint => _paint;

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0);

    final fixtureDef = FixtureDef(shape)
      ..isSensor = true
      ..userData = this;

    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = position + size / 2;

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
