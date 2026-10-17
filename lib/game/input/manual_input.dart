import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';

/// Moves the ball with the on-screen joystick or the `A`/`D` keys, and jumps
/// with `Space` (player-controls spec). Both push at full strength.
class ManualInput extends Component with KeyboardHandler {
  new({required this.intent, required this.joystick});

  final MovementIntent intent;
  final JoystickComponent joystick;

  /// Joystick deflection, as a fraction of its radius, that counts as a push.
  static const joystickThreshold = 0.1;

  int _keyboardDirection = 0;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
      intent.requestJump();
    }
    final left = keysPressed.contains(LogicalKeyboardKey.keyA);
    final right = keysPressed.contains(LogicalKeyboardKey.keyD);
    _keyboardDirection = (right ? 1 : 0) - (left ? 1 : 0);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final knob = joystick.relativeDelta.x;
    intent.horizontal = _keyboardDirection != 0
        ? _keyboardDirection.toDouble()
        : knob.abs() > joystickThreshold
        ? knob.sign
        : 0;
  }

  @override
  void onRemove() {
    intent.horizontal = 0;
    super.onRemove();
  }
}
