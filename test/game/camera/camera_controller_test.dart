import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/game/camera/camera_controller.dart';

const double _dt = 1 / 60;
const double _radius = 0.2;

LevelData _level({
  List<FloorRun> floors = const [
    FloorRun(position: Vec2(0, 4), size: Vec2(300, 1.5)),
  ],
  List<Boost> boosts = const [],
}) => LevelData(
  seed: 'camera',
  level: 1,
  ballStart: const Vec2(0.75, 3),
  goal: const Vec2(299, 2.25),
  floors: floors,
  ramps: const [],
  boosts: boosts,
  checkpoints: const [],
  sections: const [],
  estimatedDuration: 10,
);

CameraController _camera(Vector2 viewport, [LevelData? level]) =>
    CameraController(metersToPixels: 40)
      ..viewport = viewport
      ..setLevel(level ?? _level());

/// Where [y] appears on screen, as a fraction of the screen height.
double _screenFraction(CameraController camera, double y) {
  final pixelsPerMeter = camera.zoom * camera.metersToPixels;
  return 0.5 + (y - camera.centre.y) * pixelsPerMeter / camera.viewport.y;
}

/// The visible world width and height, in meters.
(double, double) _visible(CameraController camera) {
  final pixelsPerMeter = camera.zoom * camera.metersToPixels;
  return (
    camera.viewport.x / pixelsPerMeter,
    camera.viewport.y / pixelsPerMeter,
  );
}

