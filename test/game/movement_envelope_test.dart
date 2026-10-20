import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/game/ball_envelope.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';

import '../helpers/game_helpers.dart';

const double _dt = 1 / 60;

/// A course on level ground at y 4: [floors] spans of ground, with a deep
/// floor far below so nothing counts as a fall.
LevelData _course({
  List<(double, double, FloorSurface)> floors = const [],
  List<CurvedRun> curves = const [],
  List<Trampoline> trampolines = const [],
  List<Loop> loops = const [],
  List<Boost> boosts = const [],
}) => LevelData(
  seed: 'envelope',
  level: 1,
  ballStart: const Vec2(tileSize / 2, 3),
  goal: const Vec2(299, 2.25),
  floors: [
    for (final (left, right, surface) in floors)
      FloorRun(
        position: Vec2(left, 4),
        size: Vec2(right - left, tileSize),
        surface: surface,
      ),
    const FloorRun(position: Vec2(0, 40), size: Vec2(300, tileSize)),
  ],
  ramps: const [],
  boosts: boosts,
  checkpoints: const [],
  sections: const [],
  estimatedDuration: 10,
  curves: curves,
  trampolines: trampolines,
  loops: loops,
);

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

  group('the new physics reaches the movement envelope', () {
    /// The ball of [game] at rest at [x], with input removed.
    Future<BallComponent> placed(BallOdysseyGame game, double x) async {
      game.input!.removeFromParent();
      await game.ready();
      final ball = game.level!.ball;
      ball.body
        ..setTransform(Vector2(x, 3.79), const Rot.identity())
        ..linearVelocity = Vector2.zero();
      for (var i = 0; i < 30; i++) {
        game.update(_dt);
      }
      return ball;
    }

    // The smallest and biggest of each kind of curve.
    final curves = [
      for (final height in [0.75, 3.0]) ...[
        CurvedRun.bumps(
          kind: CurveKind.hill,
          left: 40,
          ground: 4,
          bumps: [(4.4 * height, height)],
        ),
        CurvedRun.bumps(
          kind: CurveKind.halfPipe,
          left: 40,
          ground: 4,
          bumps: [(4.4 * height, -height)],
        ),
        CurvedRun.slope(left: 40, from: 4, to: 4 - height, width: 2.2 * height),
      ],
    ];
    for (final curve in curves) {
      final end = curve.points.last;
      testWithGame(
        'pushing from rest leaves a ${curve.kind.name} '
        '${(curve.bottom - curve.top).toStringAsFixed(2)} m high fast enough',
        () => testGame(
          images: images,
          levelFor: (_) => LevelData(
            seed: 'envelope',
            level: 1,
            ballStart: const Vec2(tileSize / 2, 3),
            goal: const Vec2(299, 0),
            floors: [
              const FloorRun(position: Vec2(0, 4), size: Vec2(40, tileSize)),
              FloorRun(
                position: Vec2(end.x, end.y),
                size: const Vec2(150, tileSize),
              ),
              const FloorRun(position: Vec2(0, 40), size: Vec2(300, tileSize)),
            ],
            ramps: const [],
            boosts: const [],
            checkpoints: const [],
            sections: const [],
            estimatedDuration: 10,
            curves: [curve],
          ),
        ),
        (game) async {
          final ball = await placed(game, 39.5);
          game.intent.horizontal = 1;
          for (var i = 0; i < 900; i++) {
            game.update(_dt);
            if (ball.body.position.x > end.x + 0.3) break;
          }
          expect(ball.body.position.x, greaterThan(end.x));
          expect(
            ball.body.linearVelocity.x,
            greaterThanOrEqualTo(ballEnvelope.curveExitSpeed),
          );
        },
      );
    }

    testWithGame(
      'trampoline height and reach at top speed',
      () => testGame(
        images: images,
        levelFor: (_) => _course(
          floors: const [(0, 200, FloorSurface.plain)],
          trampolines: const [Trampoline(position: Vec2(60, 4), width: 1.5)],
        ),
      ),
      (game) async {
        final ball = await placed(game, 20);
        game.intent.horizontal = 1;
        var peak = 4.0;
        double? from;
        for (var i = 0; i < 900; i++) {
          game.update(_dt);
          final p = ball.body.position;
          if (from == null && ball.body.linearVelocity.y < -5) from = p.x;
          if (from == null) continue;
          if (p.y < peak) peak = p.y;
          if (p.x > from + 2 && p.y >= 3.79) break;
        }
        expect(3.8 - peak, greaterThanOrEqualTo(ballEnvelope.trampolineHeight));
        expect(
          ball.body.position.x - from!,
          greaterThanOrEqualTo(
            ballEnvelope.maxTrampolineGap(
              speed: ballEnvelope.topSpeed,
              rise: 0,
              margin: 1,
            ),
          ),
        );
      },
    );

    testWithGame(
      'a trampoline bounce taken at rest carries a pushing ball its distance',
      () => testGame(
        images: images,
        levelFor: (_) => _course(
          floors: const [(0, 200, FloorSurface.plain)],
          trampolines: const [Trampoline(position: Vec2(30, 4), width: 1.5)],
        ),
      ),
      (game) async {
        final ball = await placed(game, 20);
        ball.body
          ..setTransform(Vector2(30.4, 3), const Rot.identity())
          ..linearVelocity = Vector2.zero();
        game.intent.horizontal = 1;
        double? from;
        for (var i = 0; i < 600; i++) {
          game.update(_dt);
          final p = ball.body.position;
          if (from == null && ball.body.linearVelocity.y < -5) from = p.x;
          if (from != null && p.x > from + 2 && p.y >= 3.79) break;
        }
        expect(
          ball.body.position.x - from!,
          greaterThanOrEqualTo(
            ballEnvelope.maxTrampolineGap(speed: 0, rise: 0, margin: 1),
          ),
        );
      },
    );

    testWithGame(
      'an adrenaline rush reaches its scaled speed curve',
      () => testGame(
        images: images,
        levelFor: (_) => _course(floors: const [(0, 200, FloorSurface.plain)]),
      ),
      (game) async {
        final ball = await placed(game, 5)
          ..enterRush();
        final x0 = ball.body.position.x;
        game.intent.horizontal = 1;
        var fastest = 0.0;
        for (var i = 0; i < 600; i++) {
          game.update(_dt);
          final distance = ball.body.position.x - x0;
          if (distance > 150) break;
          final v = ball.body.linearVelocity.x;
          if (v > fastest) fastest = v;
          expect(
            v,
            greaterThanOrEqualTo(ballEnvelope.rushSpeedAfter(distance)),
            reason: 'at $distance m',
          );
        }
        expect(
          fastest,
          greaterThanOrEqualTo(ballEnvelope.rushGain * ballEnvelope.topSpeed),
        );
      },
    );

    testWithGame(
      'a forward belt carries a resting ball',
      () => testGame(
        images: images,
        levelFor: (_) =>
            _course(floors: const [(0, 200, FloorSurface.conveyorForward)]),
      ),
      (game) async {
        final ball = await placed(game, 10);
        for (var i = 0; i < 180; i++) {
          game.update(_dt);
        }
        expect(
          ball.body.linearVelocity.x,
          greaterThanOrEqualTo(0.9 * ballEnvelope.beltSpeed),
        );
      },
    );

    for (final surface in [FloorSurface.ice, FloorSurface.conveyorBackward]) {
      testWithGame(
        'pushing on ${surface.name} reaches its speed curve',
        () => testGame(
          images: images,
          levelFor: (_) => _course(floors: [(0, 200, surface)]),
        ),
        (game) async {
          final ball = await placed(game, 10);
          final x0 = ball.body.position.x;
          game.intent.horizontal = 1;
          for (var i = 0; i < 600; i++) {
            game.update(_dt);
            final distance = ball.body.position.x - x0;
            if (distance > 150) break;
            // A backward belt first carries the resting ball back.
            if (distance < 0.5) continue;
            expect(
              ball.body.linearVelocity.x,
              greaterThanOrEqualTo(ballEnvelope.speedOn(surface, distance)),
              reason: 'at $distance m',
            );
          }
        },
      );
    }

    testWithGame(
      'mud top speed and jump',
      () => testGame(
        images: images,
        levelFor: (_) => _course(floors: const [(0, 200, FloorSurface.mud)]),
      ),
      (game) async {
        final ball = await placed(game, 10);
        push(game, 3.79, 5);
        expect(
          ball.body.linearVelocity.x,
          greaterThanOrEqualTo(ballEnvelope.mudTopSpeed),
        );
        final ground = ball.body.position.y;
        game.intent.requestJump();
        final (distance, height) = fly(game, ground);
        expect(height, greaterThanOrEqualTo(ballEnvelope.mudJumpHeight));
        expect(
          distance,
          greaterThanOrEqualTo(
            ballEnvelope.maxGap(
              speed: ballEnvelope.mudTopSpeed,
              rise: 0,
              margin: 1,
              surface: FloorSurface.mud,
            ),
          ),
        );
      },
    );

    testWithGame(
      'a loop entered at its entry speed goes around',
      () => testGame(
        images: images,
        levelFor: (_) => _course(
          floors: const [(0, 200, FloorSurface.plain)],
          loops: const [Loop(foot: Vec2(40, 4), radius: loopRadius)],
        ),
      ),
      (game) async {
        final ball = await placed(game, 39.4);
        ball.body
          ..linearVelocity = Vector2(ballEnvelope.loopEntrySpeed, 0)
          ..angularVelocity = ballEnvelope.loopEntrySpeed / 0.2;
        game.intent.horizontal = 1;
        var top = 4.0;
        for (var i = 0; i < 480 && ball.body.position.x < 46; i++) {
          game.update(_dt);
          if (ball.body.position.y < top) top = ball.body.position.y;
        }
        expect(top, lessThan(4 - 2 * loopRadius + 0.5));
        expect(ball.body.position.x, greaterThanOrEqualTo(46));
      },
    );

    testWithGame(
      "a loop's boost, taken from rest, carries the ball around",
      () => testGame(
        images: images,
        levelFor: (_) => _course(
          floors: const [(0, 200, FloorSurface.plain)],
          loops: const [Loop(foot: Vec2(40, 4), radius: loopRadius)],
          boosts: const [
            Boost(
              position: Vec2(40 - loopRadius - loopBoostLead, 3.4),
              type: BoostType.speed,
            ),
          ],
        ),
      ),
      (game) async {
        final ball = await placed(game, 40 - loopRadius - loopBoostLead - 1);
        game.intent.horizontal = 1;
        double? entry;
        for (var i = 0; i < 480 && ball.body.position.x < 46; i++) {
          game.update(_dt);
          if (entry == null && ball.body.position.x >= 39.4) {
            entry = ball.body.linearVelocity.x;
          }
        }
        expect(ball.body.position.x, greaterThanOrEqualTo(46));
        // With a fifth to spare (design D5).
        expect(entry, greaterThanOrEqualTo(1.2 * ballEnvelope.loopEntrySpeed));
      },
    );
  });

  group('the dynamic elements reach the movement envelope', () {
    /// A level of [floors] at their heights, with [fans] and [seesaws], and
    /// a deep floor far below.
    LevelData course({
      required List<FloorRun> floors,
      List<Fan> fans = const [],
      List<Seesaw> seesaws = const [],
    }) => LevelData(
      seed: 'envelope',
      level: 1,
      ballStart: const Vec2(tileSize / 2, 3),
      goal: const Vec2(299, 2.25),
      floors: [
        ...floors,
        const FloorRun(position: Vec2(0, 60), size: Vec2(300, tileSize)),
      ],
      ramps: const [],
      boosts: const [],
      checkpoints: const [],
      sections: const [],
      estimatedDuration: 10,
      fans: fans,
      seesaws: seesaws,
    );

    // A pit fan as the generator builds it, with the least clearance.
    const run = 4.0;
    const hover = run - 0.5 - 0.2;
    const base = run + 3;
    const fan = Fan(
      left: 30,
      right: 60,
      base: base,
      top: base - (base - hover) / (1 - 1 / fanLift),
    );
    for (final jump in [false, true]) {
      testWithGame(
        'a fan catches a ball that ${jump ? 'jumps' : 'rolls'} in, and '
        'floats it clear of the banks',
        () => testGame(
          images: images,
          levelFor: (_) => course(
            floors: const [
              FloorRun(position: Vec2(0, run), size: Vec2(30, tileSize)),
              FloorRun(position: Vec2(60, run), size: Vec2(30, tileSize)),
            ],
            fans: const [fan],
          ),
        ),
        (game) async {
          game.input!.removeFromParent();
          await game.ready();
          final ball = game.level!.ball;
          game.intent.horizontal = 1;
          var deepest = double.negativeInfinity;
          var risen = false;
          var lowest = double.negativeInfinity;
          var jumped = !jump;
          for (var i = 0; i < 900; i++) {
            game.update(_dt);
            final p = ball.body.position;
            if (!jumped && p.x > 29.4) {
              game.intent.requestJump();
              jumped = true;
            }
            if (p.x <= 30) continue;
            game.intent.horizontal = p.x < 38 ? 1 : 0;
            deepest = math.max(deepest, p.y);
            if (p.y <= hover) risen = true;
            // The ball's bottom, once it has risen to the hover height.
            if (risen) lowest = math.max(lowest, p.y + 0.2);
          }
          expect(risen, isTrue);
          expect(deepest, lessThan(run + ballEnvelope.fanCatchDepth));
          expect(lowest, lessThan(hover + ballEnvelope.fanClearance));
        },
      );
    }

    testWithGame(
      'a fan lifts the ball over a wall at its rising speed',
      () => testGame(
        images: images,
        levelFor: (_) => course(
          floors: const [
            FloorRun(position: Vec2(0, run), size: Vec2(12, tileSize)),
            FloorRun(position: Vec2(12, run - 10), size: Vec2(30, 11.5)),
          ],
          fans: const [
            Fan(left: 10.5, right: 12, base: run, top: run - 2 * 10.7),
          ],
        ),
      ),
      (game) async {
        game.input!.removeFromParent();
        await game.ready();
        final ball = game.level!.ball;
        game.intent.horizontal = 1;
        double? entered;
        double? over;
        var time = 0.0;
        for (var i = 0; i < 1200 && over == null; i++) {
          game.update(_dt);
          time += _dt;
          final p = ball.body.position;
          if (entered == null && p.x > 10.5) entered = time;
          if (p.x > 12.5 && p.y < run - 10) over = time;
        }
        expect(over, isNotNull);
        // Risen 10.7 m to its hover height in that time.
        expect(
          10.7 / (over! - entered!),
          greaterThan(ballEnvelope.fanRiseSpeed),
        );
      },
    );

    // The shortest seesaw is the slowest, the longest jumps lowest.
    for (final half in [1.5, 2.25]) {
      final rest = half * 0.14;
      final seesaw = Seesaw(
        pivot: Vec2(
          10 + seesawCrack + math.sqrt(half * half - rest * rest),
          run - rest,
        ),
        halfLength: half,
        rest: rest,
        tip: half * 0.33,
      );
      testWithGame(
        'a seesaw $half m each side pushed from rest leaves its far end fast '
        'enough, and its jump carries far enough',
        () => testGame(
          images: images,
          levelFor: (_) => course(
            floors: const [
              FloorRun(position: Vec2(0, run), size: Vec2(10, tileSize)),
            ],
            seesaws: [seesaw],
          ),
        ),
        (game) async {
          game.input!.removeFromParent();
          await game.ready();
          final ball = game.level!.ball;
          ball.body
            ..setTransform(
              Vector2(seesaw.nearEnd.x + 0.05, run - 0.21),
              const Rot.identity(),
            )
            ..linearVelocity = Vector2.zero();
          for (var i = 0; i < 20; i++) {
            game.update(_dt);
          }
          game.intent.horizontal = 1;
          for (var i = 0; i < 300; i++) {
            game.update(_dt);
            if (ball.body.position.x >= seesaw.farEnd.x - 0.25) break;
          }
          expect(
            ball.body.linearVelocity.x,
            greaterThanOrEqualTo(ballEnvelope.seesawExitSpeed),
          );
          final ground = ball.body.position.y;
          game.intent.requestJump();
          final (distance, height) = fly(game, ground);
          expect(height, greaterThanOrEqualTo(ballEnvelope.seesawJumpHeight));
          expect(
            distance,
            greaterThanOrEqualTo(ballEnvelope.maxSeesawGap(rise: 0, margin: 1)),
          );
        },
      );
    }
  });
}
