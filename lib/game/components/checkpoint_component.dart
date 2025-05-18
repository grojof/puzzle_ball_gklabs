import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';

/// Componente de checkpoint para respawn
class CheckPointComponent extends BodyComponent with ContactCallbacks {
  CheckPointComponent({
    required this.position,
    required this.size,
    this.color = const Color(0xFF43A047),
    this.sprite,
  });

  @override
  final Vector2 position;
  final Vector2 size;
  final Color color;
  final dynamic sprite;

  bool activated = false;

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
      ..isSensor = true
      ..userData = this;
    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = position;
    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallComponent && !activated) {
      activated = true;
      // TODO: notificar al juego para actualizar el respawn
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
      paint,
    );
    // TODO: dibujar sprite si se define
  }
}
