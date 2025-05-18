import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';

class RampComponent extends BodyComponent with ContactCallbacks {
  RampComponent({
    required this.position,
    required this.size,
    this.inverted = false,
    Paint? paint,
    this.friction = 0.6,
    this.restitution = 0.0,
  }) {
    this.paint = paint ?? (Paint()..color = const Color(0xFF90CAF9));
  }

  @override
  final Vector2 position;
  final Vector2 size;
  final bool inverted;
  final double friction;
  final double restitution;

  late final List<Vector2> vertices;

  @override
  Body createBody() {
    final halfW = size.x / 2;
    final halfH = size.y / 2;

    vertices = inverted
        ? [
            Vector2(-halfW, halfH), // base izquierda
            Vector2(halfW, halfH), // base derecha
            Vector2(-halfW, -halfH), // vértice inclinado (arriba izquierda)
          ]
        : [
            Vector2(-halfW, halfH), // esquina inferior izquierda
            Vector2(halfW, halfH), // esquina inferior derecha
            Vector2(halfW, -halfH), // vértice inclinado (arriba derecha)
          ];

    final shape = PolygonShape()..set(vertices);

    final fixtureDef = FixtureDef(shape)
      ..friction = friction
      ..restitution = restitution
      ..userData = this;

    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = position;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    final path = Path()
      ..moveTo(vertices[0].x, vertices[0].y)
      ..lineTo(vertices[1].x, vertices[1].y)
      ..lineTo(vertices[2].x, vertices[2].y)
      ..close();

    canvas.drawPath(path, paint);
  }
}
