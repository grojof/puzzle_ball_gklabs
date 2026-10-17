import 'dart:async';

import 'package:flame/components.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Moves the ball with the device's tilt (player-controls spec).
///
/// Reads the accelerometer only while mounted: it exists only in tilt mode,
/// and the subscription is cancelled on removal or [stop].
class TiltInput extends Component {
  new({required this.intent, Stream<AccelerometerEvent> Function()? events})
    : _events = events ?? accelerometerEventStream;

  /// Tilt, in m/s² along the screen's x axis, that gives a full push: about
  /// 30° from flat.
  static const fullPush = 5.0;

  /// Pushes smaller than this fraction of a full push are ignored.
  static const deadZone = 0.08;

  /// A change in z acceleration above this, in m/s², is a shake: a jump.
  static const shakeThreshold = 15.0;

  final MovementIntent intent;
  final Stream<AccelerometerEvent> Function() _events;
  StreamSubscription<AccelerometerEvent>? _subscription;
  double? _lastZ;

  /// Whether the accelerometer is being read.
  bool get isListening => _subscription != null;

  @override
  void onMount() {
    super.onMount();
    _subscription = _events().listen(_onEvent);
  }

  void _onEvent(AccelerometerEvent event) {
    final push = (-event.x / fullPush).clamp(-1.0, 1.0);
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
