import 'package:flame/game.dart' hide Route;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_ball_gklabs/game/game.dart';
import 'package:puzzle_ball_gklabs/game/levels/levels.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/loading/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';
import 'package:puzzle_ball_gklabs/shared/widgets/sound_toggle_fab.dart';

class GamePage extends StatelessWidget {
  const GamePage({
    super.key,
    this.level = 1,
  });

  final int level;

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const GamePage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: GameView(level: level),
      ),
    );
  }
}

class GameView extends StatelessWidget {
  const GameView({
    required this.level,
    super.key,
  });

  final int level;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          color: Colors.white,
          fontSize: 4,
        );

    final settings = context.read<SettingsCubit>().state;
    final preload = context.read<PreloadCubit>();

    final game = PuzzleBallGklabs(
      l10n: context.l10n,
      effectPlayer: context.read<AudioCubit>().effectPlayer,
      textStyle: textStyle,
      images: preload.images,
      levelIndex: level - 1,
      onLevelCompleted: () {
        final nextLevel = level + 1;
        context.read<SettingsCubit>().updateMaxLevelIfNeeded(nextLevel);
        if (nextLevel <= predefinedLevels.length) {
          GoRouter.of(context).go('/game?level=$nextLevel');
        } else {
          GoRouter.of(context).go('/menu');
        }
      },
      onResetRequested: () {
        GoRouter.of(context).go('/game?level=$level');
      },
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GameWidget(
            game: game,
            focusNode: FocusNode(),
          ),
        ),
        const SoundToggleFab(),
      ],
    );
  }
}
