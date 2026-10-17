import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';

class ControlModeSelector extends StatelessWidget {
  const new({required this.l10n, super.key});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        settings.useSensorControl ? Icons.sensors : Icons.gamepad,
        color: theme.colorScheme.primary,
      ),
      title: Text(
        settings.useSensorControl ? l10n.controlTilt : l10n.controlJoystick,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        settings.useSensorControl
            ? l10n.controlTiltDesc
            : l10n.controlJoystickDesc,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Switch.adaptive(
        value: settings.useSensorControl,
        onChanged: (value) {
          unawaited(
            context.read<SettingsCubit>().toggleControlMode(useSensor: value),
          );
        },
      ),
    );
  }
}
