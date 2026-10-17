import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/game.dart' hide Route;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/game/game.dart';
import 'package:puzzle_ball_gklabs/game/levels/levels.dart';
import 'package:puzzle_ball_gklabs/game/levels/predefined_levels.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/loading/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/widgets/sound_toggle_fab.dart';

final nullSavedGame = SavedGame(
  id: '',
  seed: '',
  totalLevels: 0,
  currentLevel: 0,
  createdAt: DateTime(2000),
  lastPlayed: DateTime(2000),
);

class GamePage extends StatelessWidget {
  const new({super.key, this.level = 1, this.savegameId});

  final int level;
  final String? savegameId;

  @override
  Widget build(BuildContext context) {
    final preload = context.read<PreloadCubit>();

    // 🔁 Si aún no ha terminado de cargar, redirige a la página de carga
    if (!preload.state.isComplete) {
      // ⚠️ Evita loops infinitos: solo redirige si no estás ya en /loading
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final current = GoRouter.of(context).state.path;
        if (current != '/loading') {
          context.go(
            '/loading?redirect=${Uri.encodeComponent('/game?level=$level&savegame=$savegameId')}',
          );
        }
      });
      return const SizedBox.shrink(); // No renderiza nada mientras redirige
    }

    // 🔽 Continúa con el resto del build (idéntico al tuyo)
    final textStyle = Theme.of(context).textTheme.bodySmall!
        .copyWith(color: Colors.white, fontSize: 4);

    final savegame = savegameId != null
        ? context.read<SavegameCubit>().state.games.firstWhere(
            (g) => g.id == savegameId,
            orElse: () => nullSavedGame,
          )
        : nullSavedGame;

    final isValidSavegame = savegame.id.isNotEmpty;
    final totalLevels = isValidSavegame ? savegame.totalLevels : 100;
    final seed = isValidSavegame ? savegame.seed : '';
    final levelsList = generatePredefinedLevels(totalLevels, seed);

    final game = PuzzleBallGklabs(
      l10n: context.l10n,
      audioCubit: context.read<AudioCubit>(),
      textStyle: textStyle,
      images: context.read<Images>(),
      levelIndex: level - 1,
      levelsList: levelsList,
      onLevelCompleted: () {
        final nextLevel = level + 1;
        if (isValidSavegame) {
          final updated = SavedGame(
            id: savegame.id,
            seed: savegame.seed,
            totalLevels: savegame.totalLevels,
            currentLevel: nextLevel,
            createdAt: savegame.createdAt,
            lastPlayed: DateTime.now(),
          );
          unawaited(context.read<SavegameCubit>().updateGame(updated));
        }
        if (nextLevel <= totalLevels) {
          GoRouter.of(context)
              .go('/game?level=$nextLevel&savegame=${savegame.id}');
        } else {
          GoRouter.of(context).go('/menu');
        }
      },
      onResetRequested: () {
        final now = DateTime.now().millisecondsSinceEpoch;
        GoRouter.of(context)
            .go('/game?level=$level&savegame=${savegame.id}&restart=$now');
      },
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GameWidget(game: game, focusNode: FocusNode()),
        ),
        const SoundToggleFab(),
        Positioned(
          top: 24,
          left: 24,
          child: FloatingActionButton.small(
            heroTag: 'back_to_levels',
            tooltip: context.l10n.titleButtonLevelSelect,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.list),
            onPressed: () {
              GoRouter.of(context).go('/levels?savegame=${savegame.id}');
            },
          ),
        ),
      ],
    );
  }
}
