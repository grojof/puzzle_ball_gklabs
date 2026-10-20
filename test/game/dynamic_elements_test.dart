import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart' show Component;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/ball_envelope.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';

import '../helpers/game_helpers.dart';

const double _dt = 1 / 60;
const double _top = 4;

/// A course of [floors] spans at [_top], with the dynamic elements, and a
/// deep floor far below so leaving them is never a fall.
LevelData _course({
  List<(double, double)> floors = const [(0, 190)],
  List<Fan> fans = const [],
  List<Bumper> bumpers = const [],
  List<Pendulum> pendulums = const [],
  List<Seesaw> seesaws = const [],
  List<double> checkpoints = const [],
}) => LevelData(
  seed: 'test',
  level: 1,
  ballStart: const Vec2(tileSize / 2, _top - 1),
  goal: const Vec2(199, _top - 1.75),
  floors: [
    for (final (left, right) in floors)
      FloorRun(position: Vec2(left, _top), size: Vec2(right - left, tileSize)),
    const FloorRun(position: Vec2(0, 60), size: Vec2(200, 1.5)),
  ],
  ramps: const [],
  boosts: const [],
  checkpoints: [for (final x in checkpoints) Checkpoint(Vec2(x, _top))],
  sections: const [],
  estimatedDuration: 10,
  fans: fans,
  bumpers: bumpers,
  pendulums: pendulums,
  seesaws: seesaws,
);

/// Puts the ball of [game] at rest at ([x], [y]), with input removed.
BallComponent _place(BallOdysseyGame game, double x, {double y = _top - 0.21}) {
  game
    ..input?.removeFromParent()
    ..update(0);
  final ball = game.level!.ball;
  ball.body
    ..setTransform(Vector2(x, y), const Rot.identity())
    ..linearVelocity = Vector2.zero()
    ..angularVelocity = 0;
  return ball;
}

void _run(BallOdysseyGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += _dt) {
    game.update(_dt);
  }
}

