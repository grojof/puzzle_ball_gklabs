import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:key_value_store/key_value_store.dart';
import 'package:puzzle_ball_gklabs/app/app.dart';
import 'package:puzzle_ball_gklabs/app/router.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/settings/settings.dart';
import 'package:savegame_repository/savegame_repository.dart';
import 'package:settings_repository/settings_repository.dart';

import '../audio/audio_service_test.dart' show FakeBackend;

void main() {
  late FakeBackend backend;
  late InMemoryKeyValueStore store;

  setUp(() {
    backend = FakeBackend();
    store = InMemoryKeyValueStore();
  });

  App app({bool isWeb = false}) => App(
    settingsRepository: SettingsRepository(store),
    savegameRepository: SavegameRepository(store),
    audio: AudioService(backend: backend),
    isWeb: isWeb,
    initialLocation: AppRoutes.settings,
  );

  /// Pumps the app and lets its startup (settings, assets, music) finish.
  Future<void> start(WidgetTester tester, App app) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(app);
      for (var i = 0; i < 200 && backend.musicCreated == 0; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      // Images and the final startup steps.
      await Future<void>.delayed(const Duration(milliseconds: 600));
    });
    await tester.pump();
  }

  group('App', () {
    testWidgets('starts the music once loaded, without any tap', (
      tester,
    ) async {
      await start(tester, app());

      expect(backend.music.isPlaying, isTrue);
    });

    testWidgets('a muted start stays silent until unmuted', (tester) async {
      await store.setBool('muted', value: true);
      await start(tester, app());
      expect(backend.music.isPlaying, isFalse);

      final context = tester.element(find.byType(SettingsPage));
      await tester.runAsync(() => context.read<SettingsCubit>().toggleMuted());
      await tester.pump();

      expect(backend.music.isPlaying, isTrue);
    });

    testWidgets('pauses the music in the background and resumes on return', (
      tester,
    ) async {
      await start(tester, app());

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(backend.music.isPlaying, isFalse);

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      expect(backend.music.isPlaying, isTrue);
    });

    testWidgets('on the web, the first tap retries the music', (tester) async {
      await start(tester, app(isWeb: true));
      final calls = backend.music.playCalls;

      await tester.tapAt(const Offset(10, 300));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.tapAt(const Offset(10, 300));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));

      expect(backend.music.playCalls, calls + 1);
    });

    testWidgets('a language change keeps the screen and the router', (
      tester,
    ) async {
      await start(tester, app());
      final before = GoRouter.of(tester.element(find.byType(SettingsPage)));

      final context = tester.element(find.byType(SettingsPage));
      await tester.runAsync(
        () => context.read<SettingsCubit>().setLanguage('es'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ajustes'), findsOneWidget);
      expect(
        GoRouter.of(tester.element(find.byType(SettingsPage))),
        same(before),
      );
    });
  });
}
