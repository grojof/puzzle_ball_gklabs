import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/game/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/game/view/game_page.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/loading/loading.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/savegame/savegame_cubit.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';
import 'package:puzzle_ball_gklabs/shared/theme/app_theme.dart';
import 'package:puzzle_ball_gklabs/title/view/view.dart';

class App extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    // The image cache is shared by the preloader and the game.
    return RepositoryProvider(
      create: (_) => Images(prefix: ''),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) {
              final cubit = PreloadCubit(
                context.read<Images>(),
                AudioCache(prefix: ''),
              );
              unawaited(cubit.loadSequentially());
              return cubit;
            },
          ),
          BlocProvider(create: (_) => SettingsCubit()),
          BlocProvider(
            create: (context) {
              final cubit = AudioCubit();

              final settings = context.read<SettingsCubit>().state;
              unawaited(cubit.setVolume(settings.soundEnabled ? 1.0 : 0.0));
              // Start the music once the stored settings are loaded.
              unawaited(
                context.read<SettingsCubit>().stream.first.then((loaded) async {
                  if (loaded.soundEnabled) await cubit.enableAndPlay();
                }),
              );

              return cubit;
            },
          ),
          BlocProvider(create: (_) => SavegameCubit()),
        ],
        child: const AppView(),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.select<SettingsCubit, Locale>((c) => c.state.locale);

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
        GoRoute(path: '/menu', builder: (_, _) => const TitlePage()),
        GoRoute(
          path: '/game',
          builder: (context, state) {
            final level =
                int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
            final savegameId = state.uri.queryParameters['savegame'];
            return GamePage(level: level, savegameId: savegameId);
          },
        ),
        GoRoute(path: '/levels', builder: (_, _) => const LevelSelectorPage()),
        GoRoute(
          path: '/savegames',
          builder: (_, _) => const SavegameSelectorPage(),
        ),
      ],
    );

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: locale,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
    );
  }
}
