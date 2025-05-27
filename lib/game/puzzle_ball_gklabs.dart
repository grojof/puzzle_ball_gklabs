import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flame/parallax.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/levels/levels.dart';
import 'package:puzzle_ball_gklabs/game/utils/camera_utils.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';

class PuzzleBallGklabs extends Forge2DGame with HasKeyboardHandlerComponents {
  PuzzleBallGklabs({
    required this.l10n,
    required this.effectPlayer,
    required this.textStyle,
    required Images images,
    required this.levelIndex,
    required this.levelsList,
    this.onLevelCompleted,
    this.onResetRequested,
  }) : super(gravity: Vector2(0, 10), zoom: 40) {
    this.images = images;
  }

  final AppLocalizations l10n;
  final AudioPlayer effectPlayer;
  final TextStyle textStyle;
  final int levelIndex;
  final VoidCallback? onLevelCompleted;
  final VoidCallback? onResetRequested;
  final List<LevelData> levelsList;

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

  late JoystickComponent joystick;
  late CameraComponent thirdPersonCamera;
  late Forge2DWorld gameWorld;
  late BallComponent ball;
  late ParallaxComponent parallax;
  late ParallaxLayer layer2;
  late ParallaxLayer layer3;

  late double _defaultCameraZoom;
  late Anchor _defaultCameraAnchor;
  bool _isCameraBoosted = false;

  double _targetCameraZoom = 40;
  Anchor _targetCameraAnchor = const Anchor(0.5, 0.85);
  double _cameraLerp = 0.08; // Suavidad de movimiento
  double? _boostZoomEndTime;

  final Vector2 parallaxVelocity = Vector2.zero();

  void _showLevelIndicator(int levelNumber) {
    final baseStyle = textStyle.copyWith(
      fontSize: 40,
      color: Colors.white,
      shadows: [
        const Shadow(
            blurRadius: 4, offset: Offset(2, 2), color: Colors.black54),
      ],
    );

    final text = '${l10n.labelLevel} $levelNumber';
    final textComponent = TextComponent(
      text: text,
      textRenderer: TextPaint(style: baseStyle),
      anchor: Anchor.center,
      position: size / 2,
      priority: 1000,
    );

    double time = 0;

    final effect = _TextFadeController(
      duration: 2.3,
      onOpacityChange: (opacity) {
        textComponent.textRenderer = TextPaint(
          style: baseStyle.copyWith(color: Colors.white.withOpacity(opacity)),
        );
      },
      onComplete: textComponent.removeFromParent,
    );

    camera.viewport.addAll([textComponent, effect]);
  }

  void _updateCameraSmooth() {
    final currentZoom = thirdPersonCamera.viewfinder.zoom;
    thirdPersonCamera.viewfinder.zoom =
        currentZoom + (_targetCameraZoom - currentZoom) * _cameraLerp;
    final currentAnchor = thirdPersonCamera.viewfinder.anchor;
    thirdPersonCamera.viewfinder.anchor = Anchor(
      currentAnchor.x + (_targetCameraAnchor.x - currentAnchor.x) * _cameraLerp,
      currentAnchor.y + (_targetCameraAnchor.y - currentAnchor.y) * _cameraLerp,
    );
  }

  void _adjustCameraHeightForTerrain(Vector2 ballPos) {
    final velocityX = ball.body.linearVelocity.x;
    adjustCameraHeightForTerrain(
      thirdPersonCamera,
      _levelFloors,
      ballPos,
      lookAhead: 8,
      lookBehind: 8,
      lookUp: 3,
      lookDown: 3,
      anchorNormal: const Anchor(0.5, 0.85),
      // cámara baja, muestra más terreno por debajo
      anchorLower: const Anchor(0.5, 0.75),
      // cámara alta, muestra más terreno por arriba
      anchorHigher: const Anchor(0.5, 0.95),
      setTargetAnchor: (anchor) => _targetCameraAnchor = anchor,
      ballVelocityX: velocityX,
    );
  }

  // --- Camera boost hooks ---
  void Function(BoostType type)? onBoostActivated;
  void Function()? onBoostDeactivated;
  late List<FloorData> _levelFloors;
  late List<BoostData> _levelBoosts;

