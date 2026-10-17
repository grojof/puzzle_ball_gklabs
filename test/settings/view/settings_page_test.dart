import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/settings/settings.dart';
import 'package:settings_repository/settings_repository.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SettingsPage', () {
    for (final locale in supportedLocales) {
      testWidgets('shows every setting in ${locale.languageCode}', (
        tester,
      ) async {
        final deps = TestDependencies();
        await deps.load();
        await tester.pumpApp(
          const SettingsPage(isWeb: false),
          locale: locale,
          dependencies: deps,
        );
        final l10n = lookupAppLocalizations(locale);

        expect(find.text(l10n.settingsTitle), findsOneWidget);
        expect(find.text(l10n.settingsMusicVolume), findsOneWidget);
        expect(find.text(l10n.settingsEffectsVolume), findsOneWidget);
        expect(find.text(l10n.controlJoystick), findsOneWidget);
        expect(find.text(l10n.controlTilt), findsOneWidget);
        expect(find.text(l10n.settingsLanguageDevice), findsOneWidget);
        expect(find.text('100 %'), findsNWidgets(2));
      });
    }

    testWidgets('does not offer tilt on the web', (tester) async {
      await tester.pumpApp(const SettingsPage(isWeb: true));

      expect(find.byKey(const Key('settings_control_tilt')), findsNothing);
    });

    testWidgets('dragging the music slider applies and stores the volume', (
      tester,
    ) async {
      final deps = await tester.pumpApp(const SettingsPage(isWeb: false));

      await tester.drag(
        find.descendant(
          of: find.byKey(const Key('settings_music_volume')),
          matching: find.byType(Slider),
        ),
        const Offset(-2000, 0),
      );
      await tester.pumpAndSettle();

      expect(deps.settings.state.settings.musicVolume, 0);
      expect(await deps.store.getDouble('musicVolume'), 0);
    });

    testWidgets('releasing the effects slider plays a preview', (tester) async {
      final deps = TestDependencies();
      await deps.load();
      await tester.pumpApp(
        const SettingsPage(isWeb: false),
        dependencies: deps,
      );

      await tester.drag(
        find.descendant(
          of: find.byKey(const Key('settings_effects_volume')),
          matching: find.byType(Slider),
        ),
        const Offset(-100, 0),
      );
      await tester.pumpAndSettle();

      final volume = deps.settings.state.settings.effectsVolume;
      expect(volume, lessThan(1));
      expect(deps.backend.effects[GameSound.jump.asset]!.plays, [volume]);
    });

    testWidgets('choosing tilt and a language updates the settings', (
      tester,
    ) async {
      final deps = await tester.pumpApp(const SettingsPage(isWeb: false));

      await tester.tap(find.byKey(const Key('settings_control_tilt')));
      await tester.scrollUntilVisible(
        find.byKey(const Key('language_ca')),
        100,
      );
      await tester.tap(find.byKey(const Key('language_ca')));
      await tester.pumpAndSettle();

      expect(deps.settings.state.settings.controlMode, ControlMode.tilt);
      expect(deps.settings.state.settings.languageCode, 'ca');

      await tester.tap(find.byKey(const Key('language_device')));
      await tester.pumpAndSettle();
      expect(deps.settings.state.settings.languageCode, isNull);
    });

    testWidgets('closing returns to the screen that opened it', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => TextButton(
              onPressed: () => context.push('/settings'),
              child: const Text('caller'),
            ),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const SettingsPage(isWeb: false),
          ),
        ],
      );
      addTearDown(router.dispose);
      final deps = TestDependencies();
      await tester.pumpWidget(
        deps.wrap(
          MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: localizationsDelegates,
            supportedLocales: supportedLocales,
          ),
        ),
      );

      await tester.tap(find.text('caller'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('caller'), findsOneWidget);
    });
  });
}
