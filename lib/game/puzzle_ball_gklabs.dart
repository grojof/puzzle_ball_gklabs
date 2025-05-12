import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/levels/predefined_levels.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';

class PuzzleBallGklabs extends Forge2DGame with HasKeyboardHandlerComponents {
  PuzzleBallGklabs({
    required this.l10n,
    required this.effectPlayer,
    required this.textStyle,
    required Images images,
    required this.levelIndex,
    this.onLevelCompleted,
    this.onResetRequested,
  }) : super(gravity: Vector2(0, 20)) {
    this.images = images;
  }

  final AppLocalizations l10n;
  final AudioPlayer effectPlayer;
  final TextStyle textStyle;
  final int levelIndex;
  final VoidCallback? onLevelCompleted;
  final VoidCallback? onResetRequested;

  late final JoystickComponent joystick;
  late final CameraComponent thirdPersonCamera;
  late final Forge2DWorld gameWorld;

  static const double joystickRadius = 40;
  static const double knobRadius = 12;
  static const double jumpButtonSize = 48;
  static const Color joystickColor = Color(0xFF2196F3);
  static const Color joystickBackground = Color(0x552196F3);
  static const Color jumpButtonColor = Color(0xFF42A5F5);
  static const EdgeInsets joystickMargin =
      EdgeInsets.only(left: 20, bottom: 20);
  static const EdgeInsets jumpButtonMargin =
      EdgeInsets.only(right: 20, bottom: 20);

  @override
  Color backgroundColor() => const Color(0xFFEFEFEF);

  @override
  Future<void> onLoad() async {
    gameWorld = Forge2DWorld();
    await add(gameWorld);

    final level =
        predefinedLevels[levelIndex.clamp(0, predefinedLevels.length - 1)];

    joystick = JoystickComponent(
      knob: CircleComponent(
        radius: knobRadius,
        paint: Paint()..color = joystickColor,
      ),
      background: CircleComponent(
        radius: joystickRadius,
        paint: Paint()..color = joystickBackground,
      ),
      margin: joystickMargin,
    );
    await add(joystick);

    final ball = BallComponent(
      initialPosition: level.ballStart,
      radius: 6,
      paint: Paint()..color = joystickColor,
      onFall: onResetRequested,
    )..joystick = joystick;
    await gameWorld.add(ball);
    await add(BallIsoVisualComponent(
      body: ball.body,
      radius: ball.radius,
      paint: ball.paint,
    ));

    final controller = KeyboardJoystickController(ball);
    ball.keyboardController = controller;
    await gameWorld.add(controller);

    final jumpButton = JumpButtonComponent(
      size: Vector2.all(jumpButtonSize),
      color: jumpButtonColor,
      onPressed: ball.jump,
      margin: jumpButtonMargin,
    );
    await gameWorld.add(jumpButton);

    for (final rect in level.floors) {
      final floor = FloorComponent(
        position: Vector2(rect.left, rect.top),
        size: Vector2(rect.width, rect.height),
      );
      await gameWorld.add(floor);
      await add(FloorIsoVisualComponent(
        body: floor.body,
        visualSize: floor.size,
        paint: floor.paint,
      ));
    }

    for (final rect in level.walls) {
      await gameWorld.add(
        WallComponent(
          position: Vector2(rect.left, rect.top),
          size: Vector2(rect.width, rect.height),
          paint: Paint()..color = const Color(0xFF444444),
        ),
      );
    }

    for (final rect in level.obstacles) {
      await gameWorld.add(
        ObstacleComponent(
          position: Vector2(rect.left, rect.top),
          size: Vector2(rect.width, rect.height),
          paint: Paint()..color = const Color(0xFFE57373),
        ),
      );
    }

    await gameWorld.add(
      GoalComponent(
        position: level.goalPosition,
        size: Vector2.all(30),
        paint: Paint()..color = const Color(0xFF81C784),
      ),
    );

    // 🎥 Cámara tipo Marble Blast
    thirdPersonCamera = CameraComponent(world: gameWorld)
      ..viewfinder.zoom = 2.2
      ..viewfinder.anchor = const Anchor(0.5, 0.85);

    await add(thirdPersonCamera);
    camera = thirdPersonCamera;

    thirdPersonCamera.follow(
      ball,
      maxSpeed: 300,
      snap: true,
    );
  }
}
