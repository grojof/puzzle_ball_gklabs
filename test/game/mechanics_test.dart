import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';

import '../helpers/game_helpers.dart';

const double _dt = 1 / 60;
const double _top = 4;

/// A start run, then [floors] and the goal run, with the given elements.
LevelData _level({
  List<FloorRun> floors = const [],
  List<SpikeStrip> hazards = const [],
  List<MovingPlatform> platforms = const [],
  List<Boost> boosts = const [],
  List<double> checkpoints = const [],
  double goalLeft = 30,
}) {
  const start = FloorRun(position: Vec2(0, _top), size: Vec2(12, tileSize));
  final goalRun = FloorRun(
    position: Vec2(goalLeft, _top),
    size: const Vec2(9, tileSize),
  );
  return LevelData(
    seed: 'test',
    level: 1,
    ballStart: const Vec2(tileSize / 2, _top - 1),
    goal: Vec2(goalRun.right - tileSize / 2, _top - 1.75),
    floors: [start, ...floors, goalRun],
    ramps: const [],
    boosts: boosts,
    checkpoints: [for (final x in checkpoints) Checkpoint(Vec2(x, _top))],
    hazards: hazards,
    platforms: platforms,
    sections: const [],
    estimatedDuration: 10,
  );
}

void _run(BallOdysseyGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += _dt) {
    game.update(_dt);
  }
}

/// Lets the ball settle on the ground.
void _settle(BallOdysseyGame game) {
  final ball = game.level!.ball;
  for (var i = 0; i < 120 && !ball.isOnGround; i++) {
    game.update(_dt);
  }
}

