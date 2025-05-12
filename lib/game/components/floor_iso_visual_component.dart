import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

class FloorIsoVisualComponent extends PositionComponent {
  FloorIsoVisualComponent({
    required this.body,
    required Vector2 visualSize,
    required this.paint,
  }) : _visualSize = visualSize;

  final Body body;
  final Vector2 _visualSize;
  final Paint paint;

  @override
  void render(Canvas canvas) {
    final iso = _isoProject(body.position);

    canvas
      ..save()
      ..translate(iso.dx, iso.dy)
      ..drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: _visualSize.x,
          height: _visualSize.y,
        ),
        paint,
      )
      ..restore();
  }

  @override
  void update(double dt) {
    // Sync position with body
    position = _isoProject(body.position).toVector2();
  }

  Offset _isoProject(Vector2 p) {
    const isoAngle = 0.5;
    final x = p.x - p.y;
    final y = (p.x + p.y) * isoAngle;
    return Offset(x, y);
  }
}
