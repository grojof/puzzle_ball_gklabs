import 'dart:math';
import 'package:flame/extensions.dart';
import 'package:puzzle_ball_gklabs/game/levels/level_data.dart';

class LevelGenerator {
  static const Size levelSize = Size(800, 600);

  static LevelData generate(int seed) {
    final rand = Random(seed);

    const platformSize = Size(80, 20);
    const totalSegments = 14;

    final floors = <Rect>[];
    final walls = <Rect>[];
    final obstacles = <Rect>[];

    var x = 40.0;
    var y = 400.0;
    final forkAt = rand.nextInt(totalSegments - 4) + 2;

    for (var i = 0; i < totalSegments; i++) {
      floors.add(Rect.fromLTWH(x, y, platformSize.width, platformSize.height));

      // Bifurcación visual
      if (i == forkAt) {
        final forkY = y + (rand.nextBool() ? 40 : -40);
        final forkX = x + platformSize.width + 40;
        floors.add(
          Rect.fromLTWH(
            forkX,
            forkY,
            platformSize.width,
            platformSize.height,
          ),
        );
      }

      // Obstáculos centrados en la plataforma
      if (i > 2 && rand.nextDouble() < 0.3) {
        obstacles
            .add(Rect.fromLTWH(x + platformSize.width / 4, y - 20, 30, 30));
      }

      // Camino en diagonal superior derecha (perspectiva isométrica falsa)
      x += 60 + rand.nextInt(20); // avanza en X
      y -= 40 + rand.nextInt(10); // sube en Y = más lejos visualmente
    }

    // Muros verticales al inicio y final
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
