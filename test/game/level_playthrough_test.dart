import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/game/ball_envelope.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/components/level_component.dart';

import '../helpers/game_helpers.dart';

const double _dt = 1 / 60;

/// The world's gravity, in m/s².
const double _gravity = 10;

/// A simple player: pushes right, jumps near the end of a run when a gap or a
/// step up follows, and steers in the air to land on the next run. It never
/// jumps before ramps or drops and lets the boosts act on their own.
class _Bot {
  new(this.data);

  final LevelData data;

  /// The right end of the surface the ball last stood on.
  double _launchEnd = 0;

  /// Whether the ball left the ground by jumping, or a jump boost launched it.
  bool _jumped = false;

  /// Time since the ball last touched the ground.
  double _airTime = 0;

  /// How long the current low-gravity boost has run.
  double _lowGravity = 0;

  /// The run chosen at take-off to land on.
  FloorRun? _target;

  /// The world y of the terrain surface at [x], or null over a gap.
  double? surfaceAt(double x) {
    for (final run in data.floors) {
      if (run.left <= x && x < run.right) return run.top;
    }
    for (final ramp in data.ramps) {
      if (ramp.left <= x && x < ramp.right) {
        final t = (x - ramp.left) / (ramp.right - ramp.left);
        return ramp.ascending
            ? ramp.bottom + (ramp.top - ramp.bottom) * t
            : ramp.top + (ramp.bottom - ramp.top) * t;
      }
    }
    return null;
  }

  FloorRun? _runUnder(double x, double bottom) {
    for (final run in data.floors) {
      if (x < run.left - 0.05 || x > run.right + 0.05) continue;
      if ((run.top - bottom).abs() < 0.2) return run;
    }
    return null;
  }

  /// Decides the push and the jump for one frame.
  ({double push, bool jump}) act(BallComponent ball) {
    final p = ball.body.position;
    final v = ball.body.linearVelocity;
    final bottom = p.y + LevelComponent.ballRadius;
    if (ball.isOnGround) {
      // Contacts linger for a frame or two after a jump.
      if (_airTime > 0.1) _jumped = false;
      _airTime = 0;
      _target = null;
      for (final boost in data.boosts) {
        final near = (boost.position.x - p.x).abs() < 1;
        if (boost.type == BoostType.jump && near) _jumped = true;
      }
      final run = _runUnder(p.x, bottom);
      if (run == null) {
        for (final ramp in data.ramps) {
          if (ramp.left - 0.3 <= p.x && p.x <= ramp.right + 0.3) {
            _launchEnd = ramp.right;
          }
        }
        return (push: 1, jump: false);
      }
      _launchEnd = run.right;
      final lead = math.max(0.25, v.x * 0.08);
      if (run.right - p.x > lead) return (push: 1, jump: false);
      final next = surfaceAt(run.right + 0.05);
      final jump = next == null || next < run.top - 0.05;
      if (jump) _jumped = true;
      return (push: 1, jump: jump);
    }
    _airTime += _dt;
    // In the air: brake to land on the chosen run, also under a gravity
    // boost, whose low gravity lasts for the rest of its duration.
    final scale = ball.body.gravityScale;
    _lowGravity = scale < 1 ? _lowGravity + _dt : 0;
    // Commit to a landing at take-off, as a player does.
    final target = _target ??= _landingRun(p.x, bottom);
    if (target == null) return (push: 1, jump: false);
    final landing = _landingX(
      p,
      v,
      target.top,
      gravityScale: scale,
      lowGravityFor: scale < 1 ? BallComponent.boostDuration - _lowGravity : 0,
    );
    if (landing == null) return (push: 1, jump: false);
    final high = math.max(
      target.left + 0.6,
      target.right - math.min(1.5, target.size.x / 2),
    );
    return (push: landing > high ? -1 : 1, jump: false);
  }

  /// After a jump, the run beyond the gap; after being launched (a ramp top,
  /// a drop), the nearest run still ahead and below the ball.
  FloorRun? _landingRun(double x, double bottom) {
    FloorRun? target;
    for (final run in data.floors) {
      final candidate = _jumped
          ? run.left >= _launchEnd - 0.01
          : run.right - 1 > x && run.top > bottom - 0.1;
      if (candidate && (target == null || run.left < target.left)) {
        target = run;
      }
    }
    return target;
  }

  /// Where the ball would come down to [top] with no push, integrating like
  /// Box2D (gravity, then linear damping), with gravity scaled by
  /// [gravityScale] for [lowGravityFor] seconds; null if it never gets
  /// there.
  double? _landingX(
    Vector2 position,
    Vector2 velocity,
    double top, {
    required double gravityScale,
    required double lowGravityFor,
  }) {
    const damping = 1 / (1 + _dt * BallComponent.linearDamping);
    final p = position.clone();
    final v = velocity.clone();
    final level = top - LevelComponent.ballRadius;
    for (var i = 0; i < 600; i++) {
      final scale = i * _dt < lowGravityFor ? gravityScale : 1;
      v
        ..y += _gravity * scale * _dt
        ..scale(damping);
      p.addScaled(v, _dt);
      if (v.y > 0 && p.y >= level) return p.x;
    }
    return null;
  }
}

/// Plays generated levels with a bot, so a level the validator accepts but
/// the real physics cannot complete fails here (level-generation spec).
void main() {
  late Images images;
  setUpAll(() async => images = await testImages());

  // One level per scripted stage, plus two deep levels.
  for (final number in [3, 8, 13, 18, 45, 120, 300]) {
    final data = levelGenerator.generate(seed: 'bot', level: number);
    var completed = false;
    testWithGame(
      'the bot completes level $number',
      () => testGame(
        images: images,
        levelFor: (_) => data,
        startLevel: number,
        totalLevels: number,
        onLevelCompleted: (_) => completed = true,
      ),
      (game) async {
        game.input!.removeFromParent();
        await game.ready();
        final level = game.level!;
        final ball = level.ball;
        final bot = _Bot(data);
        final limit = data.estimatedDuration * 2 + 10;
        var respawns = 0;
        for (var time = 0.0; time < limit && !completed; time += _dt) {
          final action = bot.act(ball);
          game.intent.horizontal = action.push;
          if (action.jump) game.intent.requestJump();
          final before = ball.body.position.x;
          game.update(_dt);
          // Lets the goal sequence's futures complete.
          await Future<void>.delayed(Duration.zero);
          if (game.level != level) {
            fail('fell with no checkpoint at x ${before.toStringAsFixed(1)}');
          }
          if (ball.body.position.x < before - 2) respawns++;
        }
        expect(completed, isTrue, reason: 'stuck at ${ball.body.position}');
        expect(respawns, 0, reason: 'respawned at a checkpoint');
      },
    );
  }
}
