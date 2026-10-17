import 'package:flame/cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/game/view/game_page.dart';
import 'package:puzzle_ball_gklabs/game/view/pause_menu.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/settings/settings.dart';
import 'package:savegame_repository/savegame_repository.dart';

import '../../helpers/game_helpers.dart';
import '../../helpers/pump_app.dart';

void main() {
  late Images images;

  setUpAll(() async => images = await testImages());

  final savegame = SavedGame(
    id: 'g1',
    seed: '1',
    totalLevels: 5,
    currentLevel: 1,
    createdAt: DateTime(2026, 10),
    lastPlayed: DateTime(2026, 10),
  );

  /// Pumps the game route with a settings route above it and returns the
  /// page state once the game has loaded.
  Future<(TestDependencies, GoRouter)> pumpGame(WidgetTester tester) async {
    final deps = TestDependencies(images: images);
    final router = GoRouter(
      initialLocation: '/game',
      routes: [
        GoRoute(
          path: '/game',
          builder: (_, _) => const GamePage(savegameId: 'g1', isWeb: false),
        ),
        GoRoute(
          path: '/settings',
          builder: (_, _) => const SettingsPage(isWeb: false),
        ),
        GoRoute(path: '/levels', builder: (_, _) => const Text('levels')),
      ],
    );
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await deps.load();
      await deps.savegames.add(savegame);
      await deps.preload.loadSequentially();
    });
    await tester.runAsync(() async {
      await tester.pumpWidget(
        deps.wrap(
          MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: localizationsDelegates,
            supportedLocales: supportedLocales,
          ),
        ),
      );
      final state = tester.state<GamePageState>(find.byType(GamePage));
      await state.game!.loaded;
    });
    await tester.pump();
    return (deps, router);
  }

  group('GamePage', () {
    testWidgets('creates one game and pauses on demand', (tester) async {
      await pumpGame(tester);
      final state = tester.state<GamePageState>(find.byType(GamePage));
      final game = state.game!;

      await tester.tap(find.byKey(const Key('game_pause')));
      await tester.pump();

      expect(game.paused, isTrue);
      expect(find.byType(PauseMenu), findsOneWidget);

      await tester.tap(find.byKey(const Key('pause_resume')));
      await tester.pump();

      expect(game.paused, isFalse);
      expect(find.byType(PauseMenu), findsNothing);
      expect(state.game, same(game));
    });

    testWidgets('settings from the pause menu keep the game mounted', (
      tester,
    ) async {
      await pumpGame(tester);
      final state = tester.state<GamePageState>(find.byType(GamePage));
      final game = state.game!;

      await tester.tap(find.byKey(const Key('game_pause')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pause_settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(tester.state<GamePageState>(find.byType(GamePage)), same(state));
      expect(game.paused, isTrue);
      expect(find.byType(PauseMenu), findsOneWidget);
    });

    testWidgets('going to the background shows the pause menu', (tester) async {
      await pumpGame(tester);
      final game = tester.state<GamePageState>(find.byType(GamePage)).game!;

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();

      expect(game.paused, isTrue);
      expect(find.byType(PauseMenu), findsOneWidget);

      tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(game.paused, isTrue);
    });

    testWidgets('leaving the screen destroys the physics world', (
      tester,
    ) async {
      final (_, router) = await pumpGame(tester);
      final game = tester.state<GamePageState>(find.byType(GamePage)).game!;

      await tester.tap(find.byKey(const Key('game_pause')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pause_levels')));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/levels');
      expect(game.world.physicsWorld.isValid, isFalse);
    });

    testWidgets('without a savegame it says so', (tester) async {
      await tester.pumpApp(const GamePage(savegameId: 'missing'));

      expect(find.text('No savegame selected.'), findsOneWidget);
    });
  });
}
