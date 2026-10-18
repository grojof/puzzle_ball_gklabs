import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/settings/cubit/settings_cubit.dart';

/// Quick mute that keeps the stored volumes (game-audio spec).
class SoundToggleFab extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = context.select<SettingsCubit, bool>(
      (cubit) => cubit.state.settings.muted,
    );
    final l10n = context.l10n;

    // Clear of the status bar and the camera cutout (game-hud spec).
    final safeArea = MediaQuery.viewPaddingOf(context);
    return Positioned(
      top: safeArea.top + 12,
      right: safeArea.right + 12,
      child: FloatingActionButton(
        heroTag: 'sound_toggle',
        mini: true,
        tooltip: muted ? l10n.soundUnmute : l10n.soundMute,
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () => unawaited(context.read<SettingsCubit>().toggleMuted()),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            muted ? Icons.volume_off : Icons.volume_up,
            key: ValueKey<bool>(muted),
            size: 20,
          ),
        ),
      ),
    );
  }
}
