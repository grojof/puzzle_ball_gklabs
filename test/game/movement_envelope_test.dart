import 'package:flame/cache.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart' show MovementEnvelope;
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

  /// A long flat level, so runs and boosted jumps land before the goal.
  BallOdysseyGame longGame() =>
      testGame(images: images, levelFor: (_) => flatLevel(tiles: 80));

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
      if (ball.body.position.x > 90) {
        ball.body.setTransform(Vector2(5, groundY), const Rot.identity());
      }
    }
  }

  /// Flies until the ball is back at [groundY]; returns (distance, height).
  /// With [airJump], uses the charged air jump at the apex.
  (double, double) fly(
    BallOdysseyGame game,
    double groundY, {
    bool airJump = false,
  }) {
    final ball = game.level!.ball;
    final x0 = ball.body.position.x;
    var peak = groundY;
    var used = false;
    for (var i = 0; i < 900; i++) {
      game.update(_dt);
      final p = ball.body.position;
      if (p.y < peak) peak = p.y;
      if (airJump && !used && i > 3 && ball.body.linearVelocity.y >= 0) {
        used = true;
        game.intent.requestJump();
      }
      if (i > 5 && p.y >= groundY - 0.02) break;
    }
    return (ball.body.position.x - x0, groundY - peak);
  }

  /// Reaches top speed, then sets off from x 5.
  void runUp(BallOdysseyGame game, double ground) {
    push(game, ground, 5);
    game.level!.ball.body.setTransform(
      Vector2(5, ground),
      const Rot.identity(),
    );
  }

  group('the ball reaches the movement envelope', () {
    testWithGame('standing jump and double jump heights', longGame, (
      game,
    ) async {
      final ground = await prepare(game);
      game.intent.requestJump();
      final (_, height) = fly(game, ground);
      expect(height, greaterThanOrEqualTo(ballEnvelope.jumpHeight));

      for (var i = 0; i < 60; i++) {
        game.update(_dt);
      }
      game.level!.ball.chargeAirJump();
      game.intent.requestJump();
      final (_, double) = fly(game, ground, airJump: true);
      expect(double, greaterThanOrEqualTo(ballEnvelope.doubleJumpHeight));
    });

    testWithGame('the speed curve from rest', longGame, (game) async {
      await prepare(game);
      final ball = game.level!.ball;
      final x0 = ball.body.position.x;
      game.intent.horizontal = 1;
      var sample = 1;
      while (sample <= ballEnvelope.speedCurve.length) {
        game.update(_dt);
        final distance = ball.body.position.x - x0;
        if (distance >= sample * MovementEnvelope.curveStep) {
          expect(
            ball.body.linearVelocity.x,
            greaterThanOrEqualTo(ballEnvelope.speedCurve[sample - 1]),
            reason: 'at $distance m',
          );
          sample++;
        }
      }
    });

    testWithGame('top speed, running jump and double jump', longGame, (
      game,
    ) async {
      final ground = await prepare(game);
      final ball = game.level!.ball;
      push(game, ground, 5);
      expect(
        ball.body.linearVelocity.x,
        greaterThanOrEqualTo(ballEnvelope.topSpeed),
      );
      runUp(game, ground);
      game.intent.requestJump();
      final (distance, _) = fly(game, ground);
      expect(
        distance,
        greaterThanOrEqualTo(
          ballEnvelope.maxGap(speed: ballEnvelope.topSpeed, rise: 0, margin: 1),
        ),
      );

      runUp(game, ground);
      ball.chargeAirJump();
      game.intent.requestJump();
      final (doubleDistance, _) = fly(game, ground, airJump: true);
      expect(
        doubleDistance,
        greaterThanOrEqualTo(ballEnvelope.doubleJumpDistance),
      );
    });

    testWithGame('jump boost height', longGame, (game) async {
      final ground = await prepare(game);
      game.level!.ball.applyJumpBoost(BoostComponent.jumpImpulse);
      final (_, height) = fly(game, ground);
      expect(height, greaterThanOrEqualTo(ballEnvelope.jumpBoostHeight));
    });

    testWithGame('speed boost jump', longGame, (game) async {
      final ground = await prepare(game);
      final ball = game.level!.ball;
      push(game, ground, 5);
      ball.applySpeedBoost(BoostComponent.speedImpulse, Vector2(1, 0));
      game.update(_dt);
      ball.body.setTransform(Vector2(5, ground), const Rot.identity());
      game.intent.requestJump();
      final (distance, _) = fly(game, ground);
      expect(
        distance,
        greaterThanOrEqualTo(ballEnvelope.speedBoostJumpDistance),
      );

      // Picked up from rest, the boost adds its gain alone.
      for (var i = 0; i < 120; i++) {
        game.update(_dt);
      }
      game.intent.horizontal = 0;
      for (var i = 0; i < 300; i++) {
        game.update(_dt);
      }
      ball.body
        ..setTransform(Vector2(5, ground), const Rot.identity())
        ..linearVelocity = Vector2.zero()
        ..angularVelocity = 0;
      ball.applySpeedBoost(BoostComponent.speedImpulse, Vector2(1, 0));
      expect(
        ball.body.linearVelocity.x,
        greaterThanOrEqualTo(ballEnvelope.speedBoostGain),
      );
      game.intent.horizontal = 1;
      game.update(_dt);
      game.intent.requestJump();
      final (fromRest, _) = fly(game, ground);
      expect(
        fromRest,
        greaterThanOrEqualTo(
          ballEnvelope.maxSpeedBoostGap(speed: 0, margin: 1),
        ),
      );
    });

    testWithGame('gravity boost jump', longGame, (game) async {
      final ground = await prepare(game);
      runUp(game, ground);
      game.level!.ball.applyGravityBoost(BoostComponent.gravityScale);
      game.intent.requestJump();
      final (distance, _) = fly(game, ground);
      expect(
        distance,
        greaterThanOrEqualTo(ballEnvelope.gravityBoostJumpDistance),
      );
    });
  });
}
