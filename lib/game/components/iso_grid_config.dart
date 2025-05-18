import 'package:flame/extensions.dart';

class IsoGridConfig {
  const IsoGridConfig({
    required this.cellWidth,
    required this.cellHeight,
    required this.angle,
  });

  final double cellWidth;
  final double cellHeight;
  final double angle;

  /// Conversión de coordenadas de cuadrícula a mundo (Forge2D)
  Vector2 gridToWorld(int col, int row) {
    final x = col * cellWidth;
    final y = row * cellHeight;
    return Vector2(x, y);
  }

  /// Proyección isométrica visual
  Offset isoProject(Vector2 p) {
    final x = p.x - p.y;
    final y = (p.x + p.y) * angle;
    return Offset(x, y);
  }
}
