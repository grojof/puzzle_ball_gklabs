import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';

/// Componente que da un salto extra al tocarlo
class JumpBoostComponent extends BodyComponent with ContactCallbacks {
  JumpBoostComponent({
    required this.position,
    required this.size,
    this.force = 120,
    this.color = const Color(0xFF42A5F5),
    this.sprite,
  });

  @override
  final Vector2 position;
  final Vector2 size;
  final double force;
  final Color color;
  final dynamic sprite; // Para futuro uso con Flame Sprite

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
    if (other is BallComponent) {
      other.body.applyLinearImpulse(Vector2(0, -force));
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

/// Componente que da un empujón de velocidad horizontal
class SpeedBoostComponent extends BodyComponent with ContactCallbacks {
  SpeedBoostComponent({
    required this.position,
    required this.size,
    this.force = 100,
    Vector2? direction,
    this.color = const Color(0xFFFFA726),
    this.sprite,
  }) : direction = direction ?? Vector2(1, 0);

  @override
  final Vector2 position;
  final Vector2 size;
  final double force;
  final Vector2 direction;
  final Color color;
  final dynamic sprite;

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
    if (other is BallComponent) {
      other.body.applyLinearImpulse(direction.normalized() * force);
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

/// Componente que reduce la gravedad de la bola temporalmente
class GravityBoostComponent extends BodyComponent with ContactCallbacks {
  GravityBoostComponent({
    required this.position,
    required this.size,
    this.duration = 2.0,
    this.gravityScale = 0.1,
    this.color = const Color(0xFFB39DDB),
    this.sprite,
  });

  @override
  final Vector2 position;
  final Vector2 size;
  final double duration;
  final double gravityScale;
  final Color color;
  final dynamic sprite;

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
    if (other is BallComponent) {
      // Solo modifica gravityScale, no density
      final originalGravity = other.body.gravityScale?.y ?? 1.0;
      other.body.gravityScale = Vector2(0, gravityScale);
      Future.delayed(Duration(milliseconds: (duration * 1000).toInt()), () {
        if (other.body.isActive) {
          other.body.gravityScale = Vector2(0, originalGravity);
        }
      });
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
