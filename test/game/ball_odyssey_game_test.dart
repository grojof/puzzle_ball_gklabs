import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/components/level_component.dart';
import 'package:puzzle_ball_gklabs/game/game_config.dart';
import 'package:puzzle_ball_gklabs/game/input/manual_input.dart';
import 'package:puzzle_ball_gklabs/game/input/tilt_input.dart';
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
      'tilt pushes proportionally with a dead zone and jumps on a shake',
      () => testGame(
        images: images,
        sensor: tiltSensor,
        config: const GameConfig(controlMode: ControlMode.tilt),
      ),
      (game) async {
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
}

class _NoContact implements Contact {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