void main() {
  late Images images;
  setUpAll(() async => images = await testImages());

  late RecordingAudioSink audio;
  late RecordingHaptics haptics;
  BallOdysseyGame gameOn(LevelData data) {
    audio = RecordingAudioSink();
    haptics = RecordingHaptics();
    return testGame(
      images: images,
      levelFor: (_) => data,
      audio: audio,
      haptics: haptics,
    );
  }

  group('fans', () {
    // A pit fan from x 20 to 40, hovering 1 m above the runs.
    const hover = _top - 1;
    const base = _top + 3;
    const fan = Fan(
      left: 20,
      right: 40,
      base: base,
      top: base - (base - hover) / (1 - 1 / fanLift),
    );
    LevelData pit() =>
        _course(floors: const [(0, 20), (40, 190)], fans: const [fan]);

    testWithGame('float the ball at the hover height', () => gameOn(pit()), (
      game,
    ) async {
      final ball = _place(game, 25, y: _top);
      _run(game, 6);
      expect(ball.body.position.y, closeTo(hover, 0.1));
      expect(ball.body.position.x, closeTo(25, 0.5));
      expect(audio.played, contains(GameSound.whoosh));
      final component = game.level!.children.whereType<FanComponent>().single;
      expect(component.holdsBall, isTrue);
      expect(component.inFloor, isFalse);
    });

    testWithGame(
      'let the ball fall once pushed out of the column',
      () => gameOn(_course(floors: const [(0, 20), (60, 190)], fans: [fan])),
      (game) async {
        final ball = _place(game, 38, y: hover);
        game.intent.horizontal = 1;
        for (var i = 0; i < 300 && ball.body.position.x < 42; i++) {
          game.update(_dt);
        }
        game.intent.horizontal = 0;
        _run(game, 0.5);
        expect(ball.body.linearVelocity.y, greaterThan(2));
        expect(ball.body.position.y, greaterThan(hover + 0.5));
      },
    );

    testWithGame(
      'set in the floor lift the ball over a wall',
      () => gameOn(
        const LevelData(
          seed: 'test',
          level: 1,
          ballStart: Vec2(tileSize / 2, _top - 1),
          goal: Vec2(40, _top - 9.75),
          floors: [
            FloorRun(position: Vec2(0, _top), size: Vec2(12, tileSize)),
            FloorRun(position: Vec2(12, _top - 8), size: Vec2(30, 9.5)),
          ],
          ramps: [],
          boosts: [],
          checkpoints: [],
          sections: [],
          estimatedDuration: 10,
          fans: [Fan(left: 10.5, right: 12, base: _top, top: _top - 2 * 8.7)],
        ),
      ),
      (game) async {
        final ball = _place(game, 8);
        expect(
          game.level!.children.whereType<FanComponent>().single.inFloor,
          isTrue,
        );
        game.intent.horizontal = 1;
        _run(game, 6);
        expect(ball.body.position.x, greaterThan(12.5));
        expect(ball.body.position.y, lessThan(_top - 8));
      },
    );
  });

  group('bumpers', () {
    testWithGame(
      'throw a ball that jumps into them straight back down',
      () => gameOn(
        _course(
          bumpers: const [
            Bumper(Vec2(10, _top - bumperRoofHeight - bumperRadius)),
          ],
        ),
      ),
      (game) async {
        final ball = _place(game, 10);
        _run(game, 0.3);
        game.intent.requestJump();
        final bumper = game.level!.children.whereType<BumperComponent>().single;
        var fastest = 0.0;
        for (var i = 0; i < 60; i++) {
          game.update(_dt);
          fastest = math.max(fastest, ball.body.linearVelocity.y);
          if (bumper.isFlashing) break;
        }
        expect(bumper.isFlashing, isTrue);
        expect(fastest, closeTo(BumperComponent.speed, 0.5));
        expect(audio.played, contains(GameSound.bumper));
        expect(haptics.played, contains(Haptic.hit));
        bumper.render(Canvas(PictureRecorder()));
        _run(game, 0.5);
        expect(bumper.isFlashing, isFalse);
      },
    );

    testWithGame(
      'in a roof carry a ball that lands on them on their beam, to roll off',
      () => gameOn(
        _course(
          bumpers: [
            for (var x = 10.0; x <= 14; x += 0.8)
              Bumper(Vec2(x, _top - bumperRoofHeight - bumperRadius)),
          ],
        ),
      ),
      (game) async {
        final beam = game.level!.children.whereType<RoofBeamComponent>().single;
        expect(beam.left, closeTo(10 - bumperRadius, 1e-9));
        final ball = _place(game, 12, y: _top - 3);
        game.intent.horizontal = 1;
        var rested = false;
        for (var i = 0; i < 240 && ball.body.position.x < 15; i++) {
          game.update(_dt);
          if (ball.isOnGround && ball.body.position.y < _top - 1) {
            rested = true;
          }
        }
        expect(rested, isTrue);
        expect(ball.body.position.x, greaterThan(14.5));
        beam.render(Canvas(PictureRecorder()));
      },
    );

    testWithGame(
      'in a riser kick a ball rolling into it back',
      () => gameOn(
        const LevelData(
          seed: 'test',
          level: 1,
          ballStart: Vec2(tileSize / 2, _top - 1),
          goal: Vec2(40, _top - 3.75),
          floors: [
            FloorRun(position: Vec2(0, _top), size: Vec2(12, tileSize)),
            FloorRun(position: Vec2(12, _top - 2), size: Vec2(30, 3.5)),
            FloorRun(position: Vec2(0, 60), size: Vec2(200, 1.5)),
          ],
          ramps: [],
          boosts: [],
          checkpoints: [],
          sections: [],
          estimatedDuration: 10,
          bumpers: [Bumper(Vec2(12 + bumperInset, _top - bumperRadius))],
        ),
      ),
      (game) async {
        final ball = _place(game, 6);
        game.intent.horizontal = 1;
        var thrown = false;
        for (var i = 0; i < 240 && !thrown; i++) {
          game.update(_dt);
          thrown = ball.body.linearVelocity.x < -3;
        }
        expect(thrown, isTrue);
      },
    );
  });

  group('pendulums', () {
    const pendulum = Pendulum(
      pivot: Vec2(20, _top - maceClearance - maceRadius - 3),
      length: 3,
      period: 6,
      clear: 0.25,
      phase: 0,
    );
    LevelData swing() =>
        _course(pendulums: const [pendulum], checkpoints: const [5]);

    test('swing less than 60° either way', () {
      for (final length in [2.5, 3.5]) {
        for (final clear in [0.2, 0.3]) {
          final component = PendulumComponent(
            pendulum: Pendulum(
              pivot: const Vec2(0, 0),
              length: length,
              period: 4,
              clear: clear,
              phase: 0,
            ),
          );
          expect(component.amplitude, lessThan(math.pi / 3));
          expect(component.laneAngle, lessThan(component.amplitude));
        }
      }
    });

    testWithGame('knock the ball along their swing', () => gameOn(swing()), (
      game,
    ) async {
      final ball = _place(game, 20);
      double? swingAtHit;
      final mace = game.level!.children.whereType<PendulumComponent>().single;
      for (var i = 0; i < 300 && swingAtHit == null; i++) {
        final before = mace.body.angularVelocity;
        game.update(_dt);
        if (ball.body.linearVelocity.x.abs() > 1) swingAtHit = before;
      }
      expect(swingAtHit, isNotNull);
      // A positive angular speed swings the mace towards smaller x.
      expect(ball.body.linearVelocity.x.sign, swingAtHit! > 0 ? -1 : 1);
      expect(audio.played, contains(GameSound.thud));
      expect(haptics.played, contains(Haptic.hit));
    });

    testWithGame(
      'let a ball cross while the lane is clear, and keep their rhythm '
      'through a respawn',
      () => gameOn(swing()),
      (game) async {
        final level = game.level!;
        final mace = level.children.whereType<PendulumComponent>().single;
        final lane = pendulum.left - ballRadius;
        final ball = _place(game, lane - 0.3);
        // Wait for the lane to clear for the crossing from rest.
        final crossing = ballEnvelope.pushTime(
          0,
          2 * (pendulum.reach + ballRadius),
        );
        expect(crossing, lessThan(pendulum.clearTime));
        for (var i = 0; i < 600 && !mace.clearFor(crossing); i++) {
          game.update(_dt);
        }
        game.intent.horizontal = 1;
        for (var i = 0; i < 300; i++) {
          if (ball.body.position.x > pendulum.right + ballRadius + 0.3) break;
          game.update(_dt);
        }
        expect(
          ball.body.position.x,
          greaterThan(pendulum.right + ballRadius + 0.3),
        );
        expect(audio.played, isNot(contains(GameSound.thud)));
        // A respawn does not reset the clock.
        _place(game, 5);
        _run(game, 0.2);
        final before = mace.time;
        level.sendBack();
        _run(game, 0.1);
        expect(mace.time, greaterThan(before));
      },
    );
  });

  group('seesaws', () {
    const half = 2.0;
    const rest = half * 0.14;
    final seesaw = Seesaw(
      pivot: Vec2(
        20 + seesawCrack + math.sqrt(half * half - rest * rest),
        _top - rest,
      ),
      halfLength: half,
      rest: rest,
      tip: half * 0.33,
    );
    LevelData plank() => _course(
      floors: const [(0, 20), (40, 190)],
      seesaws: [seesaw],
      checkpoints: const [5],
    );

    testWithGame('rest leaning back', () => gameOn(plank()), (game) async {
      _run(game, 1);
      final component = game.level!.children
          .whereType<SeesawComponent>()
          .single;
      expect(component.isTipped, isFalse);
      expect(component.body.angle, closeTo(component.restAngle, 0.02));
    });

    testWithGame(
      'tip forwards past the pivot, roll a stalled ball off, and rest '
      'again after a respawn',
      () => gameOn(plank()),
      (game) async {
        final level = game.level!;
        final component = level.children.whereType<SeesawComponent>().single;
        // Through the checkpoint, then from rest on the plank's near end.
        final ball = _place(game, 5);
        _run(game, 0.2);
        _place(game, seesaw.nearEnd.x + 0.05);
        _run(game, 0.2);
        game.intent.horizontal = 1;
        // Pushing on past the pivot tips it down to its tilt.
        for (var i = 0; i < 300; i++) {
          if (component.body.angle > component.tipAngle - 0.05) break;
          game.update(_dt);
        }
        expect(component.isTipped, isTrue);
        expect(ball.body.position.x, greaterThan(seesaw.pivot.x));
        game.intent.horizontal = 0;
        _run(game, 2);
        expect(ball.body.position.y, greaterThan(_top + 2));
        level.sendBack();
        _run(game, 0.1);
        expect(component.body.angle, closeTo(component.restAngle, 0.05));
      },
    );
  });

  testWithGame(
    'draw every dynamic element when on screen',
    () => gameOn(
      _course(
        floors: const [(0, 20), (40, 60), (80, 190)],
        fans: const [Fan(left: 20, right: 40, base: 7, top: -3)],
        bumpers: const [Bumper(Vec2(50, 2.65))],
        pendulums: const [
          Pendulum(
            pivot: Vec2(100, _top - maceClearance - maceRadius - 3),
            length: 3,
            period: 4,
            clear: 0.25,
            phase: 1,
          ),
        ],
        seesaws: [
          const Seesaw(
            pivot: Vec2(60 + seesawCrack + 1.98, _top - 0.28),
            halfLength: 2,
            rest: 0.28,
            tip: 0.66,
          ),
        ],
      ),
    ),
    (game) async {
      final level = game.level!;
      final ball = level.ball;
      final canvas = Canvas(PictureRecorder());
      final elements = <(double, Component)>[
        for (final fan in level.children.whereType<FanComponent>())
          (fan.fan.left + 2, fan),
        for (final bumper in level.children.whereType<BumperComponent>())
          (bumper.bumper.center.x, bumper),
        for (final mace in level.children.whereType<PendulumComponent>())
          (mace.pendulum.pivot.x, mace),
        for (final plank in level.children.whereType<SeesawComponent>())
          (plank.seesaw.pivot.x, plank),
      ];
      expect(elements, hasLength(4));
      for (final (x, element) in elements) {
        ball.body
          ..setTransform(Vector2(x, _top - 6), const Rot.identity())
          ..linearVelocity = Vector2.zero();
        _run(game, 0.1);
        element.render(canvas);
      }
    },
  );
}
