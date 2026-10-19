import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show AdrenalineZone;
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// An adrenaline zone: a sensor over a tense stretch of the course; while
/// the ball is inside, its push is stronger (level-mechanics spec, design D7
/// of flow-and-pacing).
///
/// Drawn as a pulsing red tint along the ground it covers, so the player
/// sees it coming (game-visuals spec).
class AdrenalineZoneComponent extends BodyComponent with ContactCallbacks {
  new({
    required this.zone,
    required this.top,
    required this.bottom,
    required this.grounds,
  }) : super(renderBody: false);

  final AdrenalineZone zone;

  /// The sensor's upper and lower ends, in world y.
  final double top;
  final double bottom;

  /// The stretches of ground the zone covers: from, to and their height.
  final List<(double, double, double)> grounds;

  /// How often the tint pulses, in cycles per second.
  static const pulseRate = 1.2;

  double _time = 0;

  late final Vector2 _center = Vector2(
    (zone.left + zone.right) / 2,
    (top + bottom) / 2,
  );

  @override
  Body createBody() {
    return world.createBody(BodyDef(position: _center))..createShape(
      Polygon.box((zone.right - zone.left) / 2, (bottom - top) / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallComponent) other.enterRush();
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other is BallComponent) other.leaveRush();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  /// The tinted bands, in the body's local coordinates.
  late final List<Rect> _bands = [
    for (final (from, to, height) in grounds)
      Rect.fromLTRB(
        from - _center.x,
        height - 0.4 - _center.y,
        to - _center.x,
        height + 0.06 - _center.y,
      ),
  ];

  late final Rect _worldBounds = Rect.fromLTRB(
    zone.left,
    top,
    zone.right,
    bottom,
  );

  final Paint _tint = Paint();

  @override
  void render(Canvas canvas) {
    if (!game.camera.visibleWorldRect.overlaps(_worldBounds)) return;
    final pulse = 0.5 + 0.5 * math.sin(2 * math.pi * pulseRate * _time);
    for (final band in _bands) {
      _tint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ElementPalette.rush.withValues(alpha: 0),
          ElementPalette.rush.withValues(alpha: 0.3 + 0.25 * pulse),
        ],
      ).createShader(band);
      canvas.drawRect(band, _tint);
    }
  }
}

/// A short red trail behind the ball during an adrenaline rush, in world
/// coordinates (game-visuals spec).
class RushTrailComponent extends Component {
  new({required this.ball});

  final BallComponent ball;

  /// How many points the trail keeps, and how often it takes one, in
  /// seconds.
  static const length = 10;
  static const interval = 0.03;

  final List<Vector2> _points = [];
  double _sinceSample = 0;

  /// The trail's points, oldest first.
  List<Vector2> get points => List.unmodifiable(_points);

  @override
  void update(double dt) {
    super.update(dt);
    _sinceSample += dt;
    if (_sinceSample < interval || !ball.isMounted) return;
    _sinceSample = 0;
    if (ball.isRushing) {
      _points.add(ball.body.position.clone());
      if (_points.length > length) _points.removeAt(0);
    } else if (_points.isNotEmpty) {
      // Fades out once the rush ends.
      _points.removeAt(0);
    }
  }

  final Paint _paint = Paint();

  @override
  void render(Canvas canvas) {
    for (var i = 0; i < _points.length; i++) {
      final share = (i + 1) / (length + 1);
      final point = _points[i];
      canvas.drawCircle(
        Offset(point.x, point.y),
        0.2 * (0.4 + 0.6 * share),
        _paint..color = ElementPalette.rush.withValues(alpha: 0.45 * share),
      );
    }
  }
}

/// The screen's edges glowing red and pulsing like a heartbeat during an
/// adrenaline rush, fading in quickly and out within half a second; drawn
/// under the HUD and never over the course's middle (game-visuals spec).
class AdrenalineGlowComponent extends PositionComponent {
  new({required this.rushing}) : super(priority: -10);

  /// Whether a rush is on.
  final bool Function() rushing;

  /// How fast the glow comes and goes, per second.
  static const fadeIn = 5.0;
  static const fadeOut = 2.0;

  /// How often it beats, in cycles per second.
  static const beatRate = 1.2;

  double _level = 0;
  double _time = 0;

  /// How strongly the glow shows, from 0 to 1.
  double get level => _level;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _level = rushing()
        ? math.min(1, _level + fadeIn * dt)
        : math.max(0, _level - fadeOut * dt);
  }

  final Paint _paint = Paint();

  @override
  void render(Canvas canvas) {
    if (_level <= 0) return;
    // A double beat per cycle, like a heart.
    final phase = (_time * beatRate) % 1;
    final beat = math.max(
      math.exp(-30 * phase * phase),
      0.6 * math.exp(-30 * (phase - 0.28) * (phase - 0.28)),
    );
    final rect = size.toRect();
    _paint.shader = RadialGradient(
      radius: 0.75,
      colors: [
        ElementPalette.rush.withValues(alpha: 0),
        ElementPalette.rush.withValues(alpha: 0),
        ElementPalette.rush.withValues(alpha: _level * (0.35 + 0.25 * beat)),
      ],
      stops: const [0, 0.6, 1],
    ).createShader(rect);
    canvas.drawRect(rect, _paint);
  }
}
