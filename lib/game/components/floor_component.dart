import 'dart:ui';

import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class FloorComponent extends BodyComponent {
  FloorComponent({
    required this.position,
    required this.size,
    this.color = const Color(0xFF8BC34A),
  });

  @override
  final Vector2 position;

  final Vector2 size;
  final Color color;

  static const double isoAngle = 0.5;

  late final Paint _paint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _paint = Paint()..color = color;
  }

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

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final iso = _isoProject(body.position);

    final halfW = size.x / 2;
    final halfH = size.x * isoAngle / 2;

    final path = Path()
      ..moveTo(iso.dx, iso.dy - halfH)
      ..lineTo(iso.dx + halfW, iso.dy)
      ..lineTo(iso.dx, iso.dy + halfH)
      ..lineTo(iso.dx - halfW, iso.dy)
      ..close();

    canvas.drawPath(path, _paint);
  }

  Offset _isoProject(Vector2 p) {
    final x = p.x - p.y;
    final y = (p.x + p.y) * isoAngle;
    return Offset(x, y);
  }
}
