import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class BallIsoVisualComponent extends PositionComponent {
  BallIsoVisualComponent({
    required this.body,
    required this.radius,
    required this.paint,
  });

  final Body body;
  final double radius;
  final Paint paint;

  @override
  void render(Canvas canvas) {
    final iso = _isoProject(body.position);

    canvas
      ..save()
      ..translate(iso.dx, iso.dy)
      ..drawCircle(Offset.zero, radius, paint)
      ..restore();
  }

  @override
  void update(double dt) {
    position = _isoProject(body.position).toVector2();
  }

  Offset _isoProject(Vector2 p) {
    const isoAngle = 0.5;
    final x = p.x - p.y;
    final y = (p.x + p.y) * isoAngle;
    return Offset(x, y);
  }
}
