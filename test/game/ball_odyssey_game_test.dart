import 'dart:async';
import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/ball_envelope.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/components/level_component.dart';
import 'package:puzzle_ball_gklabs/game/game_config.dart';
import 'package:puzzle_ball_gklabs/game/input/manual_input.dart';
import 'package:puzzle_ball_gklabs/game/input/tilt_input.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../helpers/game_helpers.dart';

AccelerometerEvent tilt(double x, {double z = 9.8}) =>
    AccelerometerEvent(x, 0, z, DateTime(2026));

void main() {
  late Images images;

  setUpAll(() async => images = await testImages());

  group('session', () {
    testWithGame(
      'restart keeps the game and replaces the level',
      () => testGame(images: images),
      (game) async {
        final first = game.level!;

        await game.restartLevel();
        await game.ready();

        final levels = game.world.children.whereType<LevelComponent>();
        expect(levels, hasLength(1));
        expect(levels.single, isNot(same(first)));
        expect(first.isMounted, isFalse);
        expect(game.levelNumber, 1);
      },
    );

    final completed = <int>[];
    testWithGame(
      'completing a level reports it and loads the next one in place',
      () => testGame(images: images, onLevelCompleted: completed.add),
      (game) async {
        game.level!.onCompleted();
        await game.ready();

        expect(completed, [1]);
        expect(game.levelNumber, 2);
        expect(game.world.children.whereType<LevelComponent>(), hasLength(1));
      },
    );

    var sessionEnded = false;
    testWithGame(
      'completing the last level ends the session',
      () => testGame(
        images: images,
        totalLevels: 1,
        onSessionCompleted: () => sessionEnded = true,
      ),
      (game) async {
        game.level!.onCompleted();
        await game.ready();

        expect(sessionEnded, isTrue);
        expect(game.levelNumber, 1);
      },
    );

    testWithGame(
      'falling below the lowest terrain restarts the level',
      () => testGame(images: images),
      (game) async {
        final level = game.level!;
        level.ball.body.setTransform(
          Vector2(0, level.fallLine + 1),
          const Rot.identity(),
        );

        game.update(0);
        await game.ready();

        expect(game.level, isNot(same(level)));
        expect(game.levelNumber, 1);
      },
    );

    final completedByGoal = <int>[];
    testWithGame(
      'reaching the goal plays the sequence and completes the level',
      () => testGame(images: images, onLevelCompleted: completedByGoal.add),
      (game) async {
        final level = game.level!;
        final goal = level.children.whereType<GoalComponent>().single;

        level.ball.beginContact(goal, _NoContact());
        expect(level.ball.body.isEnabled, isFalse);
        for (var i = 0; i < 30; i++) {
          game.update(0.1);
          await game.ready();
        }

        expect(completedByGoal, [1]);
        expect(game.levelNumber, 2);
      },
    );

    testWithGame(
      'teardown destroys the physics world',
      () => testGame(images: images),
      (game) async {
        game.teardown();

        expect(game.world.physicsWorld.isValid, isFalse);
      },
    );
  });

  group('checkpoints', () {
    testWithGame(
      'a fall respawns the ball at rest above the last active checkpoint',
      () => testGame(
        images: images,
        levelFor: (_) => flatLevel(checkpoints: [4.5, 9]),
      ),
      (game) async {
        final level = game.level!;
        final ball = level.ball;
        for (final x in [4.5, 9.0]) {
          ball.body.setTransform(Vector2(x, 3.75), const Rot.identity());
          game.update(1 / 60);
        }
        final last = level.activeCheckpoint!;
        expect(last.ground.x, 9);
        expect(last.isActivated, isTrue);

        ball.body
          ..setTransform(Vector2(20, level.fallLine + 1), const Rot.identity())
          ..linearVelocity = Vector2(5, 20);
        game.update(1 / 60);

        expect(game.level, same(level));
        expect(ball.body.position.x, closeTo(9, 1e-6));
        expect(ball.body.position.y, closeTo(last.respawnPoint.y, 0.2));
        expect(ball.body.linearVelocity.length, lessThan(1));
      },
    );

    testWithGame(
      'touching only the top of the post activates the checkpoint',
      () => testGame(
        images: images,
        levelFor: (_) => flatLevel(checkpoints: [4.5]),
      ),
      (game) async {
        final level = game.level!;
        final ball = level.ball;
        // Skims just over the top of the post, at 4 m above the ground.
        const y =
            4 -
            CheckPointComponent.postHeight -
            LevelComponent.ballRadius -
            0.05;
        ball.body
          ..gravityScale = 0
          ..setTransform(Vector2(3, y), const Rot.identity())
          ..linearVelocity = Vector2(6, 0);
        for (var i = 0; i < 30; i++) {
          game.update(1 / 60);
        }
        expect(ball.body.position.x, greaterThan(5));
        expect(level.activeCheckpoint, isNotNull);
      },
    );

    testWithGame(
      'a respawn cancels a running gravity boost',
      () => testGame(
        images: images,
        levelFor: (_) => flatLevel(checkpoints: [4.5]),
      ),
      (game) async {
        final level = game.level!;
        final ball = level.ball
          ..body.setTransform(Vector2(4.5, 3.75), const Rot.identity());
        game.update(1 / 60);
        ball
          ..applyGravityBoost(0.1)
          ..body.setTransform(
            Vector2(20, level.fallLine + 1),
            const Rot.identity(),
          );
        game.update(1 / 60);

        expect(ball.isBoosted, isFalse);
        expect(ball.body.gravityScale, 1);
      },
    );
  });

  group('boosts', () {
    testWithGame(
      'a gravity boost ends with its timer',
      () => testGame(images: images),
      (game) async {
        final ball = game.level!.ball..applyGravityBoost(0.1);
        expect(ball.body.gravityScale, closeTo(0.1, 1e-6));
        expect(ball.isBoosted, isTrue);

        game.update(BallComponent.boostDuration + 0.1);

        expect(ball.isBoosted, isFalse);
        expect(ball.body.gravityScale, 1);
      },
    );

    testWithGame(
      'unloading mid-boost leaves the next level unboosted',
      () => testGame(images: images),
      (game) async {
        game.level!.ball.applyGravityBoost(0.1);

        await game.restartLevel();
        await game.ready();

        final ball = game.level!.ball;
        expect(ball.isBoosted, isFalse);
        expect(ball.body.gravityScale, 1);
      },
    );

    final audio = RecordingAudioSink();
    testWithGame(
      'only one boost runs at a time, each with its sound',
      () => testGame(images: images, audio: audio),
      (game) async {
        game.level!.ball
          ..applyJumpBoost(10)
          ..applySpeedBoost(10, Vector2(1, 0));

        expect(audio.played, [GameSound.boostJump]);
      },
    );
  });

  group('controls', () {
    final audio = RecordingAudioSink();
    testWithGame(
      'jumps from the ground and not in mid-air',
      () => testGame(images: images, audio: audio),
      (game) async {
        final ball = game.level!.ball;
        for (var i = 0; i < 120 && !ball.isOnGround; i++) {
          game.update(1 / 60);
        }
        expect(ball.isOnGround, isTrue);

        game.intent.requestJump();
        game.update(1 / 60);
        expect(audio.played, [GameSound.jump]);

        for (var i = 0; i < 20; i++) {
          game.update(1 / 60);
        }
        game.intent.requestJump();
        game.update(1 / 60);
        expect(audio.played, [GameSound.jump]);
      },
    );

    final wallAudio = RecordingAudioSink();
    testWithGame(
      'does not jump off the side of a ledge',
      () => testGame(
        images: images,
        audio: wallAudio,
        // A wall too high to jump, with the ball falling against it.
        levelFor: (_) => const LevelData(
          seed: 'test',
          level: 1,
          ballStart: Vec2(8.75, 0.5),
          goal: Vec2(9.75, -1.75),
          floors: [
            FloorRun(position: Vec2(0, 4), size: Vec2(9, 1.5)),
            FloorRun(position: Vec2(9, 0), size: Vec2(1.5, 5.5)),
          ],
          ramps: [],
          boosts: [],
          checkpoints: [],
          sections: [],
          estimatedDuration: 10,
        ),
      ),
      (game) async {
        game.input!.removeFromParent();
        await game.ready();
        final ball = game.level!.ball;
        game.intent.horizontal = 1;
        var touchedWall = false;
        for (var i = 0; i < 60 && !ball.isOnGround; i++) {
          game.update(1 / 60);
          final p = ball.body.position;
          if (p.x > 9 - LevelComponent.ballRadius - 0.02) {
            touchedWall = true;
            game.intent.requestJump();
          }
        }
        expect(touchedWall, isTrue);
        expect(wallAudio.played, isNot(contains(GameSound.jump)));
      },
    );

    for (final size in [Vector2(800, 360), Vector2(360, 800)]) {
      testWithGame(
        'thumb-sized controls in the bottom corners on $size',
        () => testGame(images: images),
        (game) async {
          game
            ..onGameResize(size)
            ..update(0);
          final margin = HudLayout.margin(size);
          final button = game.camera.viewport.children
              .whereType<JumpButtonComponent>()
              .single
              .toAbsoluteRect();
          final stick = game.joystick.toAbsoluteRect();
          for (final control in [button, stick]) {
            expect(control.width, greaterThanOrEqualTo(72 - 1e-6));
            expect(control.bottom, closeTo(size.y - margin, 1e-3));
          }
          expect(button.right, closeTo(size.x - margin, 1e-3));
          expect(stick.left, closeTo(margin, 1e-3));
          expect(stick.width, closeTo(button.width, 1e-3));
        },
      );
    }

    testWithGame(
      'the jump button requests a jump and shows the press',
      () => testGame(images: images),
      (game) async {
        final button =
            game.camera.viewport.children
                .whereType<JumpButtonComponent>()
                .single
              ..onTapDown(TapDownEvent(1, game, TapDownDetails()));
        expect(game.intent.consumeJump(), isTrue);
        expect(button.isPressed, isTrue);
        button.onTapUp(
          TapUpEvent(1, game, TapUpDetails(kind: PointerDeviceKind.touch)),
        );
        expect(button.isPressed, isFalse);
        button
          ..onTapDown(TapDownEvent(1, game, TapDownDetails()))
          ..onTapCancel(TapCancelEvent(1));
        expect(button.isPressed, isFalse);
      },
    );

    test('the jump button draws an up arrow inside the button', () {
      final bounds = JumpButtonComponent.arrowPath(100).getBounds();
      expect(
        const Rect.fromLTWH(0, 0, 100, 100).contains(bounds.topLeft),
        isTrue,
      );
      expect(
        const Rect.fromLTWH(0, 0, 100, 100).contains(bounds.bottomRight),
        isTrue,
      );
      expect(bounds.center.dx, closeTo(50, 1e-9));
      expect(
        JumpButtonComponent.arrowPath(100).contains(const Offset(50, 25)),
        isTrue,
      );
    });

    final haptics = RecordingHaptics();
    testWithGame(
      'reports a vibration for jumps, boosts and checkpoints only',
      () => testGame(
        images: images,
        haptics: haptics,
        levelFor: (_) => flatLevel(checkpoints: [4.5]),
      ),
      (game) async {
        final ball = game.level!.ball;
        for (var i = 0; i < 120 && !ball.isOnGround; i++) {
          game.update(1 / 60);
        }
        game.intent.requestJump();
        game.update(1 / 60);
        expect(haptics.played, [Haptic.jump]);

        // In mid-air, a press does not jump and does not vibrate.
        for (var i = 0; i < 20; i++) {
          game.update(1 / 60);
        }
        game.intent.requestJump();
        game.update(1 / 60);
        expect(haptics.played, [Haptic.jump]);

        ball.applySpeedBoost(10, Vector2(1, 0));
        ball.body.setTransform(Vector2(4.5, 3.75), const Rot.identity());
        game.update(1 / 60);
        expect(haptics.played, [Haptic.jump, Haptic.boost, Haptic.checkpoint]);
      },
    );

    testWithGame(
      'joystick mode holds no sensor subscription',
      () => testGame(images: images),
      (game) async {
        expect(game.input, isA<ManualInput>());
        expect(game.children.whereType<TiltInput>(), isEmpty);
      },
    );

    final sensor = StreamController<AccelerometerEvent>.broadcast();
    testWithGame(
      'switching modes swaps the input and releases the sensor',
      () => testGame(images: images, sensor: sensor),
      (game) async {
        game.applyConfig(const GameConfig(controlMode: ControlMode.tilt));
        await game.ready();
        final tiltInput = game.input! as TiltInput;
        expect(tiltInput.isListening, isTrue);
        expect(sensor.hasListener, isTrue);

        game.applyConfig(const GameConfig());
        await game.ready();

        expect(game.input, isA<ManualInput>());
        expect(tiltInput.isListening, isFalse);
        expect(sensor.hasListener, isFalse);
      },
    );

    testWithGame(
      'tilt is ignored where it is not available',
      () => testGame(
        images: images,
        config: const GameConfig(
          controlMode: ControlMode.tilt,
          tiltAvailable: false,
        ),
      ),
      (game) async => expect(game.input, isA<ManualInput>()),
    );

    final tiltSensor = StreamController<AccelerometerEvent>.broadcast();
    testWithGame(
      'portrait tilt pushes proportionally and jumps on a shake',
      () => testGame(
        images: images,
        sensor: tiltSensor,
        config: const GameConfig(controlMode: ControlMode.tilt),
      ),
      (game) async {
        game.onGameResize(Vector2(360, 800));
        Future<void> emit(AccelerometerEvent event) async {
          tiltSensor.add(event);
          await Future<void>.delayed(Duration.zero);
        }

        await emit(tilt(-2.5));
        expect(game.intent.horizontal, closeTo(0.5, 1e-9));

        await emit(tilt(0.2));
        expect(game.intent.horizontal, 0);

        await emit(tilt(-20));
        expect(game.intent.horizontal, 1);

        await emit(tilt(0, z: 30));
        expect(game.intent.consumeJump(), isTrue);
      },
    );
  });

  group('camera', () {
    for (final (name, size, minWidth) in [
      ('landscape', Vector2(800, 360), 16.0),
      ('portrait', Vector2(360, 800), 12.0),
    ]) {
      testWithGame(
        'frames the ball in the lower half in $name',
        () => testGame(images: images),
        (game) async {
          game.onGameResize(size);
          for (var i = 0; i < 60; i++) {
            game.update(1 / 60);
          }
          final view = game.camera.visibleWorldRect;
          final ball = game.level!.ball.body.position;
          expect(view.width, greaterThanOrEqualTo(minWidth - 1e-3));
          if (size.x > size.y) {
            expect(view.height, greaterThanOrEqualTo(9 - 1e-3));
          }
          final fraction = (ball.y - view.top) / view.height;
          expect(fraction, inInclusiveRange(0.5, 0.85));
          expect(view.left, lessThan(ball.x));
          expect(view.right, greaterThan(ball.x));
        },
      );
    }

    testWithGame(
      'frames the ball right after a respawn',
      () => testGame(
        images: images,
        levelFor: (_) => flatLevel(tiles: 40, checkpoints: [4.5]),
      ),
      (game) async {
        game.onGameResize(Vector2(800, 360));
        final level = game.level!;
        final ball = level.ball;
        ball.body.setTransform(Vector2(4.5, 3.75), const Rot.identity());
        game.update(1 / 60);
        expect(level.activeCheckpoint, isNotNull);
        ball.body.setTransform(Vector2(50, 3.8), const Rot.identity());
        for (var i = 0; i < 120; i++) {
          game.update(1 / 60);
        }
        ball.body.setTransform(
          Vector2(55, level.fallLine + 1),
          const Rot.identity(),
        );
        game.update(1 / 60);
        final view = game.camera.visibleWorldRect;
        expect(view.center.dx, closeTo(ball.body.position.x, 0.1));
        final position = ball.body.position;
        expect(view.contains(Offset(position.x, position.y)), isTrue);
      },
    );
  });

  group('rendering', () {
    testWithGame(
      'draws a level with every element',
      () => testGame(
        images: images,
        levelFor: (_) => levelGenerator.generate(seed: 'render', level: 45),
      ),
      (game) async {
        final level = game.level!;
        expect(level.data.ramps, isNotEmpty);
        expect(level.data.boosts, isNotEmpty);
        expect(level.data.checkpoints, isNotEmpty);
        expect(level.data.floors.any((run) => run.size.y > 1.5), isTrue);
        // Move the camera along the level so every component is in view once.
        for (final run in level.data.floors) {
          game.camera.moveTo(Vector2(run.left + run.size.x / 2, run.top));
          game.update(0);
          level.renderTree(Canvas(PictureRecorder()));
        }
      },
    );
  });
}

class _NoContact implements Contact {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
