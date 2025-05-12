import 'package:flutter/material.dart';
import 'package:puzzle_ball_gklabs/shared/theme/app_theme.dart';

/// {@template animated_progress_bar}
/// A [Widget] that renders an intrinsically animated progress bar with theme.
/// {@endtemplate}
class AnimatedProgressBar extends StatelessWidget {
  /// {@macro animated_progress_bar}
  const AnimatedProgressBar({
    required this.progress,
    this.height = 24,
    super.key,
  }) : assert(
          progress >= 0.0 && progress <= 1.0,
          'Progress should be between 0.0 and 1.0',
        );

  /// The progress value between 0 and 1
  final double progress;

  /// The height of the progress bar
  final double height;

  /// Duration of the animation
  static const Duration intrinsicAnimationDuration =
      Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        width: 240,
        child: ColoredBox(
          color: AppColors.secondary,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: intrinsicAnimationDuration,
              curve: Curves.easeOutCubic,
              builder: (context, animatedProgress, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: animatedProgress,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(height / 2),
                          color: AppColors.accent,
                          boxShadow: [
                            if (animatedProgress > 0.05)
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