void main() {
  final landscape = Vector2(800, 360);
  final portrait = Vector2(360, 800);
  final restOnGround = Vector2(5, 4 - _radius);

  group('framing by screen shape', () {
    test('shows at least 16 m x 9 m in landscape', () {
      final camera = _camera(landscape)..reset(restOnGround);
      final (width, height) = _visible(camera);
      expect(width, greaterThanOrEqualTo(16));
      expect(height, closeTo(9, 1e-9));
    });

    test('shows at least 12 m across in portrait', () {
      final camera = _camera(portrait)..reset(restOnGround);
      final (width, _) = _visible(camera);
      expect(width, closeTo(12, 1e-9));
    });

    test('puts the ground at about 65 % of the screen height', () {
      for (final viewport in [landscape, portrait]) {
        final camera = _camera(viewport)..reset(restOnGround);
        expect(_screenFraction(camera, 4), closeTo(0.65, 1e-6));
        expect(camera.centre.x, restOnGround.x);
      }
    });

    test('re-frames at once when the screen rotates', () {
      final camera = _camera(landscape)
        ..reset(restOnGround)
        ..viewport = portrait;
      expect(camera.zoom, closeTo(camera.restZoom, 1e-9));
    });

    test('gives the same result at 30 and 120 steps per second', () {
      CameraController run(int stepsPerSecond) {
        final camera = _camera(landscape)..reset(restOnGround);
        final moved = Vector2(5, 4 - _radius);
        for (var i = 0; i < stepsPerSecond; i++) {
          camera.update(1 / stepsPerSecond, moved, Vector2(2, 0));
        }
        return camera;
      }

      final slow = run(30);
      final fast = run(120);
      expect(slow.centre.x, closeTo(fast.centre.x, 1e-9));
      expect(slow.centre.y, closeTo(fast.centre.y, 1e-9));
      expect(slow.zoom, closeTo(fast.zoom, 1e-9));
    });
  });

  group('look-ahead and ground', () {
    test('frames more course ahead at top speed, centred at rest', () {
      final camera = _camera(landscape)..reset(restOnGround);
      for (var t = 0.0; t < 3; t += _dt) {
        camera.update(_dt, restOnGround, Vector2(7.8, 0));
      }
      expect(camera.centre.x - restOnGround.x, closeTo(4.68, 0.05));
      for (var t = 0.0; t < 4; t += _dt) {
        camera.update(_dt, restOnGround, Vector2.zero());
      }
      expect(camera.centre.x - restOnGround.x, closeTo(0, 0.01));
    });

    test('rises steadily over a staircase, without swinging back', () {
      final level = _level(
        floors: const [
          FloorRun(position: Vec2(0, 4), size: Vec2(6, 1.5)),
          FloorRun(position: Vec2(6, 3.4), size: Vec2(1.5, 2.1)),
          FloorRun(position: Vec2(7.5, 2.8), size: Vec2(1.5, 2.7)),
          FloorRun(position: Vec2(9, 2.2), size: Vec2(20, 3.3)),
        ],
      );
      final camera = _camera(landscape, level)..reset(Vector2(1, 3.8));
      var previous = camera.centre.y;
      for (var x = 1.0; x < 20; x += 3 * _dt) {
        final top = camera.surfaceAt(x)!;
        camera.update(_dt, Vector2(x, top - _radius), Vector2(3, 0));
        expect(camera.centre.y, lessThanOrEqualTo(previous + 1e-9));
        previous = camera.centre.y;
      }
      expect(_screenFraction(camera, 2.2), closeTo(0.65, 0.01));
    });

    test('stays near ground height during a jump in place', () {
      final camera = _camera(landscape)..reset(restOnGround);
      final start = camera.centre.y;
      // A 3.6 m jump lasting 1.65 s.
      for (var t = 0.0; t < 1.65; t += _dt) {
        final height = 3.6 * 4 * t / 1.65 * (1 - t / 1.65);
        camera.update(_dt, Vector2(5, 3.8 - height), Vector2.zero());
        expect(camera.centre.y, closeTo(start, 0.01));
      }
    });

    test('keeps the ball in view during a jump boost and a fall', () {
      final camera = _camera(landscape)..reset(restOnGround);
      for (final (from, to) in [(3.8, -3.0), (-3.0, 30.0)]) {
        for (var t = 0.0; t <= 1; t += _dt) {
          final y = from + (to - from) * t;
          camera.update(_dt, Vector2(5, y), Vector2.zero());
          expect(
            _screenFraction(camera, y),
            inInclusiveRange(0.15 - 1e-6, 0.85 + 1e-6),
          );
        }
      }
    });

    test('finds surfaces on floors and ramps, and none over gaps', () {
      final camera = CameraController(metersToPixels: 40)
        ..setLevel(
          const LevelData(
            seed: 'camera',
            level: 1,
            ballStart: Vec2(0.75, 3),
            goal: Vec2(9, 0.25),
            floors: [
              FloorRun(position: Vec2(0, 4), size: Vec2(3, 1.5)),
              FloorRun(position: Vec2(6, 2), size: Vec2(4, 1.5)),
            ],
            ramps: [
              Ramp(position: Vec2(3, 2), size: Vec2(2, 2), ascending: true),
            ],
            boosts: [],
            checkpoints: [],
            sections: [],
            estimatedDuration: 10,
          ),
        );
      expect(camera.surfaceAt(1), 4);
      expect(camera.surfaceAt(4), closeTo(3, 1e-9));
      expect(camera.surfaceAt(5.5), isNull);
      expect(camera.surfaceAt(7), 2);
    });

    test('finds surfaces on curves', () {
      final camera = CameraController(metersToPixels: 40)
        ..setLevel(
          LevelData(
            seed: 'camera',
            level: 1,
            ballStart: const Vec2(0.75, 3),
            goal: const Vec2(20, 2.25),
            floors: const [
              FloorRun(position: Vec2(0, 4), size: Vec2(3, 1.5)),
              FloorRun(position: Vec2(11, 4), size: Vec2(10, 1.5)),
            ],
            ramps: const [],
            boosts: const [],
            checkpoints: const [],
            sections: const [],
            estimatedDuration: 10,
            curves: [
              CurvedRun.bumps(
                kind: CurveKind.hill,
                left: 3,
                ground: 4,
                bumps: const [(8, 2)],
              ),
            ],
          ),
        );
      expect(camera.surfaceAt(7), closeTo(2, 1e-9));
      expect(camera.surfaceAt(12), 4);
    });
  });

  group('loops', () {
    test('keep the whole loop in view, steadily, while the ball rides it', () {
      const loop = Loop(foot: Vec2(30, 4), radius: loopRadius);
      final camera = _camera(
        landscape,
        const LevelData(
          seed: 'camera',
          level: 1,
          ballStart: Vec2(0.75, 3),
          goal: Vec2(299, 2.25),
          floors: [FloorRun(position: Vec2(0, 4), size: Vec2(300, 1.5))],
          ramps: [],
          boosts: [],
          checkpoints: [],
          sections: [],
          estimatedDuration: 10,
          loops: [loop],
        ),
      )..reset(Vector2(0, 4 - _radius));
      // Rolls in at speed, around the loop in about a second, and out.
      const speed = 14.0;
      const inner = loopRadius - _radius;
      final c = loop.center;
      final path = <(Vector2, Vector2)>[
        for (var x = 0.0; x < 30; x += speed * _dt)
          (Vector2(x, 4 - _radius), Vector2(speed, 0)),
        for (var a = 0.0; a < 2 * math.pi; a += 6 * _dt)
          (
            Vector2(c.x + inner * math.sin(a), c.y + inner * math.cos(a)),
            Vector2(math.cos(a), -math.sin(a)) * speed,
          ),
        for (var x = 30.0; x < 40; x += speed * _dt)
          (Vector2(x, 4 - _radius), Vector2(speed, 0)),
      ];
      var last = camera.centre.clone();
      var maxStep = 0.0;
      var ridden = false;
      for (final (ball, velocity) in path) {
        camera.update(_dt, ball, velocity);
        final (width, height) = _visible(camera);
        final centre = camera.centre;
        final riding =
            ball.x >= loop.left && ball.x <= loop.right && ball.y < 4 - 1;
        if (riding) {
          ridden = true;
          expect(centre.x - width / 2, lessThanOrEqualTo(loop.left));
          expect(centre.x + width / 2, greaterThanOrEqualTo(loop.right));
          expect(centre.y - height / 2, lessThanOrEqualTo(loop.top));
          expect(centre.y + height / 2, greaterThanOrEqualTo(loop.foot.y));
        }
        if (riding) maxStep = math.max(maxStep, centre.distanceTo(last));
        last = centre.clone();
      }
      expect(ridden, isTrue);
      // The view glides while the ball turns: far less than the ball's own
      // step each frame.
      expect(maxStep, lessThan(speed * _dt * 0.75));
    });
  });

  group('anticipated zoom', () {
    test('is zoomed out before the ball reaches a boost, and back after', () {
      final level = _level(
        boosts: const [Boost(position: Vec2(30, 3.4), type: BoostType.speed)],
      );
      final camera = _camera(landscape, level)..reset(restOnGround);
      final rest = camera.zoom;
      final ball = restOnGround.clone();
      while (ball.x < 30) {
        ball.x += 7.8 * _dt;
        camera.update(_dt, ball, Vector2(7.8, 0));
        if (ball.x < 15) expect(camera.zoom, closeTo(rest, 1e-6));
      }
      expect(camera.zoom, closeTo(rest * CameraController.boostZoom, 0.01));
      for (var t = 0.0; t < 4; t += _dt) {
        ball.x += 3 * _dt;
        camera.update(_dt, ball, Vector2(3, 0));
      }
      expect(camera.zoom, closeTo(rest, 0.01));
    });

    test('zooms out to keep the ground in view high above it', () {
      final camera = _camera(landscape)..reset(restOnGround);
      final rest = camera.zoom;
      // A jump boost: 7 m above the ground, held at the top for a moment.
      for (var t = 0.0; t < 1.5; t += _dt) {
        final y = 3.8 - 7 * (t < 1 ? t : 1);
        camera.update(_dt, Vector2(5, y), Vector2.zero());
      }
      expect(camera.zoom, lessThan(rest));
      expect(_screenFraction(camera, 4), lessThanOrEqualTo(0.7));
      expect(_screenFraction(camera, -3.2), greaterThanOrEqualTo(0.15));

      for (var t = 0.0; t < 2; t += _dt) {
        camera.update(_dt, Vector2(5, -60), Vector2.zero());
      }
      expect(
        camera.zoom / rest,
        closeTo(CameraController.minAltitudeZoom, 1e-4),
      );

      for (var t = 0.0; t < 3; t += _dt) {
        camera.update(_dt, restOnGround, Vector2.zero());
      }
      expect(camera.zoom, closeTo(rest, 1e-3));
    });

    test('zooms out at high speed', () {
      final camera = _camera(landscape)..reset(restOnGround);
      final rest = camera.zoom;
      for (var t = 0.0; t < 2; t += _dt) {
        camera.update(_dt, restOnGround, Vector2(23, 0));
      }
      expect(camera.zoom / rest, closeTo(0.69, 0.01));
    });

    test('a reset frames the ball at once', () {
      final camera = _camera(landscape)..reset(restOnGround);
      for (var t = 0.0; t < 2; t += _dt) {
        camera.update(_dt, Vector2(100, 3.8), Vector2(23, 0));
      }
      final respawn = Vector2(20, 4 - _radius);
      camera.reset(respawn);
      expect(camera.centre.x, respawn.x);
      expect(camera.zoom, camera.restZoom);
      expect(_screenFraction(camera, 4), closeTo(0.65, 1e-6));
    });
  });
}
