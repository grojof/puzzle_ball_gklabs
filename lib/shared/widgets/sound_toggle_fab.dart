import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/game/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';

class SoundToggleFab extends StatelessWidget {
  const SoundToggleFab({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final isEnabled = settings.soundEnabled;

    return Positioned(
      top: 12,
      right: 12,
      child: FloatingActionButton(
        heroTag: 'sound_toggle',
        mini: true,
        tooltip: isEnabled ? 'Sonido activado' : 'Sonido desactivado',
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () async {
          await context.read<SettingsCubit>().toggleSound(
                enabled: !isEnabled,
                audioCubit: context.read<AudioCubit>(),
              );
        },
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            isEnabled ? Icons.volume_up : Icons.volume_off,
            key: ValueKey<bool>(isEnabled),
            size: 20,
          ),
        ),
      ),
    );
  }
}
