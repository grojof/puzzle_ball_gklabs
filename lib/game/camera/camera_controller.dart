import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:level_generator/level_generator.dart';

/// Frames the ball and the course (game-camera spec, design D1–D6).
///
/// Plain inputs in, a centre and a zoom out: the game copies them into the
/// viewfinder every frame. Every value moves with a critically damped spring,
/// so the view never jumps or swings, at any frame rate.
class CameraController {
  new({required this.metersToPixels});

  /// Pixels per meter at zoom 1.
  final double metersToPixels;

  /// The narrowest visible world, in meters, in landscape and portrait.
  static const minWidthLandscape = 16.0;
  static const minWidthPortrait = 12.0;

  /// The lowest visible world at rest, in meters.
  static const minHeight = 9.0;

  /// How far above the screen centre the ground sits, as a fraction of the
  /// visible height: the ground ends up at 65 % of the screen height.
  static const groundOffset = 0.15;

  /// The ball stays between these fractions of the screen height.
  static const minBallFraction = 0.15;
  static const maxBallFraction = 0.85;

  /// Look-ahead: seconds of travel, and its limits behind and ahead.
  static const lookAheadTime = 0.6;
  static const maxLookBehind = 3.0;
  static const maxLookAhead = 5.0;

  /// How far ahead the ground is sampled, in meters.
  static const groundReach = 4.0;

  /// Zoom factor around boosts, how early it starts (seconds before the
  /// ball gets there) and how long it holds after passing one.
  static const boostZoom = 0.75;
  static const boostLead = 1.2;
  static const boostHold = 1.5;

  /// Zoom-out with speed, above [speedZoomFrom] m/s, floored at
  /// [minSpeedZoom].
  static const speedZoomFrom = 8.0;
  static const speedZoomRate = 0.03;
  static const minSpeedZoom = 0.6;

  /// How high above the ground the ball may go, as a fraction of the
  /// visible height at rest, before the camera zooms out to keep the ground
  /// in view; and the furthest it zooms out for that (design D10).
  static const altitudeRoom = 0.45;
  static const minAltitudeZoom = 0.5;

  /// Smoothing times, in seconds.
  static const groundSmoothing = 0.35;
  static const lookSmoothing = 0.5;
  static const zoomSmoothing = 0.3;
  static const loopSmoothing = 0.4;

  /// How much room to leave around a loop, in meters (design D8 of
  /// add-curved-terrain-and-physics).
  static const loopMargin = 2.0;

  List<FloorRun> _floors = const [];
  List<Ramp> _ramps = const [];
  List<CurvedRun> _curves = const [];
  List<Boost> _boosts = const [];
  List<Loop> _loops = const [];

  /// The loop last framed, and how far the view has moved onto it, from 0
  /// to 1.
  Loop? _loop;
  final _Spring _loopBlend = _Spring(loopSmoothing);
  Vector2 _viewport = Vector2(800, 360);

  final _Spring _ground = _Spring(groundSmoothing);
  final _Spring _look = _Spring(lookSmoothing);
  final _Spring _zoom = _Spring(zoomSmoothing);
  double _sinceBoost = double.infinity;

  final Vector2 _centre = Vector2.zero();

  /// The world point the camera centres on.
  Vector2 get centre => _centre;

  /// The camera zoom, relative to [metersToPixels].
  double get zoom => _zoom.value;

  /// The level's terrain and boosts, sorted for lookups.
  void setLevel(LevelData level) {
    _floors = [...level.floors]..sort((a, b) => a.left.compareTo(b.left));
    _ramps = [...level.ramps]..sort((a, b) => a.left.compareTo(b.left));
    _curves = [...level.curves]..sort((a, b) => a.left.compareTo(b.left));
    _loops = level.loops;
    _boosts = [...level.boosts]
      ..sort((a, b) => a.position.x.compareTo(b.position.x));
  }

  /// The screen size, in logical pixels. A new size, such as a rotation,
  /// re-frames at once: the zoom scales with the resting zoom.
  Vector2 get viewport => _viewport;
  set viewport(Vector2 size) {
    final before = restZoom;
    _viewport = size.clone();
    _zoom.scale(restZoom / before);
  }

  /// The zoom at rest for the current screen shape (design D3).
  double get restZoom {
    final minWidth = _viewport.x >= _viewport.y
        ? minWidthLandscape
        : minWidthPortrait;
    final pixelsPerMeter = math.min(
      _viewport.x / minWidth,
      _viewport.y / minHeight,
    );
    return pixelsPerMeter / metersToPixels;
  }

  /// Frames [ball] at rest at once: on a new level or a respawn.
  void reset(Vector2 ball) {
    _ground.snap(_groundAround(ball, 0) ?? ball.y);
    _look.snap(0);
    _zoom.snap(restZoom);
    _loopBlend.snap(0);
    _loop = null;
    _sinceBoost = double.infinity;
    _frame(ball);
  }

  /// Advances the camera by [dt] seconds for a ball at [ball] moving at
  /// [velocity].
  void update(double dt, Vector2 ball, Vector2 velocity) {
    final ground = _groundAround(ball, velocity.x);
    if (ground != null) _ground.target = ground;
    _look.target = (velocity.x * lookAheadTime).clamp(
      -maxLookBehind,
      maxLookAhead,
    );
    final loop = _loopAround(ball);
    if (loop != null) _loop = loop;
    _loopBlend.target = loop == null ? 0 : 1;
    _zoom.target =
        restZoom *
        [
          _boostFactor(dt, ball, velocity),
          _speedFactor(velocity),
          _altitudeFactor(ball),
          if (loop != null) _loopFactor(loop),
        ].reduce(math.min);
    _ground.step(dt);
    _look.step(dt);
    _zoom.step(dt);
    _loopBlend.step(dt);
    _frame(ball);
  }

