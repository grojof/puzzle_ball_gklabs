import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/settings/cubit/settings_cubit.dart';
import 'package:settings_repository/settings_repository.dart';

/// Applies the player's volumes and mute state to the [AudioService] as soon
/// as they change (game-audio spec).
class AudioSettingsListener extends StatelessWidget {
  const new({required this.child, super.key});

  final Widget child;

  /// Applies [settings] to [audio].
  static Future<void> apply(AudioService audio, PlayerSettings settings) =>
      audio.applySettings(
        musicVolume: settings.musicVolume,
        effectsVolume: settings.effectsVolume,
        muted: settings.muted,
      );

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) => previous.settings != current.settings,
      listener: (context, state) =>
          unawaited(apply(context.read<AudioService>(), state.settings)),
      child: child,
    );
  }
}
