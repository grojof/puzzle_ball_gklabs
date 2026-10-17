import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';

/// The in-game pause menu (game-session spec).
class PauseMenu extends StatelessWidget {
  const new({
    required this.onResume,
    required this.onRestart,
    required this.onSettings,
    required this.onLevels,
    super.key,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onSettings;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.pauseTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    key: const Key('pause_resume'),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(l10n.pauseResume),
                    onPressed: onResume,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('pause_restart'),
                    icon: const Icon(Icons.replay),
                    label: Text(l10n.pauseRestart),
                    onPressed: onRestart,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('pause_settings'),
                    icon: const Icon(Icons.settings),
                    label: Text(l10n.settingsTitle),
                    onPressed: onSettings,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    key: const Key('pause_levels'),
                    icon: const Icon(Icons.grid_view),
                    label: Text(l10n.titleButtonLevelSelect),
                    onPressed: onLevels,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
