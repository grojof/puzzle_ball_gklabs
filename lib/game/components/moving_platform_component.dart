import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/components/ground_surface.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';

/// A platform that shuttles between two positions, pausing at each end: a
/// kinematic body that carries the ball resting on it (level-mechanics
/// spec), drawn as a riveted steel deck (game-visuals spec).
///
/// When it starts or stops, it changes the velocity of the ball on its deck
/// by as much as its own, as if carrying it rigidly: friction alone would
/// spin the ball instead, and the deck would slide out from under it. At a
/// steady speed the ball rolls on the deck as on the ground.
class MovingPlatformComponent extends BodyComponent
    with ContactCallbacks
    implements GroundSurface {
  new({
    required this.start,
    required this.end,
    required this.size,
    required this.speed,
    required this.pause,
  }) : super(renderBody: false);

  /// Top-left corner at each end of the path, in meters.
  final Vector2 start;
  final Vector2 end;

  /// Width and height, in meters.
  final Vector2 size;

  /// Speed along the path, in m/s.
  final double speed;

  /// The pause at each end, in seconds.
  final double pause;

  /// The deck's friction, as the ground's.
  static const friction = 0.8;

  bool _towardsEnd = true;
  double _paused = 0;
  Picture? _art;

  /// The balls touching the deck.
  final Set<BallComponent> _touching = {};

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallComponent) _touching.add(other);
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other is BallComponent) _touching.remove(other);
  }

  /// The top-left corner now, in meters.
  Vector2 get topLeft => body.position - size / 2;

  /// Whether the platform is pausing at one of its ends.
  bool get isPausing => _paused > 0;

  /// How much longer the current pause lasts, in seconds.
  double get pauseLeft => _paused > 0 ? _paused : 0;

  @override
  bool supports(Vector2 center) {
    final left = topLeft;
    return center.x >= left.x - GroundSurface.edgeTolerance &&
        center.x <= left.x + size.x + GroundSurface.edgeTolerance &&
        center.y < left.y;
  }

  @override
  Body createBody() {
    return world.createBody(
      BodyDef(type: BodyType.kinematic, position: start + size / 2),
    )..createShape(
      Polygon.box(size.x / 2, size.y / 2),
      ShapeDef(
        material: SurfaceMaterial(friction: friction),
        enableContactEvents: true,
        userData: this,
      ),
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    _move(_velocity(dt));
  }

  /// The velocity for the next step.
  Vector2 _velocity(double dt) {
    if (_paused > 0) {
      _paused -= dt;
      return Vector2.zero();
    }
    final target = (_towardsEnd ? end : start) + size / 2;
    final offset = target - body.position;
    final distance = offset.length;
    if (distance <= speed * dt) {
      // Arrives during this step: lands exactly on the end, then pauses.
      _towardsEnd = !_towardsEnd;
      _paused = pause;
      return offset / dt;
    }
    return offset / distance * speed;
  }

  /// Moves at [velocity], carrying the ball on the deck through the change.
  void _move(Vector2 velocity) {
    final change = velocity - body.linearVelocity;
    if (change.length2 > 0) {
      for (final ball in _touching) {
        if (supports(ball.body.position)) {
          ball.body.linearVelocity = ball.body.linearVelocity + change;
        }
      }
    }
    body.linearVelocity = velocity;
  }

  Picture _record() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final deck = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
      const Radius.circular(0.08),
    );
    canvas
      // Shadow below.
      ..drawRRect(
        deck.shift(const Offset(0.06, 0.12)),
        Paint()..color = const Color(0x55000000),
      )
      // Steel, lit from the top.
      ..drawRRect(
        deck,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB9C6D2), Color(0xFF5E6E7C), Color(0xFF39444E)],
          ).createShader(deck.outerRect),
      )
      // Yellow and black stripes along the bottom: a machine.
      ..save()
      ..clipRRect(deck);
    final band = Rect.fromLTRB(
      deck.left,
      deck.bottom - size.y * 0.3,
      deck.right,
      deck.bottom,
    );
    canvas.drawRect(band, Paint()..color = const Color(0xFF1C1F24));
    final stripe = Paint()..color = const Color(0xFFFFC531);
    for (var x = deck.left - size.y; x < deck.right; x += 0.3) {
      canvas.drawPath(
        Path()
          ..moveTo(x, band.bottom)
          ..lineTo(x + 0.15, band.bottom)
          ..lineTo(x + 0.15 + band.height, band.top)
          ..lineTo(x + band.height, band.top)
          ..close(),
        stripe,
      );
    }
    canvas.restore();
    // Rivets along the deck.
    final rivet = Paint()..color = const Color(0xFF2A3138);
    final shine = Paint()..color = const Color(0xCCFFFFFF);
    for (var x = deck.left + 0.25; x < deck.right - 0.1; x += 0.5) {
      final c = Offset(x, deck.top + size.y * 0.3);
      canvas
        ..drawCircle(c, 0.045, rivet)
        ..drawCircle(c.translate(-0.012, -0.012), 0.015, shine);
    }
    ElementPainter.outline(canvas, Path()..addRRect(deck), 0.045);
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawPicture(_art ??= _record());
  }

  @override
  void onRemove() {
    _art?.dispose();
    _art = null;
    super.onRemove();
  }
}
