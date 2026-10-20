import 'dart:async';

import 'package:flutter/services.dart';

/// What happened to the ball, for vibration feedback (player-controls spec).
enum Haptic {
  /// The ball jumped.
  jump,

  /// A boost started.
  boost,

  /// A checkpoint activated.
  checkpoint,

  /// An adrenaline rush started.
  heartbeat,

  /// A bumper or a mace hit the ball.
  hit,
}

/// Where the game sends its vibration events; the game knows nothing else
/// about haptics (design D9).
abstract interface class HapticsSink {
  void play(Haptic haptic);
}

/// A sink that does nothing: the web, where there is no vibration.
class NoHaptics implements HapticsSink {
  const new();

  @override
  void play(Haptic haptic) {}
}

/// The device's haptic feedback, with a different feel per event, while
/// [enabled] says the vibration setting is on (read on every event, so a
/// change applies at once).
class DeviceHaptics implements HapticsSink {
  new({required this.enabled});

  final bool Function() enabled;

  /// The gap between the two pulses of a checkpoint.
  static const checkpointGap = Duration(milliseconds: 120);

  /// The gap between the two soft pulses of a heartbeat.
  static const heartbeatGap = Duration(milliseconds: 280);

  @override
  void play(Haptic haptic) {
    if (!enabled()) return;
    switch (haptic) {
      case Haptic.jump:
        unawaited(HapticFeedback.lightImpact());
      case Haptic.boost:
        unawaited(HapticFeedback.heavyImpact());
      case Haptic.checkpoint:
        unawaited(_doublePulse());
      case Haptic.heartbeat:
        unawaited(_heartbeat());
      case Haptic.hit:
        unawaited(HapticFeedback.vibrate());
    }
  }

  static Future<void> _heartbeat() async {
    await HapticFeedback.lightImpact();
    await Future<void>.delayed(heartbeatGap);
    await HapticFeedback.lightImpact();
  }

  static Future<void> _doublePulse() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(checkpointGap);
    await HapticFeedback.mediumImpact();
  }
}
