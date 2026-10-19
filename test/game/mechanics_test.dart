import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart' show Component;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/components/level_component.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';

import '../helpers/game_helpers.dart';

const double _dt = 1 / 60;
const double _top = 4;

/// A start run, then [floors] and the goal run, with the given elements.
LevelData _level({
  List<FloorRun> floors = const [],
  List<SpikeStrip> hazards = const [],
  List<MovingPlatform> platforms = const [],
  List<LaserBarrier> lasers = const [],
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
    lasers: lasers,
    sections: const [],
    estimatedDuration: 10,
  );
}

/// A course on level ground at [_top]: [floors] spans with their surfaces,
/// and a deep floor far below so leaving them is never a fall.
LevelData _course({
  List<(double, double, FloorSurface)> floors = const [],
  List<CurvedRun> curves = const [],
  List<Trampoline> trampolines = const [],
  List<Loop> loops = const [],
  List<double> checkpoints = const [],
  List<AdrenalineZone> adrenaline = const [],
  bool safety = true,
}) => LevelData(
  seed: 'test',
  level: 1,
  ballStart: const Vec2(tileSize / 2, _top - 1),
  goal: const Vec2(199, _top - 1.75),
  floors: [
    for (final (left, right, surface) in floors)
      FloorRun(
        position: Vec2(left, _top),
        size: Vec2(right - left, tileSize),
        surface: surface,
      ),
    if (safety) const FloorRun(position: Vec2(0, 40), size: Vec2(200, 1.5)),
  ],
  ramps: const [],
  boosts: const [],
  checkpoints: [for (final x in checkpoints) Checkpoint(Vec2(x, _top))],
  sections: const [],
  estimatedDuration: 10,
  curves: curves,
  trampolines: trampolines,
  loops: loops,
  adrenaline: adrenaline,
);

