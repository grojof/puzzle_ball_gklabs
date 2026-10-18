import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/game/input/tilt_input.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Counts jump requests.
class _CountingIntent extends MovementIntent {
  int jumps = 0;

  @override
  void requestJump() {
    jumps++;
    super.requestJump();
  }
}

void main() {
  late StreamController<AccelerometerEvent> sensor;
  late _CountingIntent intent;
  late TiltInput input;

  setUp(() {
    sensor = StreamController<AccelerometerEvent>();
    intent = _CountingIntent();
    input = TiltInput(intent: intent, events: () => sensor.stream)
      ..onGameResize(Vector2(800, 360))
      ..onMount();
  });

  tearDown(() async {
    input.stop();
    await sensor.close();
  });

  /// Feeds [count] identical readings, as a phone held still does.
  Future<void> hold(double x, double y, {int count = 30}) async {
    for (var i = 0; i < count; i++) {
      sensor.add(AccelerometerEvent(x, y, 2, DateTime(2026)));
    }
    await Future<void>.delayed(Duration.zero);
  }

  group(
    'in landscape, tilting towards the right of the screen pushes right',
    () {
      test('with the device right side up', () async {
        await hold(9.5, 2.5);
        expect(intent.horizontal, closeTo(0.5, 1e-9));
        await hold(9.5, -2.5);
        expect(intent.horizontal, closeTo(-0.5, 1e-9));
      });

      test('with the device left side up', () async {
        await hold(-9.5, -2.5);
        expect(intent.horizontal, closeTo(0.5, 1e-9));
      });

      test('a phone held nearly flat keeps the last side', () async {
        await hold(-9.5, 0);
        await hold(0.5, -2.5);
        expect(intent.horizontal, closeTo(0.5, 1e-9));
      });
    },
  );

  group('a flick towards the player jumps', () {
    /// Feeds z readings 20 ms apart, as at the game interval, from [start].
    Future<DateTime> feed(List<double> zs, DateTime start) async {
      var time = start;
      for (final z in zs) {
        sensor.add(AccelerometerEvent(9.5, 0, z, time));
        time = time.add(const Duration(milliseconds: 20));
      }
      await Future<void>.delayed(Duration.zero);
      return time;
    }

    final rest = List<double>.filled(30, 2);
    final start = DateTime(2026);

    test('a gentle flick jumps once', () async {
      final after = await feed(rest, start);
      await feed([4, 7, 9, 6, 3, 2, 2, 2], after);
      expect(intent.jumps, 1);
    });

    test('small wobbles and steering do not jump', () async {
      var time = await feed(rest, start);
      time = await feed([3.5, 4.5, 3.5, 2, 0.5, 1, 2], time);
      // A quick 30-degree steer moves z by about 1.3 m/s².
      await feed([2, 1.6, 1.2, 0.9, 0.7, 0.7, 0.7], time);
      expect(intent.jumps, 0);
    });

    test('a second flick counts after the cooldown', () async {
      var time = await feed(rest, start);
      time = await feed([9, 2], time);
      time = await feed([9, 2], time);
      expect(intent.jumps, 1);
      time = await feed(List.filled(20, 2), time);
      await feed([9, 2], time);
      expect(intent.jumps, 2);
    });
  });

  test('in portrait, the push comes from x', () async {
    input.onGameResize(Vector2(360, 800));
    await hold(-2.5, 9.5);
    expect(intent.horizontal, closeTo(0.5, 1e-9));
  });
}
