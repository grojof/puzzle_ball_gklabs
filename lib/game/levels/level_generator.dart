import 'dart:math';
import 'package:flame/extensions.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';

class LevelGenerator {
  /// Tamaño físico total del nivel (para paredes o límites laterales)
  static const Size levelSize = Size(800, 600);

  /// Genera un nivel isométrico con [segmentCount] pasos conectados.
  /// [seed] garantiza aleatoriedad reproducible.
  static LevelData generate(
    int seed, {
    int segmentCount = 14,
    double stepX = 60.0,
    double stepY = 30.0,
  }) {
    final rand = Random(seed);

    const platformSize = Size(80, 20);

    final floors = <Rect>[];
    final walls = <Rect>[];
    final obstacles = <Rect>[];

    // Punto de inicio visible para la primera plataforma
    var x = 80.0;
    var y = 400.0;

    // Punto en el que puede generarse una bifurcación
    final forkAt = rand.nextInt(segmentCount - 4) + 2;

    for (var i = 0; i < segmentCount; i++) {
      // Suelo principal
      floors.add(Rect.fromLTWH(x, y, platformSize.width, platformSize.height));

      // Bifurcación opcional
      if (i == forkAt) {
        final forkY = y + (rand.nextBool() ? stepY : -stepY);
        final forkX = x + platformSize.width + stepX;
        floors.add(Rect.fromLTWH(
            forkX, forkY, platformSize.width, platformSize.height));
      }

      // Obstáculo opcional centrado en el suelo
      if (i > 2 && rand.nextDouble() < 0.3) {
        obstacles
            .add(Rect.fromLTWH(x + platformSize.width / 4, y - 20, 30, 30));
      }

      // Movimiento en diagonal (efecto isométrico falso)
      x += stepX + rand.nextInt(10);
      y -= stepY + rand.nextInt(10);
    }

    // Paredes laterales
    walls
      ..add(Rect.fromLTWH(0, 0, 20, levelSize.height))
      ..add(Rect.fromLTWH(levelSize.width - 20, 0, 20, levelSize.height));

    final ballStart = Vector2(floors.first.left + 10, floors.first.top - 30);
    final goalPos = Vector2(floors.last.center.dx, floors.last.top - 20);

    return LevelData(
      ballStart: ballStart,
      goalPosition: goalPos,
      walls: walls,
      floors: floors,
      obstacles: obstacles,
    );
  }
}
