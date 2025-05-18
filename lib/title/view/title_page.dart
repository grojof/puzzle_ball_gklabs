import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/theme/app_theme.dart';
import 'package:puzzle_ball_gklabs/shared/widgets/widgets.dart';

class TitlePage extends StatelessWidget {
  const TitlePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleAppBarTitle),
      ),
      body: const SafeArea(child: TitleView()),
    );
  }
}

class TitleView extends StatefulWidget {
  const TitleView({super.key});

  @override
  State<TitleView> createState() => _TitleViewState();
}

class _TitleViewState extends State<TitleView> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.titleAppBarTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  final games = context.read<SavegameCubit>().state.games;
                  if (games.isEmpty) {
                    context.go('/savegames');
                  } else {
                    final sorted = List<SavedGame>.from(games)
                      ..sort((a, b) => b.lastPlayed.compareTo(a.lastPlayed));
                    final lastGame = sorted.first;
                    context.go('/levels?savegame=${lastGame.id}');
                  }
                },
                child: Text(l10n.titleButtonContinue),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/savegames'),
                child: Text(l10n.titleSelectSavegame),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  // TODO: lógica de reset de partidas guardadas
                  // Por ahora, solo muestra un dialog
                  await showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.titleResetProgress),
                      content: Text(l10n.titleResetProgressConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.titleCancel),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: lógica real de reset
                            Navigator.pop(context);
                          },
                          child: Text(l10n.titleConfirm),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: Text(l10n.titleButtonRestart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  context.go('/levels');
                },
                child: Text(l10n.titleButtonLevelSelect),
              ),
              const SizedBox(height: 12),
              const ControlModeSelector(),
              const Spacer(),
            ],
          ),
        ),
        const SoundToggleFab(),
      ],
    );
  }
}
