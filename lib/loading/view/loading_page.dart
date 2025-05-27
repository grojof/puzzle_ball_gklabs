import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/loading/loading.dart';
import 'package:puzzle_ball_gklabs/shared/widgets/puzzle_ball_loader.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({
    this.redirectTo,
    super.key,
  });

  final String? redirectTo;

  @override
  Widget build(BuildContext context) {
    final loaderTotalDelay = PuzzleBallLoader.intrinsicAnimationDuration +
        const Duration(milliseconds: 2000);

    final preload = context.watch<PreloadCubit>();

    // ✅ Si ya está precargado desde el principio (cambio idioma u otro rebuild)
    if (preload.state.isComplete) {
      Future.microtask(() async {
        await Future<void>.delayed(loaderTotalDelay); // ⏳ Espera mínima visible
        if (context.mounted) {
          context.go(redirectTo ?? '/menu');
        }
      });
    }

    return BlocListener<PreloadCubit, PreloadState>(
      listenWhen: (prev, next) => !prev.isComplete && next.isComplete,
      listener: (context, _) {
        Future.delayed(loaderTotalDelay, () {
          if (context.mounted) context.go(redirectTo ?? '/menu');
        });
      },
      child: const Scaffold(
        body: Center(child: _LoadingInternal()),
      ),
    );
  }
}

class _LoadingInternal extends StatelessWidget {
  const _LoadingInternal();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return BlocBuilder<PreloadCubit, PreloadState>(
      builder: (context, state) {
        final label = l10n.loadingPhaseLabel(state.currentLabel);
        final message = l10n.loading(label);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PuzzleBallLoader(progress: state.progress),
            const SizedBox(height: 24),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}
