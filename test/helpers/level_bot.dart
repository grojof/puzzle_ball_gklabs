import 'dart:math' as math;

import 'package:flame/cache.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/components/level_component.dart';

import 'game_helpers.dart';

const double _dt = 1 / 60;

/// The world's gravity, in m/s².
const double _gravity = 10;

/// The speed the bot slows to before a step up onto a short tread, in m/s.
const double _shortTreadSpeed = 4.5;

/// A stretch of ground to land on, clear of spikes.
typedef Landing = ({double left, double right, double top});

/// A simple player: pushes right, jumps close to the end of a run or the
/// start of spikes when a gap, spikes or a step up follows, and steers in the
/// air to land on the ground beyond. It rides ferries, uses an orb's charge
/// when a flight falls short, never jumps before ramps or drops, and lets
/// the boosts act on their own (design D9 of add-physical-mechanics). It
/// keeps pushing over curves and through loops, and after a trampoline's
/// bounce chooses the ground beyond it (design D9 of
/// add-curved-terrain-and-physics).
class LevelBot {
  new(this.data);

  final LevelData data;

  /// The right end of the surface the ball last stood on.
  double _launchEnd = 0;

  /// Whether the ball left the ground by jumping, or a jump boost launched it.
  bool _jumped = false;

  /// Time since the ball last touched the ground.
  double _airTime = 0;

  /// Time since the bot last asked for a jump: it asks once per jump, so
  /// lingering contacts do not spend an orb's charge on the way up.
  double _sinceJump = double.infinity;

  /// How long the current low-gravity boost has run.
  double _lowGravity = 0;

  /// The ground chosen at take-off to land on.
  Landing? _target;

  /// The ground to land on after a jump over spikes, set at take-off.
  Landing? _pending;

  /// The ferry the bot has set off to board, by index.
  int? _boarding;

  /// The ball's vertical speed in the last frame, to notice a bounce.
  double _lastVy = 0;

