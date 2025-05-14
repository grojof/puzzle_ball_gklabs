import 'dart:ui';
import 'package:flame/components.dart';

/// Dibuja una cuadrícula isométrica perfecta con rombos sin separación para debug.
class IsoGridDebugComponent extends Component {
  IsoGridDebugComponent({
    this.columns = 30,
    this.rows = 30,
    this.angle = 0.5,
    this.color = const Color(0x44888888),
  });

  final int columns;
  final int rows;
  final double angle;
  final Color color;

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;

    const cellWidth = 80.0;

    final originX = -columns ~/ 2 * cellWidth;
    final originY = -rows ~/ 2 * cellWidth;

    // Líneas diagonales ↘ (de izquierda a derecha)
    for (var row = 0; row <= rows; row++) {
      final start = _isoProject(Vector2(originX, originY + row * cellWidth));
      final end = _isoProject(
          Vector2(originX + columns * cellWidth, originY + row * cellWidth));
      canvas.drawLine(start, end, paint);
    }

    // Líneas diagonales ↙ (de derecha a izquierda)
    for (var col = 0; col <= columns; col++) {
      final start = _isoProject(Vector2(originX + col * cellWidth, originY));
      final end = _isoProject(
          Vector2(originX + col * cellWidth, originY + rows * cellWidth));
      canvas.drawLine(start, end, paint);
    }
  }

  Offset _isoProject(Vector2 p) {
    final x = p.x - p.y;
    final y = (p.x + p.y) * angle;
    return Offset(x, y);
  }
}
