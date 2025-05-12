import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/settings/settings_cubit.dart';

class LevelSelectorPage extends StatelessWidget {
  const LevelSelectorPage({super.key});

  static const int maxLevels = 20; // Puedes ajustar esto

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleSelectLevel),
      ),
      body: const SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: _LevelGrid(),
        ),
      ),
    );
  }
}

class _LevelGrid extends StatelessWidget {
  const _LevelGrid();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsCubit>().state;

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: LevelSelectorPage.maxLevels,
      itemBuilder: (context, index) {
        final levelNumber = index + 1;
        final isUnlocked = levelNumber <= settings.currentLevel;

        return _LevelButton(
          levelNumber: levelNumber,
          isUnlocked: isUnlocked,
        );
      },
    );
  }
}

class _LevelButton extends StatefulWidget {
  const _LevelButton({
    required this.levelNumber,
    required this.isUnlocked,
  });

  final int levelNumber;
  final bool isUnlocked;

  @override
  State<_LevelButton> createState() => _LevelButtonState();
}

class _LevelButtonState extends State<_LevelButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    if (!widget.isUnlocked) return;

    _controller.reverse().then((_) {
      if (!mounted) return;

      context
          .read<SettingsCubit>()
          .setCurrentLevel(widget.levelNumber)
          .then((_) {
        if (mounted) {
          context.go('/game');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.isUnlocked) _controller.reverse();
      },
      onTapUp: (_) {
        if (widget.isUnlocked) _controller.forward().then((_) => _onTap());
      },
      onTapCancel: () {
        if (widget.isUnlocked) _controller.forward();
      },
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: widget.isUnlocked
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isUnlocked
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
          child: widget.isUnlocked
              ? Text(
                  '${widget.levelNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.lock, color: Colors.grey),
        ),
      ),
    );
  }
}