/// Puts the ball of [game] at ([x], [y]) moving at [velocity], with input
/// removed.
BallComponent _place(
  BallOdysseyGame game,
  double x, {
  double y = _top - 0.21,
  Vector2? velocity,
}) {
  game
    ..input?.removeFromParent()
    // Removing the input resets the push in the next update.
    ..update(0);
  final ball = game.level!.ball;
  ball.body
    ..setTransform(Vector2(x, y), const Rot.identity())
    ..linearVelocity = velocity ?? Vector2.zero()
    ..angularVelocity = (velocity?.x ?? 0) / LevelComponent.ballRadius;
  return ball;
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
  final audio = RecordingAudioSink();
  final haptics = RecordingHaptics();
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
      () => gameOn(_level(floors: [island], checkpoints: [3], goalLeft: 20)),
      (game) async {
        game.input!.removeFromParent();
        final platform = game.level!.children
            .whereType<CrumblingPlatformComponent>()
            .single;
        _run(game, 1);
        expect(platform.isShaking, isFalse);
        expect(platform.isCollapsed, isFalse);

        final ball = game.level!.ball
          ..body.setTransform(Vector2(3, _top - 0.25), const Rot.identity());
        game.update(_dt);
        ball.body.setTransform(Vector2(15.5, _top - 0.3), const Rot.identity());
        _settle(game);
        // The platform notices on its next update.
        game.update(_dt);
        expect(platform.isShaking, isTrue);
        _run(game, CrumblingPlatformComponent.delay - 0.2);
        expect(platform.isCollapsed, isFalse);
        platform.render(Canvas(PictureRecorder()));
        _run(game, 0.3);
        expect(platform.isCollapsed, isTrue);
        expect(platform.supports(ball.body.position), isFalse);
        platform.render(Canvas(PictureRecorder()));
        // The ball falls with nothing left to land on, and is sent back
        // to the checkpoint.
        _run(game, 0.5);
        expect(ball.body.position.x, closeTo(3, 0.2));
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
        final platform = level.children
            .whereType<CrumblingPlatformComponent>()
            .single;
        _run(game, CrumblingPlatformComponent.delay + 0.05);
        expect(platform.isCollapsed, isTrue);
        level.sendBack();
        expect(platform.isCollapsed, isFalse);
        expect(platform.isShaking, isFalse);
        expect(platform.body.isEnabled, isTrue);
      },
    );
  });

  group('falls', () {
    testWithGame(
      'a long drop onto distant lower ground is not cut short',
      () => gameOn(
        _level(
          floors: const [
            FloorRun(position: Vec2(24, _top + 15), size: Vec2(16, tileSize)),
          ],
          goalLeft: 44,
        ),
      ),
      (game) async {
        game.input!.removeFromParent();
        // The input's removal resets the push on the next update.
        game.update(0);
        final level = game.level!;
        final ball = level.ball;
        ball.body
          ..setTransform(Vector2(11.5, _top - 0.3), const Rot.identity())
          ..linearVelocity = Vector2(7, -4);
        game.intent.horizontal = 1;
        var landed = false;
        for (var t = 0.0; t < 4 && !landed; t += _dt) {
          game.update(_dt);
          await game.ready();
          expect(game.level, same(level));
          landed = ball.isOnGround && ball.body.position.x > 24;
        }
        expect(landed, isTrue);
        expect(ball.body.position.x, inInclusiveRange(24, 40));
        expect(ball.body.position.y, closeTo(_top + 15 - 0.2, 0.1));
      },
    );

    testWithGame(
      'a hopeless fall from high up is caught within a second',
      () => gameOn(
        _level(
          // Far below and far away: out of reach from the pit.
          floors: const [
            FloorRun(position: Vec2(120, _top + 40), size: Vec2(8, tileSize)),
          ],
          goalLeft: 200,
        ),
      ),
      (game) async {
        game.input!.removeFromParent();
        // The input's removal resets the push on the next update.
        game.update(0);
        final level = game.level!;
        level.ball.body
          ..setTransform(Vector2(11.9, _top - 0.25), const Rot.identity())
          ..linearVelocity = Vector2(2, 0);
        var elapsed = 0.0;
        while (game.level == level && elapsed < 2) {
          game.update(_dt);
          await game.ready();
          elapsed += _dt;
        }
        expect(game.level, isNot(same(level)));
        expect(elapsed, lessThan(1));
      },
    );

    testWithGame(
      "an orb's charge keeps a ledge within reach a little longer",
      () => gameOn(_level(goalLeft: 200)),
      (game) async {
        game.input!.removeFromParent();
        game.update(0);
        final level = game.level!;
        final ball = level.ball;
        // In the pit just past the start run, 1.5 m below its top.
        ball.body
          ..gravityScale = 0
          ..setTransform(Vector2(12.5, _top + 1.5), const Rot.identity());
        expect(level.canStillLand, isFalse);
        ball.chargeAirJump();
        expect(level.canStillLand, isTrue);
        // Deeper than an air jump can climb, it is gone either way.
        ball.body.setTransform(Vector2(12.5, _top + 3.5), const Rot.identity());
        expect(level.canStillLand, isFalse);
      },
    );

    testWithGame(
      'rolling off a ledge onto the ground below is no fall',
      () => gameOn(
        _level(
          floors: const [
            FloorRun(position: Vec2(12, _top + 5), size: Vec2(8, tileSize)),
          ],
          goalLeft: 22,
        ),
      ),
      (game) async {
        game.input!.removeFromParent();
        // The input's removal resets the push on the next update.
        game.update(0);
        final level = game.level!;
        final ball = level.ball
          ..body.setTransform(Vector2(11, _top - 0.25), const Rot.identity());
        game.intent.horizontal = 0.5;
        _run(game, 2.5);
        expect(game.level, same(level));
        expect(ball.body.position.y, closeTo(_top + 5 - 0.2, 0.1));
        expect(level.canStillLand, isTrue);
      },
    );
  });

  group('laser barriers', () {
    const barrier = LaserBarrier(
      x: 8,
      top: _top - 9,
      bottom: _top - 0.8,
      on: 1.4,
      off: 1,
      phase: 0,
    );

    testWithGame(
      'send the ball back while lit, and let it pass while dark',
      () => gameOn(_level(lasers: const [barrier], checkpoints: [3])),
      (game) async {
        game.input!.removeFromParent();
        // The input's removal resets the push on the next update.
        game.update(0);
        final level = game.level!;
        final laser = level.children.whereType<LaserBarrierComponent>().single;
        final ball = level.ball
          ..body.setTransform(Vector2(3, _top - 0.25), const Rot.identity());
        game.update(_dt);
        expect(laser.isOn, isTrue);
        final canvas = Canvas(PictureRecorder());
        laser.render(canvas);
        // Into the lit beam: back to the checkpoint.
        ball.body
          ..gravityScale = 0
          ..setTransform(Vector2(8, _top - 3), const Rot.identity());
        game
          ..update(_dt)
          ..update(_dt);
        expect(ball.body.position.x, closeTo(3, 0.1));
        // Dark: the ball passes.
        _run(game, 1.4);
        expect(laser.isOn, isFalse);
        laser.render(canvas);
        ball.body.setTransform(Vector2(8, _top - 3), const Rot.identity());
        game
          ..update(_dt)
          ..update(_dt);
        expect(ball.body.position.x, closeTo(8, 0.1));
        // It flickers just before lighting again.
        _run(game, 0.75);
        expect(laser.isWarning, isTrue);
        laser.render(canvas);
      },
    );

    testWithGame(
      'keep their rhythm through a respawn, and leave the route alone',
      () => gameOn(_level(lasers: const [barrier], checkpoints: [3])),
      (game) async {
        game.input!.removeFromParent();
        // The input's removal resets the push on the next update.
        game.update(0);
        final level = game.level!;
        final laser = level.children.whereType<LaserBarrierComponent>().single;
        final ball = level.ball
          ..body.setTransform(Vector2(3, _top - 0.25), const Rot.identity());
        game.update(_dt);
        _run(game, 1);
        final before = laser.isOn;
        level.sendBack();
        expect(laser.isOn, before);
        _run(game, 0.6);
        expect(laser.isOn, isFalse);
        // Rolling under the beam along the ground is safe.
        ball.body.setTransform(Vector2(6, _top - 0.25), const Rot.identity());
        game.intent.horizontal = 1;
        _run(game, 0.8);
        expect(ball.body.position.x, greaterThan(7));
        laser.removeFromParent();
        game.update(_dt);
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

  group('curved terrain', () {
    final hill = CurvedRun.bumps(
      kind: CurveKind.hill,
      left: 12,
      ground: _top,
      bumps: const [(4.4 * 2, 2), (4.4, 1)],
    );
    final pipe = CurvedRun.bumps(
      kind: CurveKind.halfPipe,
      left: hill.right + 6,
      ground: _top,
      bumps: const [(4.4 * 2.5, -2.5)],
    );
    LevelData curvy() => _course(
      floors: [
        (0, 12, FloorSurface.plain),
        (hill.right, pipe.left, FloorSurface.plain),
        (pipe.right, 190, FloorSurface.plain),
      ],
      curves: [hill, pipe],
    );

    testWithGame(
      'the ball rolls over a hill and through a half-pipe without catching',
      () => gameOn(curvy()),
      (game) async {
        final ball = _place(game, 8);
        game.intent.horizontal = 1;
        var groundedOnCurve = false;
        var slowest = double.infinity;
        for (var i = 0; i < 900 && ball.body.position.x < pipe.right + 1; i++) {
          game.update(_dt);
          final x = ball.body.position.x;
          final onCurve =
              (x > hill.left && x < hill.right) ||
              (x > pipe.left && x < pipe.right);
          if (onCurve) {
            groundedOnCurve |= ball.isOnGround;
            slowest = slowest < ball.body.linearVelocity.x
                ? slowest
                : ball.body.linearVelocity.x;
          }
        }
        expect(ball.body.position.x, greaterThan(pipe.right + 1));
        expect(groundedOnCurve, isTrue);
        expect(slowest, greaterThan(1));
      },
    );

    testWithGame(
      'a ball deep in a half-pipe has not fallen',
      () => gameOn(
        _course(
          floors: [
            (0, 12, FloorSurface.plain),
            (hill.right, pipe.left, FloorSurface.plain),
            (pipe.right, 190, FloorSurface.plain),
          ],
          curves: [hill, pipe],
          safety: false,
        ),
      ),
      (game) async {
        final level = game.level!;
        _place(game, (pipe.left + pipe.right) / 2, y: pipe.bottom - 0.5);
        _run(game, 0.5);
        expect(game.level, same(level));
        expect(level.ball.isMounted, isTrue);
      },
    );
  });

  group('trampolines', () {
    const pad = Trampoline(position: Vec2(20, _top), width: 1.5);
    LevelData bouncy() => _course(
      floors: const [(0, 190, FloorSurface.plain)],
      trampolines: const [pad],
    );

    /// The highest the ball rises after its first bounce.
    double bounceHeight(BallOdysseyGame game) {
      final ball = game.level!.ball;
      var bounced = false;
      var peak = _top;
      for (var i = 0; i < 400; i++) {
        game.update(_dt);
        final v = ball.body.linearVelocity;
        if (!bounced && v.y < -TrampolineComponent.launchSpeed * 0.8) {
          bounced = true;
        }
        if (bounced && ball.body.position.y < peak) {
          peak = ball.body.position.y;
        }
        if (bounced && v.y > 0) break;
      }
      expect(bounced, isTrue);
      return _top - peak;
    }

    testWithGame(
      'two different falls bounce to the same height',
      () => gameOn(bouncy()),
      (game) async {
        _place(game, 20.75, y: _top - 1);
        final low = bounceHeight(game);
        _run(game, 2);
        _place(game, 20.75, y: _top - 7);
        final high = bounceHeight(game);
        expect(low, greaterThan(4.5));
        expect(high, closeTo(low, 0.15));
      },
    );

    testWithGame(
      'keep the horizontal speed and squash',
      () => gameOn(bouncy()),
      (game) async {
        final ball = _place(game, 19.4, y: _top - 0.6, velocity: Vector2(3, 0));
        final component = game.level!.children
            .whereType<TrampolineComponent>()
            .single;
        var before = 0.0;
        for (var i = 0; i < 60; i++) {
          before = ball.body.linearVelocity.x;
          game.update(_dt);
          if (ball.body.linearVelocity.y < -10) break;
        }
        expect(ball.body.linearVelocity.y, lessThan(-10));
        expect(ball.body.linearVelocity.x, closeTo(before, 0.2));
        expect(component.isSquashed, isTrue);
        _run(game, TrampolineComponent.squashTime);
        expect(component.isSquashed, isFalse);
      },
    );
  });

  group('surfaces', () {
    testWithGame(
      'a belt carries a resting ball forwards, or backwards',
      () => gameOn(
        _course(
          floors: const [
            (0, 40, FloorSurface.conveyorForward),
            (40, 80, FloorSurface.conveyorBackward),
          ],
        ),
      ),
      (game) async {
        final ball = _place(game, 10);
        _run(game, 2);
        expect(ball.body.position.x, greaterThan(12.5));
        _place(game, 60);
        _run(game, 2);
        expect(ball.body.position.x, lessThan(57.5));
      },
    );

    testWithGame(
      'ice is slow to speed up and slow to stop',
      () => gameOn(
        _course(
          floors: const [
            (0, 60, FloorSurface.plain),
            (60, 140, FloorSurface.ice),
          ],
        ),
      ),
      (game) async {
        final ball = _place(game, 5);
        game.intent.horizontal = 1;
        _run(game, 1);
        final plain = ball.body.linearVelocity.x;
        _place(game, 70);
        game.intent.horizontal = 1;
        _run(game, 1);
        final ice = ball.body.linearVelocity.x;
        expect(ice, lessThan(plain * 0.6));
        _run(game, 4);
        final fast = ball.body.linearVelocity.x;
        game.intent.horizontal = 0;
        _run(game, 1);
        // Plain ground would take most of the speed in a second.
        expect(ball.body.linearVelocity.x, greaterThan(fast / 2));
      },
    );

    testWithGame(
      'mud holds the ball slow and weakens its jump, until it leaves',
      () => gameOn(
        _course(
          floors: const [
            (0, 40, FloorSurface.mud),
            (40, 120, FloorSurface.plain),
          ],
        ),
      ),
      (game) async {
        final ball = _place(game, 5);
        game.intent.horizontal = 1;
        _run(game, 3);
        expect(ball.body.linearVelocity.x, lessThan(3.6));
        game.intent.horizontal = 0;
        _run(game, 2);
        final ground = ball.body.position.y;
        game.intent.requestJump();
        var peak = ground;
        for (var i = 0; i < 90; i++) {
          game.update(_dt);
          if (ball.body.position.y < peak) peak = ball.body.position.y;
        }
        expect(ground - peak, lessThan(2.1));
        expect(ground - peak, greaterThan(1.5));
        _place(game, 45);
        game.intent.horizontal = 1;
        _run(game, 3);
        expect(ball.body.linearVelocity.x, greaterThan(6));
      },
    );
  });

  group('loops', () {
    const loop = Loop(foot: Vec2(30, _top), radius: loopRadius);
    LevelData loopy({List<double> checkpoints = const []}) => _course(
      floors: const [(0, 190, FloorSurface.plain)],
      loops: const [loop],
      checkpoints: checkpoints,
    );
    LoopComponent track(BallOdysseyGame game) =>
        game.level!.children.whereType<LoopComponent>().single;

    testWithGame(
      'carry a fast ball around and out along the run after it',
      () => gameOn(loopy()),
      (game) async {
        final ball = _place(game, 29.4, velocity: Vector2(15, 0));
        var top = _top;
        var rode = false;
        var flashed = false;
        for (var i = 0; i < 300 && ball.body.position.x < loop.right + 2; i++) {
          game.update(_dt);
          rode |= ball.isInLoop;
          flashed |= track(game).isFlashing;
          if (ball.body.position.y < top) top = ball.body.position.y;
        }
        expect(rode, isTrue);
        expect(flashed, isTrue);
        expect(top, lessThan(loop.top + 0.5));
        expect(ball.body.position.x, greaterThan(loop.right + 2));
        // The track resets once the ball has left.
        _run(game, 0.2);
        expect(track(game).rising.isActive, isTrue);
        expect(track(game).falling.isActive, isFalse);
      },
    );

    testWithGame(
      'a slow ball rolls back out of the entry',
      () => gameOn(loopy()),
      (game) async {
        final ball = _place(game, 29.4, velocity: Vector2(6, 0));
        var top = _top;
        for (var i = 0; i < 180; i++) {
          game.update(_dt);
          if (ball.body.position.y < top) top = ball.body.position.y;
        }
        // It came back down short of the top, behind the foot, on the floor.
        expect(top, greaterThan(loop.center.y));
        expect(ball.body.position.x, lessThan(loop.foot.x));
        expect(ball.isOnGround, isTrue);
        game.intent.horizontal = -1;
        for (var i = 0; i < 300 && ball.body.position.x > loop.left - 1; i++) {
          game.update(_dt);
        }
        expect(ball.body.position.x, lessThan(loop.left - 1));
      },
    );

    testWithGame(
      'a ball falling in from above is never trapped',
      () => gameOn(loopy()),
      (game) async {
        // Wherever it lands inside, heading back takes it out of the entry,
        // to try again with the boost.
        for (final x in [loop.foot.x + 0.3, loop.foot.x - 0.3]) {
          final ball = _place(game, x, y: loop.center.y - 0.5);
          game.intent.horizontal = -1;
          bool inside() =>
              ball.body.position.x > loop.left - 1 &&
              ball.body.position.x < loop.right + 1;
          for (var i = 0; i < 600 && inside(); i++) {
            game.update(_dt);
          }
          expect(inside(), isFalse, reason: 'dropped at $x');
          expect(ball.body.position.x, lessThan(loop.left));
          _run(game, 0.5);
        }
      },
    );

    testWithGame(
      'a respawn puts the track back',
      () => gameOn(loopy(checkpoints: [5])),
      (game) async {
        final level = game.level!;
        final ball = _place(game, 5);
        _run(game, 0.2);
        expect(level.activeCheckpoint, isNotNull);
        _place(game, 29.4, velocity: Vector2(15, 0));
        for (var i = 0; i < 120 && !track(game).falling.isActive; i++) {
          game.update(_dt);
        }
        expect(track(game).falling.isActive, isTrue);
        level.sendBack();
        expect(track(game).rising.isActive, isTrue);
        expect(track(game).falling.isActive, isFalse);
        expect(ball.isInLoop, isFalse);
      },
    );
  });

  group('new physics visuals', () {
    final hill = CurvedRun.bumps(
      kind: CurveKind.hill,
      left: 6,
      ground: _top,
      bumps: const [(4.4, 1)],
    );
    LevelData showcase() => _course(
      floors: [
        (0, 6, FloorSurface.plain),
        (hill.right, 16, FloorSurface.conveyorForward),
        (16, 22, FloorSurface.conveyorBackward),
        (22, 28, FloorSurface.ice),
        (28, 34, FloorSurface.mud),
        (34, 80, FloorSurface.plain),
      ],
      curves: [hill],
      trampolines: const [Trampoline(position: Vec2(40, _top), width: 3)],
      loops: const [Loop(foot: Vec2(55, _top), radius: loopRadius)],
    );

    testWithGame(
      'draw every new element when on screen',
      () => gameOn(showcase()),
      (game) async {
        final level = game.level!;
        final ball = level.ball;
        final canvas = Canvas(PictureRecorder());
        final elements = <(double, Component)>[
          for (final floor in level.children.whereType<FloorComponent>())
            (floor.position.x + 2, floor),
          for (final curve
              in level.children.whereType<CurvedTerrainComponent>())
            (curve.curve.left + 2, curve),
          for (final pad in level.children.whereType<TrampolineComponent>())
            (pad.left, pad),
          for (final loop in level.children.whereType<LoopComponent>())
            (loop.loop.foot.x, loop),
        ];
        for (final (x, element) in elements) {
          ball.body
            ..setTransform(Vector2(x, _top - 3), const Rot.identity())
            ..linearVelocity = Vector2.zero();
          _run(game, 0.6);
          element.render(canvas);
        }
        // A pad squashed by a bounce.
        final pad = level.children.whereType<TrampolineComponent>().single;
        ball.body
          ..setTransform(Vector2(pad.left + 1, _top - 1), const Rot.identity())
          ..linearVelocity = Vector2.zero();
        for (var i = 0; i < 60 && !pad.isSquashed; i++) {
          game.update(_dt);
        }
        expect(pad.isSquashed, isTrue);
        pad.render(canvas);
      },
    );
  });

  group('adrenaline rush', () {
    const zone = AdrenalineZone(left: 20, right: 60);
    LevelData rushy() => _course(
      floors: const [(0, 190, FloorSurface.plain)],
      adrenaline: const [zone],
      checkpoints: [5],
    );

    testWithGame(
      'pushes harder inside a zone, and plays a heartbeat',
      () => testGame(
        images: images,
        levelFor: (_) => rushy(),
        audio: audio,
        haptics: haptics,
      ),
      (game) async {
        final ball = _place(game, 2);
        game.intent.horizontal = 1;
        var fastest = 0.0;
        while (ball.body.position.x < 58) {
          game.update(_dt);
          if (ball.body.position.x > 21) {
            expect(ball.isRushing, isTrue);
            fastest = math.max(fastest, ball.body.linearVelocity.x);
          }
        }
        expect(fastest, greaterThan(9.5));
        expect(audio.played, contains(GameSound.heartbeat));
        expect(haptics.played, contains(Haptic.heartbeat));
        while (ball.body.position.x < 75) {
          game.update(_dt);
        }
        expect(ball.isRushing, isFalse);
        _run(game, 2);
        expect(ball.body.linearVelocity.x, lessThan(8.8));
      },
    );

    testWithGame('ends on a respawn', () => gameOn(rushy()), (game) async {
      final level = game.level!;
      final ball = _place(game, 5);
      _run(game, 0.2);
      _place(game, 30);
      _run(game, 0.1);
      expect(ball.isRushing, isTrue);
      level.sendBack();
      _run(game, 0.1);
      expect(ball.isRushing, isFalse);
    });

    testWithGame(
      'draws the zone, the trail, the glow and the heart',
      () => gameOn(rushy()),
      (game) async {
        final level = game.level!;
        final ball = _place(game, 30);
        _run(game, 0.5);
        expect(ball.isRushing, isTrue);
        final glow = game.camera.viewport.children
            .whereType<AdrenalineGlowComponent>()
            .single;
        final tray = game.camera.viewport.children
            .whereType<BoostTrayComponent>()
            .single;
        final trail = level.children.whereType<RushTrailComponent>().single;
        final zoneArt = level.children
            .whereType<AdrenalineZoneComponent>()
            .single;
        expect(glow.level, 1);
        expect(tray.showsHeart, isTrue);
        expect(trail.points, isNotEmpty);
        final canvas = Canvas(PictureRecorder());
        zoneArt.render(canvas);
        trail.render(canvas);
        glow.render(canvas);
        tray.render(canvas);
        // Out of the zone, it all fades within half a second.
        _place(game, 100);
        _run(game, 0.55);
        expect(glow.level, 0);
        expect(tray.showsHeart, isFalse);
        _run(game, 0.3);
        expect(trail.points, isEmpty);
        glow.render(canvas);
      },
    );
  });
}
