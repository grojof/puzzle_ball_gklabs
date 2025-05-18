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

      // Salto solo con barra espaciadora (no arrow up)
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.space) {
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

    // if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
    //   delta.y -= 1;
    // }
    // if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
    //   delta.y += 1;
    // }
    if (keysPressed.contains(LogicalKeyboardKey.keyA)) {
      delta.x -= 1;
    }
    if (keysPressed.contains(LogicalKeyboardKey.keyD)) {
      delta.x += 1;
    }

    if (delta.length2 > 0) {
      keyboardDelta = delta.normalized();
    } else {
      keyboardDelta.setZero();
    }
  }
}
