import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/image_composition.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class RampComponent extends BodyComponent with ContactCallbacks {
  RampComponent({
    required this.position,
    required this.size,
    this.inverted = false,
    this.sprite,
    this.friction = 0.6,
    this.restitution = 0.0,
  });

  @override
  final Vector2 position;
  final Vector2 size;
  final bool inverted;
  final double friction;
  final double restitution;
  final Sprite? sprite;

  late final List<Vector2> vertices;
  Image? texture;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    if (sprite != null) {
      texture = sprite!.image;
    }
  }

  @override
  Body createBody() {
    final halfW = size.x / 2;
    final halfH = size.y / 2;

    vertices = inverted
        ? [
            Vector2(-halfW, halfH),
            Vector2(halfW, halfH),
            Vector2(-halfW, -halfH),
          ]
        : [
            Vector2(-halfW, halfH),
            Vector2(halfW, halfH),
            Vector2(halfW, -halfH),
          ];

    final shape = PolygonShape()..set(vertices);

    final fixtureDef = FixtureDef(shape)
      ..friction = friction
      ..restitution = restitution
      ..userData = this;

    final bodyDef = BodyDef()
      ..type = BodyType.static
      ..position = position + size / 2;

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }

  @override
  void render(Canvas canvas) {
    if (texture != null) {
      final src = Rect.fromLTWH(
        0,
        0,
        texture!.width.toDouble(),
        texture!.height.toDouble(),
      );
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: size.x,
        height: size.y,
      );

      canvas.save();
      final path = Path()
        ..moveTo(vertices[0].x, vertices[0].y)
        ..lineTo(vertices[1].x, vertices[1].y)
        ..lineTo(vertices[2].x, vertices[2].y)
        ..close();

      canvas
        ..clipPath(path) // ← Recorta la textura con la forma triangular
        ..drawImageRect(texture!, src, dst, Paint())
        ..restore();
    } else {
      final path = Path()
        ..moveTo(vertices[0].x, vertices[0].y)
        ..lineTo(vertices[1].x, vertices[1].y)
        ..lineTo(vertices[2].x, vertices[2].y)
        ..close();

      canvas.drawPath(path, Paint()..color = const Color(0xFF90CAF9));
    }
  }
}
