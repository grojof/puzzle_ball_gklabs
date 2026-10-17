import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/parallax.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/jump_button_component.dart';
import 'package:puzzle_ball_gklabs/game/components/level_component.dart';
import 'package:puzzle_ball_gklabs/game/game_config.dart';
import 'package:puzzle_ball_gklabs/game/input/manual_input.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/game/input/tilt_input.dart';
import 'package:puzzle_ball_gklabs/game/utils/camera_utils.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// One play session: a single game that swaps levels in place
/// (game-session spec).
///
/// The game receives settings as a [GameConfig] and sounds go to an
/// [AudioSink]; it reports progress through callbacks and never reads app
/// state (design D2).
class BallOdysseyGame extends Forge2DGame with HasKeyboardHandlerComponents {
  new({
    required this.levelFor,
    required int startLevel,
    required this.totalLevels,
    required this.audio,
    required this._config,
    required Images images,
    required this.levelLabel,
    required this.levelTextStyle,
    this.onLevelCompleted,
    this.onSessionCompleted,
    this.accelerometer,
  }) : _levelNumber = startLevel,
       super(gravity: Vector2(0, 10), metersToPixels: metersToPixelsScale) {
    this.images = images;
    // The game screen pauses on background and shows the pause menu, so the
    // game stays paused on return (game-session spec).
    pauseWhenBackgrounded = false;
  }

  /// Pixels per meter of the physics world; camera zoom is relative to it.
  static const metersToPixelsScale = 40.0;

  static const _joystickRadius = 40.0;
  static const _knobRadius = 12.0;
  static const _jumpButtonSize = 48.0;
  static const _defaultAnchor = Anchor(0.5, 0.85);
  static const _cameraLerp = 0.08;

  /// Builds level number `n` (1-based).
  final LevelData Function(int levelNumber) levelFor;
  final int totalLevels;
  final AudioSink audio;

  /// The "Level n" text shown when a level starts.
  final String Function(int levelNumber) levelLabel;
  final TextStyle levelTextStyle;

  /// A level was completed; [levelNumber] is the one just finished.
  final void Function(int levelNumber)? onLevelCompleted;

  /// The savegame's last level was completed.
  final VoidCallback? onSessionCompleted;

  /// The accelerometer stream; tests pass a fake.
  final Stream<AccelerometerEvent> Function()? accelerometer;

  final MovementIntent intent = MovementIntent();

  GameConfig _config;
  int _levelNumber;
  LevelComponent? _level;
  Component? _input;
  late final JoystickComponent _joystick;
  late final ParallaxComponent _parallax;
  late final ParallaxLayer _layer2;
  late final ParallaxLayer _layer3;
  final Vector2 _parallaxVelocity = Vector2.zero();
  double _targetZoom = 1;
  Anchor _targetAnchor = _defaultAnchor;
  bool _loading = false;

  /// The level being played (1-based).
  int get levelNumber => _levelNumber;

  /// The level currently loaded; null before the first load.
  LevelComponent? get level => _level;

  /// The active input component.
  Component? get input => _input;

  GameConfig get config => _config;

  @override
  Color backgroundColor() => const Color(0xFFEFEFEF);

  @override
  Future<void> onLoad() async {
    // Initializes Forge2D (on the web, loads Box2D) before any body exists.
    await super.onLoad();
    camera.viewfinder.anchor = _defaultAnchor;
    await _addBackdrop();
    await _addHud();
    await _applyInput();
    await _loadLevel(_levelNumber);
  }

  Future<void> _addBackdrop() async {
    Future<ParallaxLayer> layer(String path, Vector2 velocity) =>
        ParallaxLayer.load(
          ParallaxImageData(path),
          velocityMultiplier: velocity,
          images: images,
        );
    final parallax = Assets.images.parallax;
    final layer1 = await layer(parallax.layer1.path, Vector2(0.1, 1));
    _layer2 = await layer(parallax.layer2.path, Vector2(2.5, 1));
    _layer3 = await layer(parallax.layer3.path, Vector2(1, 1));
    _parallax = ParallaxComponent(
      parallax: Parallax([
        layer1,
        _layer2,
        _layer3,
      ], baseVelocity: _parallaxVelocity),
      priority: -10,
    );
    await camera.backdrop.add(_parallax);
  }

  Future<void> _addHud() async {
    _joystick = JoystickComponent(
      anchor: Anchor.bottomLeft,
      knob: CircleComponent(
        radius: _knobRadius,
        paint: Paint()..color = const Color(0xFF2196F3),
      ),
      background: CircleComponent(
        radius: _joystickRadius,
        paint: Paint()..color = const Color(0x552196F3),
      ),
      margin: const EdgeInsets.only(left: 20, bottom: 20),
    );
    await camera.viewport.add(
      JumpButtonComponent(
        size: Vector2.all(_jumpButtonSize),
        onPressed: intent.requestJump,
      ),
    );
  }

