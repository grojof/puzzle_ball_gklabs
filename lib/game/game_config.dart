import 'package:equatable/equatable.dart';
import 'package:settings_repository/settings_repository.dart' show ControlMode;

export 'package:settings_repository/settings_repository.dart' show ControlMode;

/// The player settings the game needs, passed in as plain values (design D2).
class GameConfig extends Equatable {
  const new({
    this.controlMode = ControlMode.joystick,
    this.tiltAvailable = true,
  });

  final ControlMode controlMode;

  /// Whether the device has a motion sensor the game may use: false on the
  /// web, where tilt is not offered (player-controls spec).
  final bool tiltAvailable;

  /// Whether tilt drives the ball.
  bool get usesTilt => tiltAvailable && controlMode == ControlMode.tilt;

  @override
  List<Object> get props => [controlMode, tiltAvailable];
}
