import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';

class KeyboardJoystickController extends KeyboardListenerComponent
    with HasGameReference {
  KeyboardJoystickController(this.ball);

  final BallComponent ball;
  Vector2 keyboardDelta = Vector2.zero();
  Set<LogicalKeyboardKey> keysPressed = {};

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    final useSensor =
        game.buildContext?.read<SettingsCubit>().state.useSensorControl ??
            false;

    if (!useSensor) {
      this.keysPressed = keysPressed;
      if (event is KeyDownEvent &&
          (event.logicalKey == LogicalKeyboardKey.space ||
              event.logicalKey == LogicalKeyboardKey.arrowUp)) {
        ball.jump();
      }
    }

    return true;
  }

  @override
  void update(double dt) {
    final useSensor =
        game.buildContext?.read<SettingsCubit>().state.useSensorControl ??
            false;

    if (useSensor) {
      keyboardDelta.setZero();
      return;
    }

    final delta = Vector2.zero();

    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      delta.y -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      delta.y += 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      delta.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      delta.x += 1;
    }

    keyboardDelta = delta.normalized();
  }
}
