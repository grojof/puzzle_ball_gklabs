import 'dart:async';

import 'package:flame/components.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Moves the ball with the device's tilt, relative to the screen as the
/// player holds it (player-controls spec, design D8).
///
/// The accelerometer reports axes of the device's natural (portrait)
/// orientation: x to its right, y to its top, +g upwards. In portrait the
/// push comes from x; in landscape from y, signed by the side the phone is
/// turned to, which gravity on x gives.
///
/// Reads the accelerometer only while mounted: it exists only in tilt mode,
/// and the subscription is cancelled on removal or [stop].
class TiltInput extends Component {
  new({required this.intent, Stream<AccelerometerEvent> Function()? events})
    : _events = events ?? accelerometerEventStream;

  /// Tilt, in m/s² along the screen's horizontal axis, that gives a full
  /// push: about 30° from flat.
  static const fullPush = 5.0;

  /// Pushes smaller than this fraction of a full push are ignored.
  static const deadZone = 0.08;

  /// A change in z acceleration above this, in m/s², is a shake: a jump.
  static const shakeThreshold = 15.0;

  /// Gravity along x, in m/s², beyond which the landscape side is known.
  static const sideThreshold = 3.0;

  final MovementIntent intent;
  final Stream<AccelerometerEvent> Function() _events;
  StreamSubscription<AccelerometerEvent>? _subscription;
  double? _lastZ;
  bool _landscape = false;

  /// Gravity along the device's x axis, low-pass filtered.
  double _gravityX = 0;

  /// +1 when the device's right side is up (its top to the screen's left),
  /// -1 the other way round.
  double _side = 1;

  /// Whether the accelerometer is being read.
  bool get isListening => _subscription != null;

  @override
  void onMount() {
    super.onMount();
    _subscription = _events().listen(_onEvent);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _landscape = size.x > size.y;
  }

  void _onEvent(AccelerometerEvent event) {
    _gravityX = 0.9 * _gravityX + 0.1 * event.x;
    if (_gravityX.abs() > sideThreshold) _side = _gravityX.sign;
    final tilt = _landscape ? _side * event.y : -event.x;
    final push = (tilt / fullPush).clamp(-1.0, 1.0);
    intent.horizontal = push.abs() < deadZone ? 0 : push;
    final lastZ = _lastZ;
    if (lastZ != null && (event.z - lastZ).abs() > shakeThreshold) {
      intent.requestJump();
    }
    _lastZ = event.z;
  }

  /// Cancels the subscription; also called when the game is torn down, where
  /// [onRemove] would not run.
  void stop() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    intent.horizontal = 0;
  }

  @override
  void onRemove() {
    stop();
    super.onRemove();
  }
}
