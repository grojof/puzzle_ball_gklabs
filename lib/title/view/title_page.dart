import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_ball_gklabs/game/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';
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
  int currentLevel = 3; // Simulación: luego lo leeremos desde SharedPreferences
  void _startGame() {
    context.go('/game');
  }

  void _resetProgress() {
    setState(
      () => currentLevel = 1,
    ); // Simulación: luego se reinicia persistencia
  }

  @override
  void initState() {
    super.initState();

    final settings = context.read<SettingsCubit>().state;
    final bgm = context.read<AudioCubit>().bgm;

    if (settings.soundEnabled && !kIsWeb) {
      bgm.play(Assets.audio.background);
    }
  }

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
                onPressed: _startGame,
                child:
                    Text('${l10n.titleButtonContinue} (Nivel $currentLevel)'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _resetProgress,
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
