import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/components.dart';
import 'package:puzzle_ball_gklabs/game/input/movement_intent.dart';
import 'package:puzzle_ball_gklabs/game/visuals/terrain_paint.dart';
import 'package:puzzle_ball_gklabs/gen/assets.gen.dart';
import 'package:puzzle_ball_gklabs/haptics/haptics.dart';

/// Everything one level is made of, under a single root, so unloading the
/// level is removing this component (design D1).
///
/// It detects a fall once no ground is left that the ball could still land
/// on, sends the ball back after a fall, spikes or a laser, restoring the
/// course, and plays the goal sequence.
class LevelComponent extends Component with HasGameReference<Forge2DGame> {
  new({
    required this.data,
    required this.intent,
    required this.audio,
    required this.haptics,
    required this.terrain,
    required this.onFell,
    required this.onCompleted,
    this.onRespawned,
    this.onPickup,
  }) : fallLine = data.lowestPoint + fallMargin,
       _ground = _groundColumns(data);

  /// How far below the lowest terrain the ball counts as fallen, in meters:
  /// a backstop to [canStillLand].
  static const fallMargin = 10.0;

  /// The width of a ground column, in meters.
  static const columnWidth = 2.0;

  /// How far sideways a falling ball can travel per meter it falls, and
  /// how much farther a boost can carry it, in meters (design D7 of
  /// raise-difficulty-and-pace).
  static const reachPerMeter = 1.3;
  static const reachExtra = 20.0;

  /// How high an orb's air jump can still lift the ball, in meters: with a
  /// charge held, ground up to this much above it is still within reach.
  static const airJumpRise = 3.0;

  /// The ball's radius, as the generator sizes the course for.
  static const ballRadius = 0.2;

  final LevelData data;
  final MovementIntent intent;
  final AudioSink audio;
  final HapticsSink haptics;

  /// The world's terrain paints.
  final TerrainPaint terrain;

  /// The ball fell below [fallLine] with no active checkpoint.
  final VoidCallback onFell;

  /// The goal sequence finished.
  final VoidCallback onCompleted;

  /// The ball respawned at a checkpoint.
  final VoidCallback? onRespawned;

  /// The ball collected an orb or reached a checkpoint (game-hud spec).
  final void Function(HudMessage message)? onPickup;

  /// World y (downwards) past which the ball has fallen out of the level.
  final double fallLine;

  /// The lowest ground (largest world y) of each [columnWidth] column from
  /// x 0, or null where there is none: the last ground a falling ball could
  /// land on there.
  final List<double?> _ground;

  static List<double?> _groundColumns(LevelData data) {
    var end = 0.0;
    for (final floor in data.floors) {
      end = math.max(end, floor.right);
    }
    final columns = List<double?>.filled((end / columnWidth).ceil() + 1, null);
    void see(double left, double right, double top) {
      final first = math.max(0, (left / columnWidth).floor());
      final last = math.min(columns.length - 1, (right / columnWidth).floor());
      for (var i = first; i <= last; i++) {
        final current = columns[i];
        columns[i] = current == null ? top : math.max(current, top);
      }
    }

    for (final floor in data.floors) {
      see(floor.left, floor.right, floor.top);
    }
    for (final ramp in data.ramps) {
      see(ramp.left, ramp.right, ramp.bottom);
    }
    for (final curve in data.curves) {
      see(curve.left, curve.right, curve.bottom);
    }
    // A ball floating in a fan's column has the fan below it.
    for (final fan in data.fans) {
      see(fan.left, fan.right, fan.base);
    }
    for (final platform in data.platforms) {
      see(
        math.min(platform.start.x, platform.end.x),
        math.max(platform.start.x, platform.end.x) + platform.size.x,
        math.max(platform.start.y, platform.end.y),
      );
    }
    return columns;
  }

