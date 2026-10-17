import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/app/router.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/ball_odyssey_game.dart';
import 'package:puzzle_ball_gklabs/game/game_config.dart';
import 'package:puzzle_ball_gklabs/game/levels/predefined_levels.dart';
import 'package:puzzle_ball_gklabs/game/view/pause_menu.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/loading/loading.dart';
import 'package:puzzle_ball_gklabs/settings/settings.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/widgets/sound_toggle_fab.dart';

/// Hosts one play session: the game is created once and lives until the
/// player leaves this screen (game-session spec).
class GamePage extends StatefulWidget {
  const new({
    required this.savegameId,
    this.level = 1,
    this.isWeb = kIsWeb,
    super.key,
  });

  final String? savegameId;
  final int level;

  /// Tilt is not available on the web (player-controls spec).
  final bool isWeb;

  @override
  State<GamePage> createState() => GamePageState();
}

@visibleForTesting
class GamePageState extends State<GamePage> {
  static const pauseOverlay = 'pause';

  final FocusNode _focusNode = FocusNode();
  late final AppLifecycleListener _lifecycle;
  BallOdysseyGame? _game;
  SavedGame? _savegame;

  /// The running game; null when there is no savegame or assets are loading.
  @visibleForTesting
  BallOdysseyGame? get game => _game;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onHide: pause);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_game != null) return;
    final id = widget.savegameId;
    _savegame = id == null
        ? null
        : context.read<SavegameCubit>().state.byId(id);
    final savegame = _savegame;
    if (savegame == null) return;
    if (!context.read<PreloadCubit>().state.isComplete) {
      _redirectToLoading();
      return;
    }
    _game = _createGame(savegame);
  }

  BallOdysseyGame _createGame(SavedGame savegame) {
    final theme = Theme.of(context);
    return BallOdysseyGame(
      levelFor: (n) => predefinedLevel(n, savegame.totalLevels),
      startLevel: widget.level.clamp(1, savegame.totalLevels),
      totalLevels: savegame.totalLevels,
      audio: context.read<AudioService>(),
      config: _configOf(context.read<SettingsCubit>().state),
      images: context.read<Images>(),
      levelLabel: (n) => '${context.l10n.labelLevel} $n',
      levelTextStyle: (theme.textTheme.headlineMedium ?? const TextStyle())
          .copyWith(color: Colors.white),
      onLevelCompleted: (n) => unawaited(
        context.read<SavegameCubit>().recordProgress(savegame.id, n + 1),
      ),
      onSessionCompleted: () {
        if (mounted) context.go(AppRoutes.menu);
      },
    );
  }

  GameConfig _configOf(SettingsState state) => GameConfig(
    controlMode: state.settings.controlMode,
    tiltAvailable: !widget.isWeb,
  );

  void _redirectToLoading() {
    final target = AppRoutes.gameAt(widget.savegameId!, widget.level);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(
        '${AppRoutes.loading}?redirect=${Uri.encodeComponent(target)}',
      );
    });
  }

  /// Pauses the simulation and shows the pause menu.
  void pause() {
    final game = _game;
    if (game == null) return;
    game.pauseEngine();
    if (!game.overlays.isActive(pauseOverlay)) game.overlays.add(pauseOverlay);
  }

  void _resume() {
    final game = _game;
    if (game == null) return;
    game
      ..overlays.remove(pauseOverlay)
      ..resumeEngine();
    _focusNode.requestFocus();
  }

  Future<void> _restart() async {
    final game = _game;
    if (game == null) return;
    await game.restartLevel();
    _resume();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _focusNode.dispose();
    _game?.teardown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = _game;
    final savegame = _savegame;
    if (savegame == null) {
      return Scaffold(
        body: Center(child: Text(context.l10n.noSavegameSelected)),
      );
    }
    if (game == null) return const Scaffold();

    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          previous.settings.controlMode != current.settings.controlMode,
      listener: (_, state) => game.applyConfig(_configOf(state)),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned.fill(
              child: GameWidget<BallOdysseyGame>(
                game: game,
                focusNode: _focusNode,
                overlayBuilderMap: {
                  pauseOverlay: (context, _) => PauseMenu(
                    onResume: _resume,
                    onRestart: () => unawaited(_restart()),
                    onSettings: () => context.push(AppRoutes.settings),
                    onLevels: () => context.go(AppRoutes.levelsOf(savegame.id)),
                  ),
                },
              ),
            ),
            const SoundToggleFab(),
            Positioned(
              top: 24,
              left: 24,
              child: FloatingActionButton.small(
                key: const Key('game_pause'),
                heroTag: 'game_pause',
                tooltip: context.l10n.pauseButton,
                backgroundColor: Theme.of(context).colorScheme.primary,
                onPressed: pause,
                child: const Icon(Icons.pause),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
