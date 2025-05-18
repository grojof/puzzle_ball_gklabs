import 'dart:ui';
import 'package:flame/components.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';

/// Dibuja una cuadrícula isométrica perfecta con rombos sin separación para debug.
class IsoGridDebugComponent extends Component {
  IsoGridDebugComponent({
    required this.gridConfig,
    this.columns = 30,
    this.rows = 30,
    this.color = const Color(0x44888888),
  });

  final IsoGridConfig gridConfig;
  final int columns;
  final int rows;
  final Color color;

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;

    final cellW = gridConfig.cellWidth;
    final cellH = gridConfig.cellHeight;

    final originX = -columns ~/ 2 * cellW;
    final originY = -rows ~/ 2 * cellH;

    for (var row = 0; row <= rows; row++) {
      final start =
          gridConfig.isoProject(Vector2(originX, originY + row * cellH));
      final end = gridConfig.isoProject(
          Vector2(originX + columns * cellW, originY + row * cellH));
      canvas.drawLine(start, end, paint);
    }

    for (var col = 0; col <= columns; col++) {
      final start =
          gridConfig.isoProject(Vector2(originX + col * cellW, originY));
      final end = gridConfig
          .isoProject(Vector2(originX + col * cellW, originY + rows * cellH));
      canvas.drawLine(start, end, paint);
    }
  }
}
