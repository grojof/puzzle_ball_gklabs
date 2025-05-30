import 'package:flame/components.dart';
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
  final Sprite? sprite; // Para futuro uso con Flame Sprite

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
      other.applyJumpBoost(force);
    }
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
      other.applySpeedBoost(force: force, direction: direction);
    }
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
      other.applyGravityBoost(
        gravityScale: gravityScale,
        duration: duration,
      );
    }
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
