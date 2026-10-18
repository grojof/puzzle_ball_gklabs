import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/game/input/tilt_input.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  late StreamController<AccelerometerEvent> sensor;
  late MovementIntent intent;
  late TiltInput input;

  setUp(() {
    sensor = StreamController<AccelerometerEvent>();
    intent = MovementIntent();
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

  test('in portrait, the push comes from x', () async {
    input.onGameResize(Vector2(360, 800));
    await hold(-2.5, 9.5);
    expect(intent.horizontal, closeTo(0.5, 1e-9));
  });
}
