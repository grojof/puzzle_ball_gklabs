import 'package:flame/cache.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/ball_envelope.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/components/boost_component.dart';

import '../helpers/game_helpers.dart';

const double _dt = 1 / 60;

/// Proves the real physics reaches every number of [ballEnvelope], so levels
/// stay completable when the physics is tuned (level-generation spec).
void main() {
  late Images images;
  setUpAll(() async => images = await testImages());

  /// A game whose ball rests on the ground, with input removed so the test
  /// drives the intent directly.
  Future<double> prepare(BallOdysseyGame game) async {
    game.input!.removeFromParent();
    await game.ready();
    final ball = game.level!.ball;
    for (var i = 0; i < 120 && !ball.isOnGround; i++) {
      game.update(_dt);
    }
    return ball.body.position.y;
  }

  /// Pushes right for [seconds], teleporting back to stay on the floor.
  void push(BallOdysseyGame game, double groundY, double seconds) {
    final ball = game.level!.ball;
    game.intent.horizontal = 1;
    for (var t = 0.0; t < seconds; t += _dt) {
      game.update(_dt);
      if (ball.body.position.x > 12) {
        ball.body.setTransform(Vector2(1, groundY), const Rot.identity());
      }
    }
  }

  /// Flies until the ball is back at [groundY]; returns (distance, height).
  (double, double) fly(BallOdysseyGame game, double groundY) {
    final ball = game.level!.ball;
    final x0 = ball.body.position.x;
    var peak = groundY;
    for (var i = 0; i < 600; i++) {
      game.update(_dt);
      final p = ball.body.position;
      if (p.y < peak) peak = p.y;
      if (i > 5 && p.y >= groundY) break;
    }
    return (ball.body.position.x - x0, groundY - peak);
  }

  /// Long enough that boosted jumps land before the goal.
  BallOdysseyGame longGame() =>
      testGame(images: images, levelFor: (_) => flatLevel(tiles: 40));

  group('the ball reaches the movement envelope', () {
    testWithGame('standing jump height', () => testGame(images: images), (
      game,
    ) async {
      final ground = await prepare(game);
      game.intent.requestJump();
      final (_, height) = fly(game, ground);
      expect(height, greaterThanOrEqualTo(ballEnvelope.jumpHeight));
    });

    testWithGame(
      'top speed, its acceleration and the running jump',
      () => testGame(images: images),
      (game) async {
        final ground = await prepare(game);
        final ball = game.level!.ball;
        push(game, ground, ballEnvelope.timeToTopSpeed);
        expect(
          ball.body.linearVelocity.x,
          greaterThanOrEqualTo(ballEnvelope.topSpeed * 0.95),
        );
        push(game, ground, 1);
        expect(
          ball.body.linearVelocity.x,
          greaterThanOrEqualTo(ballEnvelope.topSpeed),
        );
        ball.body.setTransform(Vector2(1, ground), const Rot.identity());
        game.intent.requestJump();
        final (distance, _) = fly(game, ground);
        expect(
          distance,
          greaterThanOrEqualTo(
            ballEnvelope.maxGap(
              speed: ballEnvelope.topSpeed,
              rise: 0,
              margin: 1,
            ),
          ),
        );
      },
    );

    testWithGame('jump boost height', () => testGame(images: images), (
      game,
    ) async {
      final ground = await prepare(game);
      game.level!.ball.applyJumpBoost(BoostComponent.jumpImpulse);
      final (_, height) = fly(game, ground);
      expect(height, greaterThanOrEqualTo(ballEnvelope.jumpBoostHeight));
    });

    testWithGame('speed boost jump', longGame, (game) async {
      final ground = await prepare(game);
      final ball = game.level!.ball;
      push(game, ground, 3);
      ball.applySpeedBoost(BoostComponent.speedImpulse, Vector2(1, 0));
      game.update(_dt);
      ball.body.setTransform(Vector2(1, ground), const Rot.identity());
      game.intent.requestJump();
      final (distance, _) = fly(game, ground);
      expect(
        distance,
        greaterThanOrEqualTo(ballEnvelope.speedBoostJumpDistance),
      );
    });

    testWithGame('gravity boost jump', longGame, (game) async {
      final ground = await prepare(game);
      final ball = game.level!.ball;
      push(game, ground, 3);
      ball
        ..body.setTransform(Vector2(1, ground), const Rot.identity())
        ..applyGravityBoost(BoostComponent.gravityScale);
      game.intent.requestJump();
      final (distance, _) = fly(game, ground);
      expect(
        distance,
        greaterThanOrEqualTo(ballEnvelope.gravityBoostJumpDistance),
      );
    });
  });
}
