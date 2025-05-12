import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';

class ControlModeSelector extends StatelessWidget {
  const ControlModeSelector({super.key});

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
        settings.useSensorControl
            ? 'Control por inclinación'
            : 'Control por joystick',
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        settings.useSensorControl
            ? 'Usa el acelerómetro del dispositivo para mover la bola.'
            : 'Usa el joystick táctil o las teclas para mover la bola.',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Switch.adaptive(
        value: settings.useSensorControl,
        onChanged: (value) {
          context.read<SettingsCubit>().toggleControlMode(useSensor: value);
        },
      ),
    );
  }
}
