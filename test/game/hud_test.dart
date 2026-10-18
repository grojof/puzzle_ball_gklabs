import 'dart:ui';

import 'package:flame/cache.dart';
import 'package:flame/components.dart' show Component;
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';

import '../helpers/game_helpers.dart';

const double _dt = 1 / 60;

void _run(BallOdysseyGame game, double seconds) {
  for (var t = 0.0; t < seconds; t += _dt) {
    game.update(_dt);
  }
}

T _hud<T extends Component>(BallOdysseyGame game) =>
    game.camera.viewport.children.whereType<T>().single;

void main() {
  late Images images;
  setUpAll(() async => images = await testImages());

  group('the ball reports its running boost', () {
    testWithGame(
      'which one, and for how long',
      () => testGame(images: images),
      (game) async {
        final ball = game.level!.ball;
        expect(ball.activeBoost, isNull);
        expect(ball.boostLeft, 0);
        ball.applyJumpBoost(10);
        expect(ball.activeBoost, BoostType.jump);
        expect(ball.boostLeft, closeTo(BallComponent.boostDuration, 1e-9));
        _run(game, 1);
        expect(ball.boostLeft, closeTo(1, 0.05));
        // A new boost replaces it, with its full duration.
        ball.applySpeedBoost(10, Vector2(1, 0));
        expect(ball.activeBoost, BoostType.speed);
        expect(ball.boostLeft, closeTo(BallComponent.boostDuration, 1e-9));
        _run(game, BallComponent.boostDuration + 0.1);
        expect(ball.activeBoost, isNull);
        expect(ball.boostLeft, 0);
        // A respawn ends it.
        ball
          ..applyGravityBoost(0.1)
          ..respawn(Vector2(1, 3));
        expect(ball.activeBoost, isNull);
      },
    );
  });

  group('HudLayout sizes indicators', () {
    test('fixed ones smaller than temporary ones, within limits', () {
      final portrait = Vector2(360, 800);
      expect(HudLayout.flagSize(portrait), closeTo(21.6, 1e-9));
      expect(HudLayout.boostIconSize(portrait), closeTo(28.8, 1e-9));
      expect(HudLayout.messageFontSize(portrait), closeTo(18, 1e-9));
      final landscape = Vector2(1280, 720);
      expect(HudLayout.flagSize(landscape), 28);
      expect(HudLayout.boostIconSize(landscape), 40);
      expect(HudLayout.messageFontSize(landscape), 24);
      final tiny = Vector2(200, 300);
      expect(HudLayout.flagSize(tiny), 20);
      expect(HudLayout.boostIconSize(tiny), 28);
      expect(HudLayout.messageFontSize(tiny), 16);
      for (final screen in [portrait, landscape, tiny]) {
        expect(
          HudLayout.flagSize(screen),
          lessThan(HudLayout.boostIconSize(screen)),
        );
      }
    });
  });

  group('checkpoint track', () {
    testWithGame(
      'follows the checkpoints reached, also after a respawn',
      () => testGame(
        images: images,
        levelFor: (_) => flatLevel(checkpoints: [3, 6, 9]),
      ),
      (game) async {
        final track = _hud<CheckpointTrackComponent>(game);
        final level = game.level!;
        expect(track.shown, [false, false, false]);
        final canvas = Canvas(PictureRecorder());
        track.render(canvas);
        for (final x in [3.0, 6.0]) {
          level.ball.body.setTransform(Vector2(x, 3.75), const Rot.identity());
          game.update(_dt);
        }
        expect(track.shown, [true, true, false]);
        track.render(canvas);
        level.sendBack();
        expect(track.shown, [true, true, false]);
        // Sits under the pause button, at the top left.
        game
          ..onGameResize(Vector2(360, 800))
          ..update(0);
        var rect = track.toAbsoluteRect();
        const under = HudLayout.pauseInset + HudLayout.pauseSize;
        expect(rect.left, closeTo(HudLayout.pauseInset, 10));
        expect(rect.top, greaterThan(under));
        expect(rect.right, lessThan(360 / 2));
        track.render(canvas);
        // With a status bar and a cutout, it moves below them.
        game.safeArea.value = const EdgeInsets.only(top: 40, left: 10);
        rect = track.toAbsoluteRect();
        expect(rect.top, greaterThan(40 + under));
        expect(rect.left, greaterThan(10 + HudLayout.pauseInset));
      },
    );

    testWithGame(
      'is empty without checkpoints',
      () => testGame(images: images),
      (game) async {
        final track = _hud<CheckpointTrackComponent>(game);
        expect(track.shown, isEmpty);
        track.render(Canvas(PictureRecorder()));
      },
    );

    testWithGame(
      'shows a count beyond eight checkpoints',
      () => testGame(
        images: images,
        levelFor: (_) => flatLevel(
          tiles: 20,
          checkpoints: [for (var i = 1; i <= 9; i++) i * 2.5],
        ),
      ),
      (game) async {
        final track = _hud<CheckpointTrackComponent>(game);
        expect(track.shown, hasLength(9));
        final canvas = Canvas(PictureRecorder());
        track.render(canvas);
        game.level!.ball.body.setTransform(
          Vector2(2.5, 3.75),
          const Rot.identity(),
        );
        game.update(_dt);
        track
          ..render(canvas)
          ..removeFromParent();
        game.update(_dt);
      },
    );
  });

  group('boost tray', () {
    for (final type in [BoostType.jump, BoostType.speed, BoostType.gravity]) {
      testWithGame(
        'shows a running ${type.name} boost with an emptying ring',
        () => testGame(images: images),
        (game) async {
          final tray = _hud<BoostTrayComponent>(game);
          final ball = game.level!.ball;
          expect(tray.shown, isEmpty);
          tray.render(Canvas(PictureRecorder()));
          switch (type) {
            case BoostType.jump:
              ball.applyJumpBoost(10);
            case BoostType.speed:
              ball.applySpeedBoost(10, Vector2(1, 0));
            case BoostType.gravity:
            case BoostType.doubleJump:
              ball.applyGravityBoost(0.1);
          }
          expect(tray.shown, [type]);
          expect(tray.ringShare, closeTo(1, 1e-9));
          _run(game, 1);
          expect(tray.ringShare, closeTo(0.5, 0.03));
          tray.render(Canvas(PictureRecorder()));
          _run(game, 1.1);
          expect(tray.shown, isEmpty);
        },
      );
    }

    testWithGame(
      'shows the orb while its charge is held, at the top centre',
      () => testGame(images: images),
      (game) async {
        final tray = _hud<BoostTrayComponent>(game);
        final ball = game.level!.ball..chargeAirJump();
        expect(tray.shown, [BoostType.doubleJump]);
        ball.applyJumpBoost(10);
        expect(tray.shown, [BoostType.jump, BoostType.doubleJump]);
        tray.render(Canvas(PictureRecorder()));
        game
          ..onGameResize(Vector2(800, 360))
          ..update(0);
        // Under the sound button, at the top right, as a column.
        var rect = tray.toAbsoluteRect();
        const under = HudLayout.soundInset + HudLayout.soundSize;
        expect(rect.right, closeTo(800 - HudLayout.soundInset, 10));
        expect(rect.top, greaterThan(under));
        expect(rect.height, greaterThan(rect.width));
        // With a cutout on the right, it moves clear of it.
        game.safeArea.value = const EdgeInsets.only(top: 24, right: 32);
        rect = tray.toAbsoluteRect();
        expect(rect.right, lessThan(800 - 32 - HudLayout.soundInset));
        expect(rect.top, greaterThan(24 + under));
        tray
          ..render(Canvas(PictureRecorder()))
          ..removeFromParent();
        game.update(_dt);
      },
    );
  });

  group('pickup messages', () {
    const orb = Boost(position: Vec2(6, 3.4), type: BoostType.doubleJump);

    testWithGame(
      'pop above the ball for an orb, then fade within a second',
      () => testGame(
        images: images,
        levelFor: (_) => flatLevel(boosts: const [orb], checkpoints: [9]),
      ),
      (game) async {
        final ball = game.level!.ball
          ..body.setTransform(Vector2(6, 3.4), const Rot.identity());
        game.update(_dt);
        await game.ready();
        final message = game.pickupMessage!;
        expect(message.message, HudMessage.doubleJump);
        expect(message.text, 'doubleJump');
        final canvas = Canvas(PictureRecorder());
        for (final t in [0.05, 0.3, 0.3]) {
          _run(game, t);
          // Over the ball, wherever the camera has taken it.
          final ballOnScreen = game.camera.localToGlobal(ball.body.position);
          expect(message.position.x, closeTo(ballOnScreen.x, 1e-3));
          expect(message.position.y, lessThan(ballOnScreen.y));
          expect(message.opacity, greaterThan(0));
          message.render(canvas);
        }
        _run(game, 1);
        expect(game.pickupMessage, isNull);
      },
    );

    testWithGame(
      'pop for a checkpoint, one at a time',
      () => testGame(
        images: images,
        levelFor: (_) => flatLevel(boosts: const [orb], checkpoints: [3]),
      ),
      (game) async {
        final ball = game.level!.ball
          ..body.setTransform(Vector2(3, 3.75), const Rot.identity());
        game.update(_dt);
        await game.ready();
        final first = game.pickupMessage!;
        expect(first.message, HudMessage.checkpoint);
        ball.body.setTransform(Vector2(6, 3.4), const Rot.identity());
        game.update(_dt);
        await game.ready();
        expect(game.pickupMessage!.message, HudMessage.doubleJump);
        expect(first.isMounted, isFalse);
        expect(
          game.camera.viewport.children.whereType<PickupMessageComponent>(),
          hasLength(1),
        );
      },
    );
  });
}