  /// Applies new settings during the session, swapping the input component.
  void applyConfig(GameConfig config) {
    if (config == _config) return;
    _config = config;
    if (isLoaded) unawaited(_applyInput());
  }

  Future<void> _applyInput() async {
    final previous = _input;
    if (previous is TiltInput) previous.stop();
    previous?.removeFromParent();
    if (_config.usesTilt) {
      _joystick.removeFromParent();
      _input = TiltInput(intent: intent, events: accelerometer);
    } else {
      if (_joystick.parent == null) await camera.viewport.add(_joystick);
      _input = ManualInput(intent: intent, joystick: _joystick);
    }
    await add(_input!);
  }

  /// Restarts the current level in place.
  Future<void> restartLevel() => _loadLevel(_levelNumber);

  Future<void> _completeLevel() async {
    final finished = _levelNumber;
    onLevelCompleted?.call(finished);
    if (finished < totalLevels) {
      await _loadLevel(finished + 1);
    } else {
      onSessionCompleted?.call();
    }
  }

  Future<void> _loadLevel(int levelNumber) async {
    if (_loading) return;
    _loading = true;
    _level?.removeFromParent();
    intent.reset();
    _levelNumber = levelNumber;
    final level = LevelComponent(
      data: levelFor(levelNumber),
      intent: intent,
      audio: audio,
      onFell: () => unawaited(restartLevel()),
      onCompleted: () => unawaited(_completeLevel()),
    );
    _level = level;
    await world.add(level);
    camera
      ..follow(level.ball, maxSpeed: 400, snap: true)
      ..viewfinder.zoom = 1;
    _targetZoom = 1;
    _loading = false;
    await _showLevelIndicator(levelNumber);
  }

  Future<void> _showLevelIndicator(int levelNumber) async {
    final style = levelTextStyle.copyWith(
      fontSize: 40,
      shadows: const [
        Shadow(blurRadius: 4, offset: Offset(2, 2), color: Color(0x8A000000)),
      ],
    );
    final text = TextComponent(
      text: levelLabel(levelNumber),
      textRenderer: TextPaint(style: style),
      anchor: Anchor.center,
      position: size / 2,
      priority: 1000,
    );
    final fade = _TextFade(
      onOpacity: (o) => text.textRenderer = TextPaint(
        style: style.copyWith(
          color: (style.color ?? const Color(0xFFFFFFFF)).withValues(alpha: o),
        ),
      ),
    );
    await camera.viewport.add(text);
    await text.add(fade);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final level = _level;
    if (level == null || !level.ball.isMounted) return;
    final ball = level.ball.body;

    _parallaxVelocity.x = ball.linearVelocity.x * 4;
    _layer2.update(Vector2(10 * dt, 0), dt);
    _layer3.update(Vector2(20 * dt, 0), dt);

    adjustCameraHeightForTerrain(
      camera,
      level.data.floors,
      ball.position,
      lookAhead: 8,
      lookBehind: 8,
      lookUp: 3,
      lookDown: 3,
      anchorLower: const Anchor(0.5, 0.75),
      anchorHigher: const Anchor(0.5, 0.95),
      setTargetAnchor: (anchor) => _targetAnchor = anchor,
      ballVelocityX: ball.linearVelocity.x,
    );
    adjustCameraForBoostsSmooth(
      camera,
      level.data.boosts,
      ball.position,
      1,
      camera.viewfinder.zoom,
      (zoom) => _targetZoom = zoom,
    );
    _smoothCamera();
  }

  void _smoothCamera() {
    final viewfinder = camera.viewfinder;
    viewfinder.zoom += (_targetZoom - viewfinder.zoom) * _cameraLerp;
    final anchor = viewfinder.anchor;
    viewfinder.anchor = Anchor(
      anchor.x + (_targetAnchor.x - anchor.x) * _cameraLerp,
      anchor.y + (_targetAnchor.y - anchor.y) * _cameraLerp,
    );
  }

  /// Releases everything the session holds. Called when the game screen is
  /// disposed, where the component tree is not torn down (design D1): stops
  /// the sensor and destroys the native physics world.
  void teardown() {
    final input = _input;
    if (input is TiltInput) input.stop();
    _level = null;
    world.physicsWorld.destroy();
  }
}

/// Fades the level label in, holds it and fades it out, then removes it.
class _TextFade extends Component {
  new({required this.onOpacity});

  static const _fadeIn = 0.3;
  static const _holdUntil = 1.8;
  static const _duration = 2.3;

  final void Function(double opacity) onOpacity;
  double _elapsed = 0;

  @override
  void update(double dt) {
    _elapsed += dt;
    if (_elapsed >= _duration) {
      parent?.removeFromParent();
      return;
    }
    final opacity = _elapsed < _fadeIn
        ? _elapsed / _fadeIn
        : _elapsed < _holdUntil
        ? 1.0
        : 1 - (_elapsed - _holdUntil) / (_duration - _holdUntil);
    onOpacity(opacity.clamp(0, 1));
  }
}
