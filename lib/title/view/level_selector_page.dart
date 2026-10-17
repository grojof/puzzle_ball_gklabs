import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/app/router.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/savegame/savegame_cubit.dart';

class LevelSelectorPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Obtén el id de la partida seleccionada desde la ruta
    final savegameId = GoRouterState.of(context)
        .uri
        .queryParameters['savegame'];
    final savegames = context.watch<SavegameCubit>().state;
    final partida = savegameId == null ? null : savegames.byId(savegameId);

    if (partida == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.titleSelectLevel)),
        body: Center(child: Text(l10n.noSavegameSelected)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleSelectLevel),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: l10n.titleButtonMenu,
            onPressed: () => context.go(AppRoutes.menu),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${l10n.titleSeed}: ${partida.seed}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Expanded(child: _LevelGrid(partida: partida)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelGrid extends StatelessWidget {
  const new({required this.partida});
  final SavedGame partida;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: partida.totalLevels,
      itemBuilder: (context, index) {
        final levelNumber = index + 1;
        final isUnlocked = levelNumber <= partida.currentLevel;
        return _LevelButton(
          levelNumber: levelNumber,
          isUnlocked: isUnlocked,
          partida: partida,
        );
      },
    );
  }
}

class _LevelButton extends StatelessWidget {
  const new({
    required this.levelNumber,
    required this.isUnlocked,
    required this.partida,
  });
  final int levelNumber;
  final bool isUnlocked;
  final SavedGame partida;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUnlocked
          ? () {
              // Marks the savegame as played now; progress never goes back.
              unawaited(
                context.read<SavegameCubit>().recordProgress(
                  partida.id,
                  levelNumber,
                ),
              );
              context.go(AppRoutes.gameAt(partida.id, levelNumber));
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isUnlocked
              ? [
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(2, 3),
                  ),
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: isUnlocked
            ? Text(
                '$levelNumber',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.lock, color: Colors.grey),
      ),
    );
  }
}