  /// Whether some ground lies below the ball that it can still reach,
  /// given how fast it can fall and travel sideways, and how high an orb's
  /// charge can still lift it (game-session spec).
  bool get canStillLand {
    final position = ball.body.position;
    final rise = ball.hasAirJump ? airJumpRise : 0.0;
    // Only columns the ball could reach from as high above the level's
    // lowest ground as it is.
    final widest = reachPerMeter * (fallLine - position.y + rise) + reachExtra;
    final first = math.max(0, ((position.x - widest) / columnWidth).floor());
    final last = math.min(
      _ground.length - 1,
      ((position.x + widest) / columnWidth).ceil(),
    );
    for (var i = first; i <= last; i++) {
      final top = _ground[i];
      final below = top == null ? 0.0 : top - position.y + rise;
      if (below <= 0) continue;
      final left = i * columnWidth;
      final away = position.x < left
          ? left - position.x
          : math.max(0, position.x - (left + columnWidth));
      if (away <= reachPerMeter * below + reachExtra) return true;
    }
    return false;
  }

  late final BallComponent ball;
  late final List<CheckPointComponent> _checkpoints;
  final List<Component> _overlays = [];
  CheckPointComponent? _activeCheckpoint;
  bool _fell = false;
  bool _sendBack = false;

  /// Whether each checkpoint, in course order, has been reached.
  List<bool> get checkpointsReached => isLoaded
      ? [for (final checkpoint in _checkpoints) checkpoint.isActivated]
      : const [];

  /// Whether the ball holds a double-jump charge.
  bool get hasAirJump => isLoaded && ball.hasAirJump;

  /// The last checkpoint the ball passed, if any.
  CheckPointComponent? get activeCheckpoint => _activeCheckpoint;

  static Vector2 _vector(Vec2 v) => Vector2(v.x, v.y);

  @override
  Future<void> onLoad() async {
    final images = game.images;
    final components = Assets.images.components;

    ball = BallComponent(
      intent: intent,
      audio: audio,
      haptics: haptics,
      initialPosition: _vector(data.ballStart),
      radius: ballRadius,
      onGoalReached: _onGoalReached,
      textureImage: images.fromCache(components.ball.path),
    );

    _checkpoints = [
      for (final checkpoint in data.checkpoints)
        CheckPointComponent(
          ground: _vector(checkpoint.position),
          onActivated: (component) {
            _activeCheckpoint = component;
            haptics.play(Haptic.checkpoint);
            onPickup?.call(HudMessage.checkpoint);
          },
        ),
    ];
    await addAll([
      for (final run in data.floors)
        if (run.crumbling)
          CrumblingPlatformComponent(
            position: _vector(run.position),
            size: _vector(run.size),
            terrain: terrain,
          )
        else
          FloorComponent(
            position: _vector(run.position),
            size: _vector(run.size),
            terrain: terrain,
            surface: run.surface,
          ),
      for (final curve in data.curves)
        CurvedTerrainComponent(
          curve: curve,
          bottom: curve.bottom + tileSize,
          terrain: terrain,
        ),
      for (final trampoline in data.trampolines)
        TrampolineComponent(
          left: trampoline.left,
          ground: trampoline.top,
          width: trampoline.width,
        ),
      for (final loop in data.loops) LoopComponent(loop: loop, ball: ball),
      for (final fan in data.fans)
        FanComponent(fan: fan, inFloor: _inFloor(fan)),
      for (final seesaw in data.seesaws) SeesawComponent(seesaw: seesaw),
      for (final pendulum in data.pendulums)
        PendulumComponent(pendulum: pendulum),
      for (final bumper in data.bumpers) BumperComponent(bumper: bumper),
      ...RoofBeamComponent.over(data.bumpers),
      for (final zone in data.adrenaline) _zone(zone),
      RushTrailComponent(ball: ball),
      for (final platform in data.platforms)
        MovingPlatformComponent(
          start: _vector(platform.start),
          end: _vector(platform.end),
          size: _vector(platform.size),
          speed: platform.speed,
          pause: platform.pause,
        ),
      for (final laser in data.lasers)
        LaserBarrierComponent(
          barrier: laser,
          onTouched: () => _sendBack = true,
        ),
      for (final strip in data.hazards)
        SpikeComponent(
          left: strip.left,
          ground: strip.top,
          width: strip.width,
          onTouched: () => _sendBack = true,
        ),
      for (final ramp in data.ramps)
        RampComponent(
          position: _vector(ramp.position),
          size: _vector(ramp.size),
          // A ramp component "inverted" is high on its left.
          inverted: !ramp.ascending,
          terrain: terrain,
        ),
      ..._checkpoints,
      for (final boost in data.boosts)
        BoostComponent(
          type: boost.type,
          position: _vector(boost.position),
          onCollected: () => onPickup?.call(HudMessage.doubleJump),
        ),
      GoalComponent(position: _vector(data.goal), size: Vector2(1, 3.5)),
      ball,
    ]);
  }