void main() {
  late Images images;
  setUpAll(() async => images = await testImages());

  BallOdysseyGame gameOn(LevelData data) {
    final game = testGame(images: images, levelFor: (_) => data);
    return game;
  }

  group('spikes', () {
    const strip = SpikeStrip(position: Vec2(7.5, _top), width: 1.5);

    testWithGame(
      'send the ball back to the last checkpoint',
      () => gameOn(_level(hazards: [strip], checkpoints: [3])),
      (game) async {
        game.input!.removeFromParent();
        final level = game.level!;
        final ball = level.ball
          ..body.setTransform(Vector2(3, _top - 0.25), const Rot.identity());
        game.update(_dt);
        expect(level.activeCheckpoint, isNotNull);
        ball.body.setTransform(Vector2(8.25, _top - 0.2), const Rot.identity());
        game
          ..update(_dt)
          ..update(_dt);
        expect(game.level, same(level));
        expect(ball.body.position.x, closeTo(3, 1e-6));
      },
    );

    testWithGame(
      'restart the level with no checkpoint active',
      () => gameOn(_level(hazards: [strip])),
      (game) async {
        final level = game.level!;
        level.ball.body.setTransform(
          Vector2(8.25, _top - 0.2),
          const Rot.identity(),
        );
        game
          ..update(_dt)
          ..update(_dt);
        await game.ready();
        expect(game.level, isNot(same(level)));
      },
    );

    testWithGame(
      'leave a ball that clears them alone, and draw them',
      () => gameOn(_level(hazards: [strip], checkpoints: [3])),
      (game) async {
        final level = game.level!;
        final ball = level.ball
          ..body.setTransform(Vector2(3, _top - 0.25), const Rot.identity());
        game.update(_dt);
        // Just above the sensor, the ball is safe.
        ball.body
          ..gravityScale = 0
          ..setTransform(
            Vector2(8.25, _top - SpikeComponent.sensorHeight - 0.25),
            const Rot.identity(),
          );
        game
          ..update(_dt)
          ..update(_dt);
        expect(ball.body.position.x, closeTo(8.25, 0.1));
        level.children.whereType<SpikeComponent>().single
          ..render(Canvas(PictureRecorder()))
          ..removeFromParent();
        game.update(_dt);
      },
    );
  });

  group('moving platforms', () {
    // A ferry over the 12–24 m gap.
    const ferry = MovingPlatform(
      start: Vec2(12.15, _top),
      end: Vec2(20.85, _top),
      size: Vec2(3, 0.5),
      speed: 2.2,
      pause: 0.8,
    );

    testWithGame(
      'shuttle between their ends, pausing at each',
      () => gameOn(_level(platforms: [ferry], goalLeft: 24)),
      (game) async {
        final platform = game.level!.children
            .whereType<MovingPlatformComponent>()
            .single;
        expect(platform.topLeft.x, closeTo(12.15, 1e-6));
        const travel = (20.85 - 12.15) / 2.2;
        _run(game, travel + 0.1);
        expect(platform.topLeft.x, closeTo(20.85, 0.05));
        expect(platform.isPausing, isTrue);
        expect(platform.topLeft.y, closeTo(_top, 1e-6));
        _run(game, 0.8 + travel + 0.1);
        expect(platform.topLeft.x, closeTo(12.15, 0.05));
        platform.render(Canvas(PictureRecorder()));
      },
    );

    /// Runs until the platform docks at its far end, then puts the ball at
    /// rest in the middle of its deck, as after boarding.
    Future<(MovingPlatformComponent, BallComponent)> board(
      BallOdysseyGame game,
    ) async {
      game.input!.removeFromParent();
      final platform = game.level!.children
          .whereType<MovingPlatformComponent>()
          .single;
      _run(game, (20.85 - 12.15) / 2.2 + 0.05);
      expect(platform.isPausing, isTrue);
      final ball = game.level!.ball
        ..body.setTransform(
          Vector2(platform.topLeft.x + 1.5, _top - 0.21),
          const Rot.identity(),
        );
      game.intent.horizontal = 0;
      _settle(game);
      return (platform, ball);
    }

    testWithGame(
      'carry a resting ball from one edge to the other',
      () => gameOn(_level(platforms: [ferry], goalLeft: 24)),
      (game) async {
        final (platform, ball) = await board(game);
        _run(game, 0.8 + (20.85 - 12.15) / 2.2);
        // Docked at the near end, with the ball still on board.
        expect(platform.topLeft.x, closeTo(12.15, 0.05));
        expect(ball.body.position.x, greaterThan(platform.topLeft.x));
        expect(ball.body.position.x, lessThan(platform.topLeft.x + 3));
        expect(ball.isOnGround, isTrue);
      },
    );

    testWithGame(
      'let the ball roll on the deck as on the ground',
      () => gameOn(_level(platforms: [ferry], goalLeft: 24)),
      (game) async {
        final (platform, ball) = await board(game);
        final start = ball.body.position.x - platform.topLeft.x;
        // Pushing from rest for 0.6 s rolls it over a meter, as on the
        // ground (the measured speed curve).
        game.intent.horizontal = 1;
        _run(game, 0.6);
        final rolled = ball.body.position.x - platform.topLeft.x - start;
        expect(rolled, greaterThan(1));
        expect(ball.isOnGround, isTrue);
      },
    );
  });

  group('crumbling platforms', () {
    const island = FloorRun(
      position: Vec2(14, _top),
      size: Vec2(3, tileSize),
      crumbling: true,
    );

    testWithGame(
      'collapse 0.6 s after the ball stands on them',
      () => gameOn(_level(floors: [island], goalLeft: 20)),
      (game) async {
        game.input!.removeFromParent();
        final platform = game.level!.children
            .whereType<CrumblingPlatformComponent>()
            .single;
        _run(game, 1);
        expect(platform.isShaking, isFalse);
        expect(platform.isCollapsed, isFalse);

        final ball = game.level!.ball
          ..body.setTransform(Vector2(15.5, _top - 0.3), const Rot.identity());
        _settle(game);
        expect(platform.isShaking, isTrue);
        _run(game, CrumblingPlatformComponent.delay - 0.2);
        expect(platform.isCollapsed, isFalse);
        platform.render(Canvas(PictureRecorder()));
        _run(game, 0.3);
        expect(platform.isCollapsed, isTrue);
        expect(platform.supports(ball.body.position), isFalse);
        platform.render(Canvas(PictureRecorder()));
        _run(game, 0.5);
        expect(ball.body.position.y, greaterThan(_top + 1));
        expect(ball.isOnGround, isFalse);
        platform.render(Canvas(PictureRecorder()));
      },
    );

    testWithGame(
      'come back when the ball respawns',
      () => gameOn(_level(floors: [island], checkpoints: [3], goalLeft: 20)),
      (game) async {
        game.input!.removeFromParent();
        final level = game.level!;
        final ball = level.ball
          ..body.setTransform(Vector2(3, _top - 0.25), const Rot.identity());
        game.update(_dt);
        ball.body.setTransform(Vector2(15.5, _top - 0.3), const Rot.identity());
        _settle(game);
        _run(game, 1);
        final platform = level.children
            .whereType<CrumblingPlatformComponent>()
            .single;
        expect(platform.isCollapsed, isTrue);
        level.sendBack();
        expect(platform.isCollapsed, isFalse);
        expect(platform.isShaking, isFalse);
        expect(platform.body.isEnabled, isTrue);
      },
    );
  });

  group('double-jump orbs', () {
    const orb = Boost(
      position: Vec2(6, _top - 0.6),
      type: BoostType.doubleJump,
    );

    testWithGame(
      'charge one air jump and disappear',
      () => gameOn(_level(boosts: [orb], checkpoints: [3])),
      (game) async {
        game.input!.removeFromParent();
        final level = game.level!;
        final ball = level.ball;
        final component = level.children.whereType<BoostComponent>().single;
        ball.body.setTransform(Vector2(6, _top - 0.6), const Rot.identity());
        game.update(_dt);
        expect(ball.hasAirJump, isTrue);
        expect(component.isCollected, isTrue);
        component.render(Canvas(PictureRecorder()));

        // Falling, the charge jumps from the current height.
        ball.body
          ..setTransform(Vector2(9, _top - 3), const Rot.identity())
          ..linearVelocity = Vector2(0, 6);
        game.update(_dt);
        game.intent.requestJump();
        game.update(_dt);
        expect(ball.body.linearVelocity.y, lessThan(-8));
        expect(ball.hasAirJump, isFalse);

        // Spent: another press in mid-air does nothing.
        _run(game, 0.4);
        final vy = ball.body.linearVelocity.y;
        game.intent.requestJump();
        game.update(_dt);
        expect(ball.body.linearVelocity.y, greaterThan(vy));
      },
    );

    testWithGame(
      'come back, and the charge is lost, on a respawn',
      () => gameOn(_level(boosts: [orb], checkpoints: [3])),
      (game) async {
        final level = game.level!;
        final ball = level.ball
          ..body.setTransform(Vector2(3, _top - 0.25), const Rot.identity());
        game.update(_dt);
        ball.body.setTransform(Vector2(6, _top - 0.6), const Rot.identity());
        game.update(_dt);
        final component = level.children.whereType<BoostComponent>().single;
        expect(component.isCollected, isTrue);
        // A second pass while collected does nothing.
        ball.respawn(Vector2(6, _top - 0.6));
        game.update(_dt);
        expect(ball.hasAirJump, isFalse);
        level.sendBack();
        expect(component.isCollected, isFalse);
        expect(ball.hasAirJump, isFalse);
      },
    );
  });
}
