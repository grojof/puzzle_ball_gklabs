import 'package:audioplayers/audioplayers.dart';
import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/levels/levels.dart';
import 'package:puzzle_ball_gklabs/game/utils/camera_utils.dart';
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
  }) : super(gravity: Vector2(0, 10), zoom: 40) {
    this.images = images;
  }

  final AppLocalizations l10n;
  final AudioPlayer effectPlayer;
  final TextStyle textStyle;
  final int levelIndex;
  final VoidCallback? onLevelCompleted;
  final VoidCallback? onResetRequested;

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

  late double _defaultCameraZoom;
  late Anchor _defaultCameraAnchor;
  bool _isCameraBoosted = false;

  double _targetCameraZoom = 40;
  Anchor _targetCameraAnchor = const Anchor(0.5, 0.85);
  double _cameraLerp = 0.08; // Suavidad de movimiento

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

  void _adjustCameraForBoosts(Vector2 ballPos) => adjustCameraForBoosts(
        thirdPersonCamera,
        _levelBoosts,
        ballPos,
        _defaultCameraZoom,
      );

  void _adjustCameraHeightForTerrain(Vector2 ballPos) {
    final velocityX = ball.body.linearVelocity.x;
    adjustCameraHeightForTerrain(
      thirdPersonCamera,
      _levelFloors,
      ballPos,
      lookAhead: 4.0,
      lookBehind: 8.0,
      lookUp: 8.0,
      lookDown: 8.0,
      anchorNormal: const Anchor(0.5, 0.85),
      anchorUp: const Anchor(0.5, 0.7),
      anchorDown: const Anchor(0.5, 0.95),
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
    _animateCameraZoom(25, duration: 0.4); // Aleja la cámara
  }

  void handleBoostDeactivated() {
    if (!_isCameraBoosted) return;
    _isCameraBoosted = false;
    _animateCameraZoom(
      _defaultCameraZoom,
      duration: 0.5,
    ); // Vuelve a la normalidad
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
    // 🌍 Crear mundo nuevo
    gameWorld = Forge2DWorld();
    await add(gameWorld);

    // 🎯 Cargar nivel
    final level =
        predefinedLevels[levelIndex.clamp(0, predefinedLevels.length - 1)];
    _levelFloors = level.floorData;
    _levelBoosts = level.boostData;

    // 🎮 Joystick
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

    // 🔘 Botón de salto (referencia diferida)
    final jumpButton = JumpButtonComponent(
      size: Vector2.all(jumpButtonSize),
      color: jumpButtonColor,
      onPressed: () => ball.jump,
      margin: jumpButtonMargin,
    );
    await gameWorld.add(jumpButton);

    // 🧱 Elementos del nivel: crea instancias nuevas
    for (final data in level.floorData) {
      await gameWorld
          .add(FloorComponent(position: data.position, size: data.size));
    }
    for (final data in level.rampData) {
      await gameWorld.add(
        RampComponent(
          position: data.position,
          size: data.size,
          inverted: data.inverted,
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
              size: Vector2.all(0.4),
            ),
          );
        case BoostType.speed:
          await gameWorld.add(
            SpeedBoostComponent(
              position: data.position,
              size: Vector2.all(0.4),
            ),
          );
        case BoostType.gravity:
          await gameWorld.add(
            GravityBoostComponent(
              position: data.position,
              size: Vector2.all(0.4),
            ),
          );
      }
    }

    // ⚽ Bola física
    ball = BallComponent(
      initialPosition: level.ballStart,
      radius: 0.2,
      paint: Paint()..color = joystickColor,
      onFall: resetLevel,
    )..joystick = joystick;
    await gameWorld.add(ball);

    final controller = KeyboardJoystickController(ball);
    ball.keyboardController = controller;
    await gameWorld.add(controller);

    // 📷 Cámara
    thirdPersonCamera = CameraComponent(world: gameWorld)
      ..viewfinder.zoom = 40
      ..viewfinder.anchor = const Anchor(0.5, 0.85);
    _defaultCameraZoom = thirdPersonCamera.viewfinder.zoom;
    _defaultCameraAnchor = thirdPersonCamera.viewfinder.anchor;
    await add(thirdPersonCamera);
    camera = thirdPersonCamera;

    // 🎯 Meta
    await gameWorld.add(
      GoalComponent(
        position: level.goalPosition,
        size: Vector2.all(0.6),
        paint: Paint()..color = const Color(0xFF81C784),
      ),
    );

    // 🎥 Seguimiento de cámara nativo
    thirdPersonCamera.follow(ball, maxSpeed: 300, snap: true);

    // Suscribirse a eventos de boost (BallComponent ahora tiene los hooks)
    ball.onBoostActivated = handleBoostActivated;
    ball.onBoostDeactivated = handleBoostDeactivated;
  }

  Future<void> resetLevel() async {
    onResetRequested?.call();
  }

  void _animateCameraZoom(double targetZoom, {double duration = 0.5}) =>
      animateCameraZoom(thirdPersonCamera, targetZoom, duration: duration);

  @override
  void update(double dt) {
    super.update(dt);
    final ballPos = ball.body.position;
    _adjustCameraHeightForTerrain(ballPos);
    _adjustCameraForBoosts(ballPos);
    _updateCameraSmooth();
  }
}
