import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Object?> vibrations;

  setUp(() {
    vibrations = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            vibrations.add(call.arguments);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('DeviceHaptics', () {
    testWidgets('gives each event its own feel', (tester) async {
      DeviceHaptics(enabled: () => true)
        ..play(Haptic.jump)
        ..play(Haptic.boost);
      await tester.pump();
      expect(vibrations, [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.heavyImpact',
      ]);
    });

    testWidgets('pulses twice for a checkpoint', (tester) async {
      DeviceHaptics(enabled: () => true).play(Haptic.checkpoint);
      await tester.pump();
      expect(vibrations, ['HapticFeedbackType.mediumImpact']);
      await tester.pump(DeviceHaptics.checkpointGap);
      expect(vibrations, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.mediumImpact',
      ]);
    });

    testWidgets('beats softly twice for an adrenaline rush', (tester) async {
      DeviceHaptics(enabled: () => true).play(Haptic.heartbeat);
      await tester.pump();
      expect(vibrations, ['HapticFeedbackType.lightImpact']);
      await tester.pump(DeviceHaptics.heartbeatGap);
      expect(vibrations, [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.lightImpact',
      ]);
    });

    testWidgets('stays still while the setting is off', (tester) async {
      var enabled = false;
      final haptics = DeviceHaptics(enabled: () => enabled)..play(Haptic.jump);
      await tester.pump();
      expect(vibrations, isEmpty);

      enabled = true;
      haptics.play(Haptic.jump);
      await tester.pump();
      expect(vibrations, hasLength(1));
    });
  });

  test('NoHaptics does nothing', () {
    const NoHaptics().play(Haptic.boost);
    expect(vibrations, isEmpty);
  });
}
