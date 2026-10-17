import 'package:go_router/go_router.dart';
import 'package:puzzle_ball_gklabs/game/view/game_page.dart';
import 'package:puzzle_ball_gklabs/loading/loading.dart';
import 'package:puzzle_ball_gklabs/settings/settings.dart';
import 'package:puzzle_ball_gklabs/title/view/view.dart';

/// The app's routes.
abstract final class AppRoutes {
  static const loading = '/loading';
  static const menu = '/menu';
  static const savegames = '/savegames';
  static const levels = '/levels';
  static const game = '/game';
  static const settings = '/settings';

  static String levelsOf(String savegameId) => '$levels?savegame=$savegameId';

  static String gameAt(String savegameId, int level) =>
      '$game?savegame=$savegameId&level=$level';
}

/// Builds the router once for the lifetime of the app (game-session spec:
/// navigation survives a language change).
GoRouter buildRouter({String initialLocation = AppRoutes.loading}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: AppRoutes.loading,
      builder: (_, state) =>
          LoadingPage(redirectTo: state.uri.queryParameters['redirect']),
    ),
    GoRoute(path: AppRoutes.menu, builder: (_, _) => const TitlePage()),
    GoRoute(
      path: AppRoutes.savegames,
      builder: (_, _) => const SavegameSelectorPage(),
    ),
    GoRoute(
      path: AppRoutes.levels,
      builder: (_, _) => const LevelSelectorPage(),
    ),
    GoRoute(
      path: AppRoutes.game,
      builder: (_, state) => GamePage(
        savegameId: state.uri.queryParameters['savegame'],
        level: int.tryParse(state.uri.queryParameters['level'] ?? '') ?? 1,
      ),
    ),
    GoRoute(path: AppRoutes.settings, builder: (_, _) => const SettingsPage()),
  ],
);
