import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/savegame/savegame_cubit.dart';
import 'package:puzzle_ball_gklabs/shared/widgets/sound_toggle_fab.dart';

class SavegameSelectorPage extends StatelessWidget {
  const SavegameSelectorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final games = context.watch<SavegameCubit>().state.games;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleSelectSavegame),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: l10n.titleButtonMenu,
            onPressed: () => context.go('/menu'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.titleNewSavegame,
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (context) => _NewSavegameDialog(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: games.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final game = games[index];
                return _SavegameTile(game: game);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SavegameTile extends StatefulWidget {
  const _SavegameTile({required this.game});
  final SavedGame game;

  @override
  State<_SavegameTile> createState() => _SavegameTileState();
}

class _SavegameTileState extends State<_SavegameTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFormat = DateFormat.yMMMd().add_Hm();
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: _expanded,
        onExpansionChanged: (v) => setState(() => _expanded = v),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.save),
        ),
        title: Text('${l10n.titleSeed}: ${widget.game.seed}'),
        subtitle: Text(
          '${l10n.titleLevels}: ${widget.game.currentLevel}/${widget.game.totalLevels}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: l10n.titleResetProgress,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(l10n.titleResetProgress),
                    content: Text(l10n.titleDeleteSavegame),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l10n.titleCancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l10n.titleConfirm),
                      ),
                    ],
                  ),
                );
                if (confirm ?? false) {
                  await context
                      .read<SavegameCubit>()
                      .deleteGame(widget.game.id);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: l10n.titleButtonContinue,
              onPressed: () {
                context.go('/levels?savegame=${widget.game.id}');
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.titleCreated}: ${dateFormat.format(widget.game.createdAt)}',
                ),
                Text(
                  '${l10n.titleLastPlayed}: ${dateFormat.format(widget.game.lastPlayed)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NewSavegameDialog extends StatefulWidget {
  @override
  State<_NewSavegameDialog> createState() => _NewSavegameDialogState();
}

class _NewSavegameDialogState extends State<_NewSavegameDialog> {
  final _formKey = GlobalKey<FormState>();
  int _levels = 50;
  String? _seed;
  bool _showSeedField = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.titleNewSavegame),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _levels.toString(),
                    decoration: InputDecoration(
                      labelText: l10n.titleLevels,
                      helperText: l10n.titleLevelsHelper,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 10) {
                        return l10n.titleLevelsMinError;
                      }
                      return null;
                    },
                    onSaved: (v) => _levels = int.tryParse(v ?? '') ?? 50,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.import_export),
                  tooltip: l10n.titleImportLevels,
                  onPressed: () =>
                      setState(() => _showSeedField = !_showSeedField),
                ),
              ],
            ),
            if (_showSeedField)
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.titleSeed,
                  helperText: l10n.titleSeedHelper,
                ),
                onChanged: (v) => _seed = v.trim().isEmpty ? null : v.trim(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.titleCancel),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              final now = DateTime.now();
              final seed = _seed ?? now.millisecondsSinceEpoch.toString();
              final newGame = SavedGame(
                id: now.microsecondsSinceEpoch.toString(),
                seed: seed,
                totalLevels: _levels,
                currentLevel: 1,
                createdAt: now,
                lastPlayed: now,
              );
              await context.read<SavegameCubit>().addGame(newGame);
              Navigator.pop(context);
            }
          },
          child: Text(l10n.titleCreate),
        ),
      ],
    );
  }
}
