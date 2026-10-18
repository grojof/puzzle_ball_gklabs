import 'dart:async';

import 'package:flame/cache.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/parallax.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/camera/camera_controller.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/components/level_component.dart';
import 'package:puzzle_ball_gklabs/game/game_config.dart';
import 'package:puzzle_ball_gklabs/game/input/manual_input.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/game/input/tilt_input.dart';
import 'package:puzzle_ball_gklabs/game/visuals/biome_backdrop.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_paint.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_textures.dart';
import 'package:puzzle_ball_gklabs/game/visuals/world_look.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';
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
    required this.haptics,
    required this._config,
    required Images images,
    required this.levelLabel,
    required this.levelTextStyle,
    required this.hudLabel,
    this.worldLabel,
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

  /// The joystick's radius before it is scaled to the screen (design D7).
  static const _joystickRadius = 50.0;

  /// Builds level number `n` (1-based).
  final LevelData Function(int levelNumber) levelFor;
  final int totalLevels;
  final AudioSink audio;

  /// Where vibration events go (player-controls spec).
  final HapticsSink haptics;

  /// The "Level n" text shown when a level starts.
  final String Function(int levelNumber) levelLabel;
  final TextStyle levelTextStyle;

  /// The text of a pickup message, in the player's language (game-hud spec).
  final String Function(HudMessage message) hudLabel;

  /// The line shown under the level label when a level starts a world, or
  /// null for other levels (game-visuals spec).
  final String? Function(int levelNumber)? worldLabel;

  /// A level was completed; [levelNumber] is the one just finished.
  final void Function(int levelNumber)? onLevelCompleted;

  /// The savegame's last level was completed.
  final VoidCallback? onSessionCompleted;

  /// The accelerometer stream; tests pass a fake.
  final Stream<AccelerometerEvent> Function()? accelerometer;

  final MovementIntent intent = MovementIntent();

  /// The system's safe area (status bar, camera cutout), which the HUD keeps
  /// inside; `GamePage` sets it from the view padding (game-hud spec).
  final ValueNotifier<EdgeInsets> safeArea = ValueNotifier(EdgeInsets.zero);

  GameConfig _config;
  int _levelNumber;
  LevelComponent? _level;
  Component? _input;
  final JoystickComponent _joystick = JoystickComponent(
    anchor: Anchor.bottomLeft,
    knob: JoystickKnob(radius: _joystickRadius * 0.4),
    background: JoystickBase(radius: _joystickRadius),
    margin: const EdgeInsets.only(left: 16, bottom: 16),
  );
  final Vector2 _parallaxVelocity = Vector2.zero();

  /// The painted forest's moving layers, while the forest is shown.
  List<ParallaxLayer> _forestLayers = const [];
  Component? _backdrop;
  WorldLook? _backdropLook;

  /// The backdrop of the current world.
  Component? get backdrop => _backdrop;
  final CameraController _camera = CameraController(
    metersToPixels: metersToPixelsScale,
  );
  final TerrainTextureCache _textures = TerrainTextureCache();
  WorldLook? _look;
  bool _loading = false;

  /// How the current world looks.
  WorldLook? get look => _look;

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
    camera.viewfinder.anchor = Anchor.center;
    _camera.viewport = size;
    await _addHud();
    await _applyInput();
    await _loadLevel(_levelNumber);
  }

  /// Shows the backdrop of [look], replacing the previous world's (design
  /// D4, D7).
  Future<void> _showBackdrop(WorldLook look) async {
    if (_backdropLook?.biome == look.biome &&
        _backdropLook?.variant == look.variant) {
      return;
    }
    _backdrop?.removeFromParent();
    _forestLayers = const [];
    final particles = ParticleField(
      style: ParticleField.styleOf(look.biome),
      color: look.palette.particle,
      seed: look.variant ^ look.biome.index,
      count: look.biome == Biome.nightForest ? 12 : ParticleField.calmCount,
    );
    final backdrop = Component(
      priority: -10,
      children: [
        if (look.biome == Biome.nightForest) ...[
          await _paintedForest(),
          if (look.variant != 0) ScreenTint(look.palette.skyBottom),
        ] else
          BiomeBackdrop(
            look: look,
            cameraX: () => camera.viewfinder.position.x,
          ),
        particles,
      ],
    );
    _backdrop = backdrop;
    _backdropLook = look;
    await camera.backdrop.add(backdrop);
  }

  Future<ParallaxComponent> _paintedForest() async {
    Future<ParallaxLayer> layer(String path, Vector2 velocity) =>
        ParallaxLayer.load(
          ParallaxImageData(path),
          velocityMultiplier: velocity,
          images: images,
        );
    final parallax = Assets.images.parallax;
    final layers = [
      await layer(parallax.layer1.path, Vector2(0.1, 1)),
      await layer(parallax.layer2.path, Vector2(2.5, 1)),
      await layer(parallax.layer3.path, Vector2(1, 1)),
    ];
    _forestLayers = layers;
    return ParallaxComponent(
      parallax: Parallax(layers, baseVelocity: _parallaxVelocity),
    );
  }

  Future<void> _addHud() async {
    await camera.viewport.addAll([
      JumpButtonComponent(
        onPressed: intent.requestJump,
        isCharged: () => _level?.hasAirJump ?? false,
      ),
      CheckpointTrackComponent(
        reached: () => _level?.checkpointsReached ?? const [],
        safeArea: safeArea,
      ),
      BoostTrayComponent(
        activeBoost: () => _activeBall?.activeBoost,
        boostLeft: () => _activeBall?.boostLeft ?? 0,
        charged: () => _level?.hasAirJump ?? false,
        safeArea: safeArea,
      ),
    ]);
  }

  /// The ball of the loaded level, if any.
  BallComponent? get _activeBall {
    final level = _level;
    return level != null && level.isLoaded ? level.ball : null;
  }

  PickupMessageComponent? _message;

  /// The pickup message showing, if any.
  PickupMessageComponent? get pickupMessage =>
      _message?.isMounted ?? false ? _message : null;

  /// Shows [message] above the ball, replacing the one showing (design D4 of
  /// add-hud-indicators).
  Future<void> _showPickup(HudMessage message) async {
    final ball = _activeBall;
    if (ball == null) return;
    _message?.removeFromParent();
    final component = PickupMessageComponent(
      message: message,
      text: hudLabel(message),
      style: levelTextStyle.copyWith(
        fontSize: HudLayout.messageFontSize(size),
        fontWeight: FontWeight.w700,
        color: const Color(0xFFFFFFFF),
      ),
      above: () =>
          camera.localToGlobal(ball.body.position) -
          Vector2(0, LevelComponent.ballRadius * metersToPixelsScale + 12),
    );
    _message = component;
    await camera.viewport.add(component);
  }

  /// The on-screen joystick, in joystick mode.
  JoystickComponent get joystick => _joystick;

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
    final data = levelFor(levelNumber);
    // Textures are ready before the level exists, never made during play.
    final look = WorldLook.forLevel(data.seed, data.level);
    final textures = await _textures.get(look);
    await _showBackdrop(look);
    _look = look;
    final level = LevelComponent(
      data: data,
      intent: intent,
      audio: audio,
      haptics: haptics,
      terrain: TerrainPaint(textures),
      onFell: () => unawaited(restartLevel()),
      onCompleted: () => unawaited(_completeLevel()),
      onRespawned: _frameBall,
      onPickup: (message) => unawaited(_showPickup(message)),
    );
    _level = level;
    await world.add(level);
    final start = level.data.ballStart;
    _camera
      ..setLevel(level.data)
      ..reset(Vector2(start.x, start.y));
    _applyCamera();
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
    await _showFadingText(levelLabel(levelNumber), style, size / 2);
    final world = worldLabel?.call(levelNumber);
    if (world != null) {
      await _showFadingText(
        world,
        style.copyWith(fontSize: 22),
        size / 2 + Vector2(0, 40),
      );
    }
  }

  /// Fades [text] in at [position] on the viewport, holds it, and fades it
  /// out.
  Future<void> _showFadingText(
    String text,
    TextStyle style,
    Vector2 position,
  ) async {
    final component = TextComponent(
      text: text,
      textRenderer: TextPaint(style: style),
      anchor: Anchor.center,
      position: position,
      priority: 1000,
    );
    final fade = _TextFade(
      onOpacity: (o) => component.textRenderer = TextPaint(
        style: style.copyWith(
          color: (style.color ?? const Color(0xFFFFFFFF)).withValues(alpha: o),
        ),
      ),
    );
    await camera.viewport.add(component);
    await component.add(fade);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final level = _level;
    if (level == null || !level.ball.isMounted) return;
    final ball = level.ball.body;

    _parallaxVelocity.x = ball.linearVelocity.x * 4;
    if (_forestLayers.length == 3) {
      _forestLayers[1].update(Vector2(10 * dt, 0), dt);
      _forestLayers[2].update(Vector2(20 * dt, 0), dt);
    }

    _camera.update(dt, ball.position, ball.linearVelocity);
    _applyCamera();
  }

  @override
  void onGameResize(Vector2 size) {
    // The joystick mirrors the jump button; its margin is set before the
    // HUD repositions on resize.
    final margin = HudLayout.margin(size);
    _joystick
      ..scale = Vector2.all(HudLayout.controlSize(size) / (2 * _joystickRadius))
      ..margin = EdgeInsets.only(left: margin, bottom: margin);
    super.onGameResize(size);
    _camera.viewport = size;
  }

  /// Frames the ball at once after a respawn.
  void _frameBall() {
    _camera.reset(_level!.ball.body.position);
    _applyCamera();
  }

  void _applyCamera() {
    camera.viewfinder
      ..position = _camera.centre
      ..zoom = _camera.zoom;
  }

  /// Releases everything the session holds. Called when the game screen is
  /// disposed, where the component tree is not torn down (design D1): stops
  /// the sensor and destroys the native physics world.
  void teardown() {
    final input = _input;
    if (input is TiltInput) input.stop();
    _level = null;
    _textures.clear();
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
