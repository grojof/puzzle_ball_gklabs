import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/parallax.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/app/router.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/widgets/widgets.dart';

class TitlePage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: TitleView()));
  }
}

class TitleView extends StatefulWidget {
  const new({super.key});
  @override
  State<TitleView> createState() => _TitleViewState();
}

class _TitleViewState extends State<TitleView> {
  late final _MenuParallaxGame _game;

  @override
  void initState() {
    super.initState();
    _game = _MenuParallaxGame();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        GameWidget(game: _game),
        Container(color: Colors.black.withValues(alpha: 0.3)),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                l10n.titleAppBarTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: const [Shadow(blurRadius: 4, offset: Offset(2, 2))],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  final last = context.read<SavegameCubit>().state.lastPlayed;
                  context.go(
                    last == null
                        ? AppRoutes.savegames
                        : AppRoutes.levelsOf(last.id),
                  );
                },
                child: Text(l10n.titleButtonContinue),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.savegames),
                child: Text(l10n.titleSelectSavegame),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('title_settings'),
                icon: const Icon(Icons.settings),
                label: Text(l10n.settingsTitle),
                onPressed: () => context.push(AppRoutes.settings),
              ),
              const Spacer(),
              Text(
                'Developed by Guillermo Rojo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SoundToggleFab(),
      ],
    );
  }
}

class _MenuParallaxGame extends FlameGame {
  new();

  @override
  Future<void> onLoad() async {
    final layer1 = await ParallaxLayer.load(
      ParallaxImageData('parallax/layer1.png'),
      velocityMultiplier: Vector2.zero(),
    );
    final layer2 = await ParallaxLayer.load(
      ParallaxImageData('parallax/layer2.png'),
      velocityMultiplier: Vector2(0.2, 0),
    );
    final layer3 = await ParallaxLayer.load(
      ParallaxImageData('parallax/layer3.png'),
      velocityMultiplier: Vector2(0.5, 0),
    );

    final parallax = ParallaxComponent(
      parallax: Parallax([
        layer1,
        layer2,
        layer3,
      ], baseVelocity: Vector2(20, 0)),
    );

    await add(parallax);
  }
}
