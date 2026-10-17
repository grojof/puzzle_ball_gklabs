import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Forge2D on the test host', () {
    testWithGame<Forge2DGame>(
      'steps a dynamic body under gravity and destroys the world',
      () => Forge2DGame(gravity: Vector2(0, 10)),
      (game) async {
        final body = game.world.createBody(BodyDef(type: BodyType.dynamic))
          ..createShape(Circle(radius: 0.2), ShapeDef());

        for (var i = 0; i < 30; i++) {
          game.update(1 / 60);
        }

        expect(body.position.y, greaterThan(0));

        game.world.physicsWorld.destroy();
        expect(game.world.physicsWorld.isValid, isFalse);
      },
    );
  });
}