  /// The world y of the terrain surface at [x], or null over a gap.
  double? surfaceAt(double x) {
    for (final run in data.floors) {
      if (run.left <= x && x < run.right) return run.top;
    }
    for (final curve in data.curves) {
      if (curve.left <= x && x < curve.right) return curve.heightAt(x);
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

  /// The spike strips lying on [run], left to right.
  Iterable<SpikeStrip> _stripsOn(FloorRun run) => data.hazards.where(
    (strip) =>
        (strip.top - run.top).abs() < 1e-6 &&
        strip.left >= run.left &&
        strip.right <= run.right,
  );

  /// The stretches of [run] clear of spikes, from its left.
  List<Landing> _clear(FloorRun run) {
    final stretches = <Landing>[];
    var left = run.left;
    for (final strip in _stripsOn(run)) {
      stretches.add((left: left, right: strip.left, top: run.top));
      left = strip.right;
    }
    stretches.add((left: left, right: run.right, top: run.top));
    return stretches;
  }

  /// Decides the push and the jump for one frame.
  ({double push, bool jump}) act(BallComponent ball) {
    final p = ball.body.position;
    final v = ball.body.linearVelocity;
    final bottom = p.y + LevelComponent.ballRadius;
    // A gravity boost's low gravity runs from its pick-up, on the ground or
    // in the air.
    final scale = ball.body.gravityScale;
    _lowGravity = scale < 1 ? _lowGravity + _dt : 0;
    _sinceJump += _dt;
    // A trampoline just threw the ball up: it lands beyond the pad's run.
    const bounce = TrampolineComponent.launchSpeed * 0.8;
    if (v.y < -bounce && _lastVy > -bounce) {
      for (final pad in data.trampolines) {
        if (p.x < pad.left - 1 || p.x > pad.right + 1) continue;
        _jumped = true;
        _target = null;
        _pending = null;
        _launchEnd = data.floors
            .firstWhere((run) => run.left <= pad.left && pad.right <= run.right)
            .right;
      }
    }
    _lastVy = v.y;
    final action = _decide(ball, p, v, bottom, scale);
    if (!action.jump) return action;
    if (_sinceJump < 0.3) return (push: action.push, jump: false);
    _sinceJump = 0;
    return action;
  }

  ({double push, bool jump}) _decide(
    BallComponent ball,
    Vector2 p,
    Vector2 v,
    double bottom,
    double scale,
  ) {
    // A loop carries the ball around on its own.
    if (ball.isInLoop) return (push: 1, jump: false);
    final ferry = _ferry(ball, p, v, bottom);
    if (ferry != null) return ferry;
    if (ball.isOnGround) {
      // Contacts linger for a frame or two after a jump.
      if (_airTime > 0.1) {
        _jumped = false;
        _pending = null;
      }
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
        for (final curve in data.curves) {
          if (curve.left - 0.3 <= p.x && p.x <= curve.right + 0.3) {
            _launchEnd = curve.right;
          }
        }
        return (push: 1, jump: false);
      }
      _launchEnd = run.right;
      // Spikes ahead on this run come first: their start is the edge.
      final strip = _stripsOn(run)
          .where((strip) => strip.left > p.x - 0.05)
          .firstOrNull;
      if (strip != null) {
        final lead = math.max(0.15, v.x * 0.04);
        if (strip.left - p.x > lead) return (push: 1, jump: false);
        _jumped = true;
        _pending = _clear(run).firstWhere((s) => s.left >= strip.right - 1e-6);
        return (push: 1, jump: true);
      }
      final next = surfaceAt(run.right + 0.05);
      final climb = next == null ? 0.0 : run.top - next;
      // Takes off close to the edge before a gap, as precise gaps need, and
      // before a step up early enough to clear it before the riser. A step
      // too tall to jump has a jump boost or an orb right before it: the
      // boost launches the ball on its own, and after the orb the ball
      // jumps at the riser and again at the apex.
      final rise = climb > 0.05
          ? _riseTime(
              ball,
              climb + 0.05,
              strength: run.surface == FloorSurface.mud
                  ? BallComponent.mudJump
                  : 1,
            )
          : null;
      // Before a step up onto a short tread, slows down so the jump lands
      // on it, as a player would.
      if (rise != null && run.right - p.x < 8 && v.x > _shortTreadSpeed) {
        final tread = data.floors.where(
          (floor) => (floor.left - run.right).abs() < 1e-6,
        );
        if (tread.isNotEmpty && tread.first.size.x <= 2 * tileSize + 1e-6) {
          return (push: -1, jump: false);
        }
      }
      // Against a riser the ball stops a radius short of the edge.
      final lead = rise != null
          ? math.max(0.25, v.x * rise)
          : math.max(climb > 0.05 ? 0.3 : 0.15, v.x * 0.04);
      if (run.right - p.x > lead) return (push: 1, jump: false);
      final jump = next == null || climb > 0.05;
      if (jump) _jumped = true;
      return (push: 1, jump: jump);
    }
    _airTime += _dt;
    // In the air: steer to land on the chosen ground, also under a gravity
    // boost, whose low gravity lasts for the rest of its duration.
    // Commit to a landing at take-off, as a player does.
    final target = _target ??= _pending ?? _landingRun(p.x, bottom);
    if (target == null) return (push: 1, jump: false);
    final force = BallComponent.moveForce / ball.body.mass;
    double? landingWith(double push) => _landingX(
      p,
      v,
      target.top,
      gravityScale: scale,
      lowGravityFor: scale < 1 ? BallComponent.boostDuration - _lowGravity : 0,
      push: push * force,
    );
    // With an orb's charge, jumps again near the apex when the flight would
    // fall short or stay below the ledge.
    if (ball.hasAirJump && v.y > -0.8) {
      final reach = landingWith(1);
      final short = reach == null || reach < target.left + 0.3;
      if (short || bottom > target.top - 0.05) {
        return (push: 1, jump: true);
      }
    }
    // Below a ledge to land on and still before its riser, braking would
    // only pull back into it. Pushing into the riser rolls the ball over its
    // corner at the top, but drags it down on the way up to an air jump.
    // Once over the ledge, it steers as usual, to stay on a short tread.
    if (bottom > target.top && p.x < target.left + LevelComponent.ballRadius) {
      final atRiser = target.left - p.x < LevelComponent.ballRadius + 0.15;
      return (push: atRiser && ball.hasAirJump ? 0 : 1, jump: false);
    }
    // Holds the steady push, as a tilt does, that lands at the far end of
    // the landing area: as fast as possible, and on a flight close to the
    // steady one the generator expects.
    // Before a ferry, lands early to stop and wait for it.
    final ferryAhead = data.platforms.any(
      (route) => (route.start.x - 0.15 - target.right).abs() < 1e-6,
    );
    // On a loop's run, lands before its boost, which only acts on the
    // ground.
    final loopBoost = data.loops
        .where((loop) => target.left <= loop.left && loop.left <= target.right)
        .map((loop) => loop.left - loopBoostLead)
        .where((boost) => boost > p.x)
        .firstOrNull;
    // On a trampoline island, lands on its far half to bounce on from there.
    final island = data.trampolines.any(
      (pad) =>
          pad.left <= target.left + 1e-6 && target.right <= pad.right + 1e-6,
    );
    final high = ferryAhead
        ? target.left + 0.6
        : island
        ? target.right - 0.6
        : loopBoost != null
        ? math.max(target.left + 0.6, loopBoost - 1.2)
        : math.max(
            target.left + 0.6,
            target.right - math.min(1.5, (target.right - target.left) / 2),
          );
    final pushing = landingWith(1);
    if (pushing == null || pushing <= high) return (push: 1, jump: false);
    final braking = landingWith(-1);
    if (braking == null || braking >= high) return (push: -1, jump: false);
    var low = -1.0;
    var up = 1.0;
    for (var i = 0; i < 12; i++) {
      final mid = (low + up) / 2;
      final landing = landingWith(mid);
      if (landing != null && landing > high) {
        up = mid;
      } else {
        low = mid;
      }
    }
    return (push: low, jump: false);
  }

  /// Waits for a ferry at the edge, boards it while it is docked, rides it
  /// and gets off at the far edge; null away from ferries.
  ({double push, bool jump})? _ferry(
    BallComponent ball,
    Vector2 p,
    Vector2 v,
    double bottom,
  ) {
    final level = ball.parent;
    if (level == null) return null;
    final ferries = level.children
        .whereType<MovingPlatformComponent>()
        .toList();
    final force = BallComponent.moveForce / ball.body.mass;
    for (var i = 0; i < ferries.length; i++) {
      final ferry = ferries[i];
      final route = data.platforms[i];
      final nearEdge = route.start.x - 0.15;
      final farEdge = route.end.x + route.size.x + 0.15;
      final deck = ferry.topLeft;
      // On board, or crossing onto or off the deck.
      final aboard =
          p.x >= deck.x - 0.3 &&
          p.x <= deck.x + route.size.x + 0.3 &&
          (bottom - deck.y).abs() < 0.3;
      if (aboard && p.x > nearEdge - 0.05 && p.x < farEdge + 0.05) {
        _target = null;
        _jumped = false;
        if (deck.x + route.size.x >= farEdge - 0.5) {
          return (push: 1, jump: false);
        }
        if (p.x < deck.x + 0.8) return (push: 1, jump: false);
        // Rides in the middle of the deck.
        final carry = ferry.body.linearVelocity.x;
        final desired = deck.x + route.size.x * 0.55;
        final push = ((desired - p.x) * 3 - (v.x - carry) * 1.5).clamp(
          -1.0,
          1.0,
        );
        return (push: push, jump: false);
      }
      // On the run before the ferry: boards while the deck is docked with
      // time to spare, and otherwise stops short of the edge.
      final run = _runUnder(p.x, bottom);
      if (!ball.isOnGround || run == null) continue;
      if ((run.right - nearEdge).abs() > 1e-6) continue;
      if (run.right - p.x > 12) continue;
      // Boards if it gets well onto the deck before the pause ends, and
      // once it has set off, carries on.
      final docked = deck.x - run.right < 0.35;
      if (!docked) _boarding = null;
      if (docked && _boarding == i) return (push: 1, jump: false);
      // The time to roll that far, speeding up from its current speed
      // against the damping.
      final far = deck.x + 0.8 - p.x;
      final speed = math.max(0, v.x);
      final pull = math.max(
        2,
        force - BallComponent.linearDamping * (speed + 2) / 2,
      );
      final aboardIn =
          (-speed + math.sqrt(speed * speed + 2 * pull * far)) / pull;
      if (docked && aboardIn < ferry.pauseLeft) {
        _boarding = i;
        return (push: 1, jump: false);
      }
      final wait = run.right - 0.45;
      final ahead = wait - p.x;
      final allowed = ahead <= 0 ? 0.0 : math.sqrt(1.4 * force * ahead);
      final push = ((allowed - v.x) * 2).clamp(-1.0, 1.0);
      return (push: push, jump: false);
    }
    return null;
  }

  /// The time a jump of [strength] takes to rise [height] meters, or null
  /// if it never gets that high.
  double? _riseTime(
    BallComponent ball,
    double height, {
    required double strength,
  }) {
    const damping = 1 / (1 + _dt * BallComponent.linearDamping);
    var speed = BallComponent.jumpImpulse * strength / ball.body.mass;
    var risen = 0.0;
    for (var time = _dt; speed > 0; time += _dt) {
      speed = (speed - _gravity * _dt) * damping;
      risen += speed * _dt;
      if (risen >= height) return time;
    }
    return null;
  }

  /// After a jump, the run beyond the gap; after being launched (a ramp top,
  /// a drop), the nearest run still ahead and below the ball that does not
  /// end in a drop, since overshooting such a tread only lands lower, unless
  /// it has spikes. Then its first stretch clear of spikes still ahead.
  Landing? _landingRun(double x, double bottom) {
    FloorRun? target;
    FloorRun? tread;
    for (final run in data.floors) {
      final candidate = _jumped
          ? run.left >= _launchEnd - 0.01
          : run.right - 1 > x && run.top > bottom - 0.1;
      if (!candidate) continue;
      final next = surfaceAt(run.right + 0.05);
      // Overshooting a tread with spikes on it lands on the spikes.
      final dropsAfter =
          !_jumped &&
          next != null &&
          next > run.top + 0.05 &&
          _stripsOn(run).isEmpty;
      if (dropsAfter) {
        if (tread == null || run.left < tread.left) tread = run;
      } else if (target == null || run.left < target.left) {
        target = run;
      }
    }
    final run = target ?? tread;
    if (run == null) return null;
    final stretches = _clear(run);
    return stretches.firstWhere(
      (s) => s.right - 1 > x,
      orElse: () => stretches.last,
    );
  }

  /// Where the ball would come down to [top] pushing right with an
  /// acceleration of [push], integrating like Box2D (forces and gravity,
  /// then linear damping), with gravity scaled by [gravityScale] for
  /// [lowGravityFor] seconds; null if it never gets there.
  double? _landingX(
    Vector2 position,
    Vector2 velocity,
    double top, {
    required double gravityScale,
    required double lowGravityFor,
    required double push,
  }) {
    const damping = 1 / (1 + _dt * BallComponent.linearDamping);
    final p = position.clone();
    final v = velocity.clone();
    final level = top - LevelComponent.ballRadius;
    for (var i = 0; i < 600; i++) {
      final scale = i * _dt < lowGravityFor ? gravityScale : 1;
      v
        ..x += push * _dt
        ..y += _gravity * scale * _dt
        ..scale(damping);
      p.addScaled(v, _dt);
      if (v.y > 0 && p.y >= level) return p.x;
    }
    return null;
  }
}

/// A test that [LevelBot] completes [data] as level [number] without falling
/// back to a checkpoint.
void testBotCompletes(
  Images Function() images,
  LevelData data,
  int number, {
  String? description,
}) {
  var completed = false;
  testWithGame(
    description ?? 'the bot completes level $number',
    () => testGame(
      images: images(),
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
      final bot = LevelBot(data);
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
        if (ball.body.position.x < before - 2) {
          respawns++;
          if (respawns == 1) {
            printOnFailure(
              'first respawn after x ${before.toStringAsFixed(2)}',
            );
          }
        }
      }
      expect(completed, isTrue, reason: 'stuck at ${ball.body.position}');
      expect(respawns, 0, reason: 'respawned at a checkpoint');
    },
  );
}