  /// Whether [fan] is set in a floor run rather than standing in a pit.
  bool _inFloor(Fan fan) => data.floors.any(
    (floor) =>
        floor.top == fan.base &&
        floor.left <= fan.left &&
        floor.right >= fan.right,
  );

  /// An adrenaline zone's sensor, reaching well above and a little below
  /// the ground it covers, and the stretches of that ground to tint.
  AdrenalineZoneComponent _zone(AdrenalineZone zone) {
    final grounds = [
      for (final floor in data.floors)
        if (floor.right > zone.left && floor.left < zone.right)
          (
            math.max(floor.left, zone.left),
            math.min(floor.right, zone.right),
            floor.top,
          ),
    ];
    final tops = grounds.map((ground) => ground.$3);
    final highest = tops.isEmpty ? 0.0 : tops.reduce(math.min);
    final lowest = tops.isEmpty ? 0.0 : tops.reduce(math.max);
    return AdrenalineZoneComponent(
      zone: zone,
      top: highest - 12,
      bottom: lowest + 3,
      grounds: grounds,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_fell || !ball.isMounted) return;
    final fell =
        ball.body.position.y > fallLine || (!ball.isOnGround && !canStillLand);
    if (_sendBack || fell) sendBack();
  }

  /// Sends the ball back after a fall or spikes: it respawns at the last
  /// active checkpoint with the course restored, or the level restarts
  /// when none is active (level-mechanics spec).
  void sendBack() {
    _sendBack = false;
    final checkpoint = _activeCheckpoint;
    if (checkpoint != null) {
      ball.respawn(checkpoint.respawnPoint);
      intent.reset();
      for (final child in children) {
        if (child is CrumblingPlatformComponent) child.restore();
        if (child is BoostComponent) child.restore();
        if (child is LoopComponent) child.restore();
        if (child is SeesawComponent) child.restore();
      }
      onRespawned?.call();
      return;
    }
    _fell = true;
    onFell();
  }

  void _onGoalReached() {
    // Contacts are reported after the physics step, so the body can change.
    ball.freeze();
    unawaited(_playGoalSequence());
  }

  /// Flashes blue, fades to black and then reports the level as completed.
  Future<void> _playGoalSequence() async {
    final viewport = game.camera.viewport;
    final flash = SequenceEffect([
      OpacityEffect.to(
        0.6,
        EffectController(duration: 0.4, curve: Curves.easeOut),
      ),
      OpacityEffect.to(
        0,
        EffectController(duration: 0.4, curve: Curves.easeIn),
      ),
    ]);
    final flashOverlay = _overlay(const Color(0xFF42A5F5), flash);
    await viewport.add(flashOverlay);
    await flash.completed;
    flashOverlay.removeFromParent();

    final fade = OpacityEffect.to(
      1,
      EffectController(duration: 0.4, curve: Curves.easeIn),
    );
    await viewport.add(_overlay(const Color(0xFF000000), fade));
    await fade.completed;
    if (isMounted) onCompleted();
  }

  RectangleComponent _overlay(Color color, Effect effect) {
    final overlay = RectangleComponent(
      size: game.size,
      paint: Paint()..color = color.withValues(alpha: 0),
      children: [effect],
      priority: 1000,
    );
    _overlays.add(overlay);
    return overlay;
  }

  @override
  void onRemove() {
    // Overlays live in the viewport, outside this subtree.
    for (final overlay in _overlays) {
      overlay.removeFromParent();
    }
    _overlays.clear();
    super.onRemove();
  }
}
