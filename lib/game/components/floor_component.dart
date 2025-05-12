import 'package:flame_forge2d/flame_forge2d.dart';

class FloorComponent extends BodyComponent {
  FloorComponent({
    required this.position,
    required this.size,
  });

  @override
  final Vector2 position;

  final Vector2 size;

  @override
  Body createBody() {
    final shape = PolygonShape()
      ..setAsBox(size.x / 2, size.y / 2, Vector2.zero(), 0);

    final fixtureDef = FixtureDef(shape)
      ..friction = 0.9
      ..restitution = 0.0;

    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = position + size / 2;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
