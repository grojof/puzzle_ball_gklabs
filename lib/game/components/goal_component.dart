import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';

class GoalComponent extends BodyComponent with ContactCallbacks {
  GoalComponent({
    required this.position,
    required this.size,
    Paint? paint,
  }) : _customPaint = paint ?? (Paint()..color = const Color(0xFF81C784));

  @override
  final Vector2 position;

  final Vector2 size;

  late final Paint _customPaint;

  @override
  Paint get paint => _customPaint;

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
  void render(Canvas canvas) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    canvas.drawRect(rect, paint);
  }
}
