import 'package:flutter/material.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';

class PuzzleBallLoader extends StatefulWidget {
  const PuzzleBallLoader({
    super.key,
    this.progress,
  });

  /// Optional loading progress (0.0 to 1.0) for circular indicator
  final double? progress;

  static const Duration intrinsicAnimationDuration =
      Duration(milliseconds: 300);

  @override
  State<PuzzleBallLoader> createState() => _PuzzleBallLoaderState();
}

class _PuzzleBallLoaderState extends State<PuzzleBallLoader>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = widget.progress?.clamp(0.0, 1.0) ?? 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 40, end: 0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: 1 - (value / 40),
          child: Transform.translate(
            offset: Offset(0, value),
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _rotationController,
            child: SizedBox(
              height: 180,
              width: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Assets.images.loadingBall.image(),
                  if (widget.progress != null)
                    SizedBox(
                      width: 196,
                      height: 196,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 6,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