  /// The loop the ball is riding through, if any.
  Loop? _loopAround(Vector2 ball) {
    for (final loop in _loops) {
      if (ball.x >= loop.left &&
          ball.x <= loop.right &&
          ball.y <= loop.foot.y &&
          ball.y >= loop.top - 1) {
        return loop;
      }
    }
    return null;
  }

  /// Zooms out, if needed, to fit [loop] and some room around it.
  double _loopFactor(Loop loop) {
    final pixelsPerMeter = restZoom * metersToPixels;
    final visibleHeight = _viewport.y / pixelsPerMeter;
    final needed = 2 * loop.radius + 2 * loopMargin;
    return math.min(1, visibleHeight / needed);
  }

  /// Places the centre from the smoothed values, keeping the ball in view.
  void _frame(Vector2 ball) {
    final pixelsPerMeter = _zoom.value * metersToPixels;
    final visibleHeight = _viewport.y / pixelsPerMeter;
    var y = _ground.value - groundOffset * visibleHeight;
    final lowest = ball.y - (maxBallFraction - 0.5) * visibleHeight;
    final highest = ball.y - (minBallFraction - 0.5) * visibleHeight;
    y = y.clamp(lowest, highest);
    var x = ball.x + _look.value;
    // Over a loop, the view settles on its centre instead of following
    // each turn of the ball.
    final loop = _loop;
    final blend = _loopBlend.value.clamp(0.0, 1.0);
    if (loop != null && blend > 0) {
      x += (loop.center.x - x) * blend;
      y += (loop.center.y - y) * blend;
    }
    _centre.setValues(x, y);
  }

  /// The highest ground (smallest y) under the ball and up to [groundReach]
  /// ahead in its direction of travel; null over a gap with nothing ahead.
  double? _groundAround(Vector2 ball, double vx) {
    final direction = vx < -0.5 ? -1.0 : 1.0;
    double? highest;
    for (var d = 0.0; d <= groundReach; d += 1) {
      final surface = surfaceAt(ball.x + direction * d);
      if (surface != null && (highest == null || surface < highest)) {
        highest = surface;
      }
    }
    return highest;
  }

  /// The world y of the terrain surface at [x], or null over a gap.
  double? surfaceAt(double x) {
    final run = _find(_floors, x, (r) => r.left, (r) => r.right);
    if (run != null) return run.top;
    final ramp = _find(_ramps, x, (r) => r.left, (r) => r.right);
    if (ramp == null) {
      return _find(_curves, x, (c) => c.left, (c) => c.right)?.heightAt(x);
    }
    final t = (x - ramp.left) / (ramp.right - ramp.left);
    return ramp.ascending
        ? ramp.bottom + (ramp.top - ramp.bottom) * t
        : ramp.top + (ramp.bottom - ramp.top) * t;
  }

  /// The element of [sorted] whose span holds [x], by binary search.
  static T? _find<T>(
    List<T> sorted,
    double x,
    double Function(T) left,
    double Function(T) right,
  ) {
    var low = 0;
    var high = sorted.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final element = sorted[mid];
      if (x < left(element)) {
        high = mid - 1;
      } else if (x >= right(element)) {
        low = mid + 1;
      } else {
        return element;
      }
    }
    return null;
  }

  /// [boostZoom] from [boostLead] seconds before a boost until [boostHold]
  /// seconds after passing it (design D6).
  double _boostFactor(double dt, Vector2 ball, Vector2 velocity) {
    _sinceBoost += dt;
    // The first boost not yet passed.
    var low = 0;
    var high = _boosts.length;
    while (low < high) {
      final mid = (low + high) >> 1;
      if (_boosts[mid].position.x < ball.x - 0.5) {
        low = mid + 1;
      } else {
        high = mid;
      }
    }
    if (low < _boosts.length) {
      final ahead = _boosts[low].position.x - ball.x;
      if (ahead / math.max(velocity.x, 2) < boostLead) _sinceBoost = 0;
    }
    return _sinceBoost < boostHold ? boostZoom : 1;
  }

  /// Below 1 while the ball is more than [altitudeRoom] of the resting
  /// visible height above the ground (design D10).
  double _altitudeFactor(Vector2 ball) {
    final room = altitudeRoom * _viewport.y / (restZoom * metersToPixels);
    final above = _ground.target - ball.y;
    return above <= room ? 1 : math.max(minAltitudeZoom, room / above);
  }

  static double _speedFactor(Vector2 velocity) => math.max(
    minSpeedZoom,
    1 / (1 + speedZoomRate * math.max(0, velocity.length - speedZoomFrom)),
  );
}

/// A value that follows its [target] like a critically damped spring,
/// using the exact solution for a constant target, so any split of the time
/// into steps gives the same result.
class _Spring {
  new(this.smoothingTime);

  final double smoothingTime;
  double value = 0;
  double target = 0;
  double _velocity = 0;

  /// Scales the value, its target and its velocity by [factor].
  void scale(double factor) {
    value *= factor;
    target *= factor;
    _velocity *= factor;
  }

  void snap(double to) {
    value = target = to;
    _velocity = 0;
  }

  void step(double dt) {
    if (dt <= 0) return;
    final omega = 2 / smoothingTime;
    final offset = value - target;
    final temp = (_velocity + omega * offset) * dt;
    final decay = math.exp(-omega * dt);
    _velocity = (_velocity - omega * temp) * decay;
    value = target + (offset + temp) * decay;
  }
}
