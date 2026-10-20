import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart'
    show Pendulum, maceClearance, maceLane, maceRadius;
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A pendulum: an iron mace on a rigid arm, swinging on its rhythm from the
/// game's clock, which a respawn does not reset (level-mechanics spec,
/// design D3 of add-dynamic-elements).
///
/// A kinematic body: each step it takes its scheduled angle and angular
/// speed, and a mace that meets the ball throws it away at [knockSpeed].
///
/// Drawn as a riveted bracket, a dark arm and a studded mace, its swing
/// traced faintly (game-visuals spec).
class PendulumComponent extends BodyComponent with ContactCallbacks {
  new({required this.pendulum}) : super(renderBody: false);

  final Pendulum pendulum;

  /// The arm's thickness, in meters.
  static const armWidth = 0.1;

  /// The speed a mace knocks the ball away at, in m/s: harder than its own
  /// swing, so a hit throws the ball (design D3 of add-dynamic-elements).
  static const knockSpeed = 10.0;

  /// The angle at which the mace leaves the lane, from straight down.
  late final double laneAngle = math.acos(
    (pendulum.length - (maceLane - maceClearance)) / pendulum.length,
  );

  /// The swing's amplitude: in each half swing the mace stays above the
  /// lane for the pendulum's clear share of the period.
  late final double amplitude = laneAngle / math.cos(math.pi * pendulum.clear);

  double _time = 0;
  Picture? _art;
  Picture? _arc;

  /// The game time the pendulum's rhythm reads, in seconds.
  double get time => _time;

  /// The scheduled angle at [time], from straight down.
  double angleAt(double time) =>
      amplitude *
      math.sin(2 * math.pi * (time + pendulum.phase) / pendulum.period);

  /// Whether the mace is in the lane at [time].
  bool inLaneAt(double time) => angleAt(time).abs() < laneAngle;

  /// Whether the lane stays clear from now for [seconds].
  bool clearFor(double seconds) {
    for (var t = 0.0; t <= seconds; t += 0.02) {
      if (inLaneAt(_time + t)) return false;
    }
    return true;
  }

  double _angularSpeedAt(double time) =>
      amplitude *
      2 *
      math.pi /
      pendulum.period *
      math.cos(2 * math.pi * (time + pendulum.phase) / pendulum.period);

  @override
  Body createBody() {
    final length = pendulum.length;
    return world.createBody(
        BodyDef(
          type: BodyType.kinematic,
          position: Vector2(pendulum.pivot.x, pendulum.pivot.y),
          rotation: Rot.fromAngle(angleAt(0)),
        ),
      )
      ..createShape(
        Polygon.offsetBox(
          armWidth / 2,
          length / 2,
          center: Vector2(0, length / 2),
        ),
        ShapeDef(enableContactEvents: true, userData: this),
      )
      ..createShape(
        Circle(radius: maceRadius, center: Vector2(0, length)),
        ShapeDef(enableContactEvents: true, userData: this),
      );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is! BallComponent) return;
    final mace = body.worldPoint(Vector2(0, pendulum.length));
    final away = other.body.position - mace;
    if (away.length2 == 0) return;
    other.knock(away.normalized(), knockSpeed);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    body
      ..setTransform(body.position, Rot.fromAngle(angleAt(_time)))
      ..angularVelocity = _angularSpeedAt(_time);
  }

  Picture _recordArt() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final length = pendulum.length;
    // The arm.
    final arm = RRect.fromRectAndRadius(
      Rect.fromLTWH(-armWidth / 2, 0, armWidth, length),
      const Radius.circular(0.04),
    );
    canvas.drawRRect(
      arm,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF1C1F24), Color(0xFF5E6E7C), Color(0xFF1C1F24)],
        ).createShader(arm.outerRect),
    );
    // Studs around the mace, then the iron ball and its hazard ring.
    final center = Offset(0, length);
    final stud = Paint()..color = const Color(0xFF2A2E33);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final tip = center + Offset(math.cos(angle), math.sin(angle)) * 0.56;
      final side = Offset(-math.sin(angle), math.cos(angle)) * 0.08;
      final base = center + Offset(math.cos(angle), math.sin(angle)) * 0.4;
      canvas.drawPath(
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(base.dx + side.dx, base.dy + side.dy)
          ..lineTo(base.dx - side.dx, base.dy - side.dy)
          ..close(),
        stud,
      );
    }
    canvas
      ..save()
      ..translate(center.dx, center.dy);
    ElementPainter.orb(canvas, maceRadius, ElementPalette.iron);
    canvas
      ..drawCircle(
        Offset.zero,
        maceRadius * 0.62,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.06
          ..color = ElementPalette.hazard,
      )
      ..restore();
    // The bracket at the pivot.
    final bracket = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 0.6, height: 0.3),
      const Radius.circular(0.06),
    );
    canvas.drawRRect(bracket, Paint()..color = const Color(0xFF39444E));
    final rivet = Paint()..color = const Color(0xFFB9C6D2);
    canvas
      ..drawCircle(const Offset(-0.2, 0), 0.04, rivet)
      ..drawCircle(const Offset(0.2, 0), 0.04, rivet)
      ..drawCircle(Offset.zero, 0.07, Paint()..color = ElementPalette.hazard);
    ElementPainter.outline(canvas, Path()..addRRect(bracket), 0.03);
    return recorder.endRecording();
  }

  /// The mace's path, traced faintly, so the stretch it sweeps reads as
  /// danger.
  Picture _recordArc() {
    final recorder = PictureRecorder();
    final reach = pendulum.length + maceRadius;
    final rect = Rect.fromCircle(center: Offset.zero, radius: reach);
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05
      ..color = ElementPalette.hazard.withValues(alpha: 0.3);
    final canvas = Canvas(recorder);
    // Straight down is π/2 on the canvas, which grows clockwise.
    const steps = 14;
    final sweep = 2 * amplitude / steps;
    for (var i = 0; i < steps; i += 2) {
      canvas.drawArc(
        rect,
        math.pi / 2 - amplitude + i * sweep,
        sweep,
        false,
        dash,
      );
    }
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    // The arc stays still while the body turns.
    canvas
      ..save()
      ..rotate(-body.angle)
      ..drawPicture(_arc ??= _recordArc())
      ..restore()
      ..drawPicture(_art ??= _recordArt());
  }

  @override
  void onRemove() {
    _art?.dispose();
    _art = null;
    _arc?.dispose();
    _arc = null;
    super.onRemove();
  }
}
