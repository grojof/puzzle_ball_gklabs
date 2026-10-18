import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/settings/cubit/settings_cubit.dart';
import 'package:puzzle_ball_gklabs/shared/widgets/language_selector.dart';
import 'package:settings_repository/settings_repository.dart';

/// Music, effects, control mode and language (player-settings spec).
///
/// Pushed over the screen that opens it, so closing it returns there.
class SettingsPage extends StatelessWidget {
  const new({this.isWeb = kIsWeb, super.key});

  /// Tilt control is not offered on the web (player-controls spec).
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = context.select<SettingsCubit, PlayerSettings>(
      (cubit) => cubit.state.settings,
    );
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _VolumeSlider(
              key: const Key('settings_music_volume'),
              icon: Icons.music_note,
              label: l10n.settingsMusicVolume,
              value: settings.musicVolume,
              onChanged: (v) => cubit.setMusicVolume(v, persist: false),
              onChangeEnd: cubit.setMusicVolume,
            ),
            _VolumeSlider(
              key: const Key('settings_effects_volume'),
              icon: Icons.graphic_eq,
              label: l10n.settingsEffectsVolume,
              value: settings.effectsVolume,
              onChanged: (v) => cubit.setEffectsVolume(v, persist: false),
              onChangeEnd: (v) async {
                await cubit.setEffectsVolume(v);
                // Preview at the new volume once audio has applied it.
                if (context.mounted) {
                  context.read<AudioService>().play(GameSound.jump);
                }
              },
            ),
            if (!isWeb) ...[
              const SizedBox(height: 24),
              Text(l10n.settingsControls, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _ControlModeOption(
                mode: ControlMode.joystick,
                selected: settings.controlMode,
                icon: Icons.gamepad,
                title: l10n.controlJoystick,
                subtitle: l10n.controlJoystickDesc,
              ),
              _ControlModeOption(
                mode: ControlMode.tilt,
                selected: settings.controlMode,
                icon: Icons.screen_rotation,
                title: l10n.controlTilt,
                subtitle: l10n.controlTiltDesc,
              ),
              SwitchListTile(
                key: const Key('settings_vibration'),
                secondary: const Icon(Icons.vibration),
                title: Text(l10n.settingsVibration),
                subtitle: Text(l10n.settingsVibrationDesc),
                value: settings.vibration,
                onChanged: (enabled) =>
                    unawaited(cubit.setVibration(enabled: enabled)),
              ),
            ],
            const SizedBox(height: 24),
            Text(l10n.settingsLanguage, style: theme.textTheme.titleMedium),
            const LanguageSelector(),
          ],
        ),
      ),
    );
  }
}

class _VolumeSlider extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
    super.key,
  });

  final IconData icon;
  final String label;
  final double value;
  final Future<void> Function(double) onChanged;
  final Future<void> Function(double) onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final percent = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(label)),
            Text('$percent %'),
          ],
        ),
        Slider(
          value: value,
          divisions: 20,
          label: '$percent %',
          onChanged: (v) => unawaited(onChanged(v)),
          onChangeEnd: (v) => unawaited(onChangeEnd(v)),
        ),
      ],
    );
  }
}

class _ControlModeOption extends StatelessWidget {
  const new({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ControlMode mode;
  final ControlMode selected;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isSelected = mode == selected;
    final color = Theme.of(context).colorScheme.primary;
    return ListTile(
      key: Key('settings_control_${mode.name}'),
      leading: Icon(icon, color: isSelected ? color : null),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected ? Icon(Icons.check_circle, color: color) : null,
      selected: isSelected,
      onTap: () =>
          unawaited(context.read<SettingsCubit>().setControlMode(mode)),
    );
  }
}