  void handleBoostActivated(BoostType type) {
    if (_isCameraBoosted) return;
    _isCameraBoosted = true;

    // Definir cuánto tiempo dura el zoom especial
    _boostZoomEndTime = currentTime() + 2.0; // 2 segundos desde ahora
  }

  void handleBoostDeactivated() {
    _isCameraBoosted = false;
    _boostZoomEndTime = null;
    _targetCameraZoom = _defaultCameraZoom;
  }

  void adjustCameraAnchorForTerrain(Vector2 ballPos) {
    // Método obsoleto, no hacer nada
  }

  @override
  Color backgroundColor() => const Color(0xFFEFEFEF);

  @override
  Future<void> onLoad() async {
    await _loadLevel();
  }

  Future<void> _loadLevel() async {
    final ballTextureImage =
        images.fromCache(Assets.images.components.ball.path);
    final floorSprite =
        Sprite(images.fromCache(Assets.images.components.floor.path));
    final goalSprite =
        Sprite(images.fromCache(Assets.images.components.goal.path));
    final gravityBoostSprite = Sprite(
      images.fromCache(Assets.images.components.gravityBoost.path),
    );
    final jumpBoostSprite =
        Sprite(images.fromCache(Assets.images.components.jumpBoost.path));
    final speedBoostSprite =
        Sprite(images.fromCache(Assets.images.components.speedBoost.path));

    // 🌍 Crear mundo nuevo
    gameWorld = Forge2DWorld();

    // 📷 Cámara
    thirdPersonCamera = CameraComponent(world: gameWorld)
      ..viewfinder.zoom = 40
      ..viewfinder.anchor = const Anchor(0.5, 0.85);
    _defaultCameraZoom = thirdPersonCamera.viewfinder.zoom;
    _defaultCameraAnchor = thirdPersonCamera.viewfinder.anchor;
    await add(thirdPersonCamera);
    camera = thirdPersonCamera;

    // 1. Crea el parallax y añádelo al gameWorld
    final layer1 = await ParallaxLayer.load(
      ParallaxImageData('parallax/layer1.png'),
      velocityMultiplier: Vector2(0.1, 1),
    );

    layer2 = await ParallaxLayer.load(
      ParallaxImageData('parallax/layer2.png'),
      velocityMultiplier: Vector2(2.5, 1),
    );

    layer3 = await ParallaxLayer.load(
      ParallaxImageData('parallax/layer3.png'),
      velocityMultiplier: Vector2(1, 1),
    );

    final parallaxObject = Parallax(
      [layer1, layer2, layer3],
      baseVelocity: parallaxVelocity,
    );
    parallax = ParallaxComponent(parallax: parallaxObject, priority: -10);
    await camera.backdrop.add(parallax);

    await camera.backdrop.add(parallax);
    await add(gameWorld);

    // 🎯 Cargar nivel
    final level = levelsList[levelIndex.clamp(0, levelsList.length - 1)];
    _levelFloors = level.floorData;
    _levelBoosts = level.boostData;

    // 🎮 Joystick
    joystick = JoystickComponent(
      anchor: Anchor.bottomLeft,
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
    await camera.viewport.add(joystick);

    // 🔘 Botón de salto (referencia diferida)
    final jumpButton = JumpButtonComponent(
      size: Vector2.all(jumpButtonSize),
      color: jumpButtonColor,
      onPressed: () => ball.jump(),
      margin: jumpButtonMargin,
    );
    await camera.viewport.add(jumpButton);

    // 🧱 Elementos del nivel: crea instancias nuevas
    for (final data in level.floorData) {
      await gameWorld.add(
        FloorComponent(
          position: data.position,
          size: data.size,
          sprite: floorSprite,
        ),
      );
    }
    for (final data in level.rampData) {
      await gameWorld.add(
        RampComponent(
          position: data.position,
          size: data.size,
          inverted: data.inverted,
          sprite: floorSprite,
        ),
      );
    }

    // 🚩 Checkpoints
    for (final data in level.checkpointData) {
      await gameWorld.add(
        CheckPointComponent(position: data.position, size: Vector2.all(0.5)),
      );
    }

    // ⚡ Boosts
    for (final data in level.boostData) {
      switch (data.type) {
        case BoostType.jump:
          await gameWorld.add(
            JumpBoostComponent(
              position: data.position,
              size: Vector2.all(1),
              sprite: jumpBoostSprite,
            ),
          );
        case BoostType.speed:
          await gameWorld.add(
            SpeedBoostComponent(
              position: data.position,
              size: Vector2.all(1),
              sprite: speedBoostSprite,
            ),
          );
        case BoostType.gravity:
          await gameWorld.add(
            GravityBoostComponent(
              position: data.position,
              size: Vector2.all(1),
              sprite: gravityBoostSprite,
            ),
          );
      }
    }

    // ⚽ Bola física
    ball = BallComponent(
      effectPlayer: effectPlayer,
      initialPosition: level.ballStart,
      radius: 0.2,
      onFall: resetLevel,
      textureImage: ballTextureImage,
    )..joystick = joystick;
    await gameWorld.add(ball);

    final controller = KeyboardJoystickController(ball);
    ball.keyboardController = controller;
    await gameWorld.add(controller);

    // 🎯 Meta
    await gameWorld.add(
      GoalComponent(
        position: level.goalPosition,
        size: Vector2(1, 3.5),
        sprite: goalSprite,
      ),
    );

    // 🎥 Seguimiento de cámara nativo
    thirdPersonCamera.follow(ball, maxSpeed: 400, snap: true);

    // Suscribirse a eventos de boost (BallComponent ahora tiene los hooks)
    ball.onBoostActivated = handleBoostActivated;
    ball.onBoostDeactivated = handleBoostDeactivated;

    _showLevelIndicator(levelIndex + 1);
  }

  Future<void> resetLevel() async {
    onResetRequested?.call();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final ballVelocityX = ball.body.linearVelocity.x;

    // Velocidad general aplicada a todas las capas (como baseVelocity)
    parallaxVelocity.x = ballVelocityX * 4;

    // Actualiza la lógica del parallax global
    parallax.parallax?.update(dt);

    // ✨ Añadir desplazamiento base individual a capas concretas
    layer2.update(Vector2(10 * dt, 0), dt);
    layer3.update(Vector2(20 * dt, 0), dt);

    _adjustCameraHeightForTerrain(ball.body.position);
    // adjustCameraForBoostsSmooth(
    //   thirdPersonCamera,
    //   _levelBoosts,
    //   ball.body.position,
    //   _defaultCameraZoom,
    //   thirdPersonCamera.viewfinder.zoom,
    //   (newZoom) => _targetCameraZoom = newZoom,
    // );
    final now = currentTime();
    if (_isCameraBoosted &&
        _boostZoomEndTime != null &&
        now < _boostZoomEndTime!) {
      adjustCameraForBoostsSmooth(
        thirdPersonCamera,
        _levelBoosts,
        ball.body.position,
        40, // Zoom alejado
        thirdPersonCamera.viewfinder.zoom,
        (newZoom) => _targetCameraZoom = newZoom,
      );
    } else {
      adjustCameraForBoostsSmooth(
        thirdPersonCamera,
        _levelBoosts,
        ball.body.position,
        _defaultCameraZoom,
        thirdPersonCamera.viewfinder.zoom,
        (newZoom) => _targetCameraZoom = newZoom,
      );
    }
    _updateCameraSmooth();
  }
}

class _TextFadeController extends Component {
  _TextFadeController({
    required this.duration,
    required this.onOpacityChange,
    required this.onComplete,
  });

  final double duration;
  final void Function(double opacity) onOpacityChange;
  final VoidCallback onComplete;

  double _elapsed = 0;

  @override
  void update(double dt) {
    _elapsed += dt;

    double opacity;
    if (_elapsed < 0.3) {
      opacity = _elapsed / 0.3; // fade in
    } else if (_elapsed < 1.8) {
      opacity = 1.0; // hold
    } else if (_elapsed < duration) {
      opacity = 1.0 - ((_elapsed - 1.8) / (duration - 1.8)); // fade out
    } else {
      onComplete();
      removeFromParent();
      return;
    }

    onOpacityChange(opacity.clamp(0.0, 1.0));
  }
}
