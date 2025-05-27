import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_ball_gklabs/game/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/game/view/game_page.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/loading/loading.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/savegame/savegame_cubit.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_state.dart';
import 'package:puzzle_ball_gklabs/shared/theme/app_theme.dart';
import 'package:puzzle_ball_gklabs/title/view/view.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => PreloadCubit(
            Images(prefix: ''),
            AudioCache(prefix: ''),
          )..loadSequentially(),
        ),
        BlocProvider(
          create: (_) => SettingsCubit(),
        ),
        BlocProvider(
          create: (context) {
            final preload = context.read<PreloadCubit>();
            final cubit = AudioCubit(audioCache: preload.audio);

            // final settings = context.read<SettingsCubit>().state;
            // cubit.setVolume(settings.soundEnabled ? 0.0 : 1.0);

            return cubit;
          },
        ),
        BlocProvider(
          create: (_) => SavegameCubit(),
        ),
      ],
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.select((SettingsCubit c) => c.state.locale);

    final router = GoRouter(
      initialLocation: '/loading',
      routes: [
        GoRoute(
          path: '/loading',
          builder: (context, state) {
            final redirectTo = state.uri.queryParameters['redirect'];
            return LoadingPage(redirectTo: redirectTo);
          },
        ),
        GoRoute(path: '/menu', builder: (_, __) => const TitlePage()),
        GoRoute(
          path: '/game',
          builder: (context, state) {
            final level =
                int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
            final savegameId = state.uri.queryParameters['savegame'];
            return GamePage(level: level, savegameId: savegameId);
          },
        ),
        GoRoute(
          path: '/levels',
          builder: (_, __) => const LevelSelectorPage(),
        ),
        GoRoute(
          path: '/savegames',
          builder: (_, __) => const SavegameSelectorPage(),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
