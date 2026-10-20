import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show Fan, fanLift;
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A fan blowing a column of air upwards, always on (level-mechanics spec,
/// design D1 of add-dynamic-elements).
///
/// Inside the column the ball is lifted by [fanLift] times gravity at the
/// base, fading to nothing at the top, so it floats halfway up; an extra
/// vertical damping settles its bobbing. The push works as in the air.
///
/// Drawn as a steel housing with spinning blades, on a pillar into the pit
/// or set in the floor, and pale currents rising through the column
/// (game-visuals spec).
class FanComponent extends BodyComponent with ContactCallbacks {
  new({required this.fan, required this.inFloor}) : super(renderBody: false);

  final Fan fan;

  /// Whether the fan is set in a floor run rather than standing in a pit.
  final bool inFloor;

  /// How strongly the column damps the ball's vertical speed, per second.
  static const damping = 1.0;

  /// The least time between two whooshes, in seconds.
  static const whooshGap = 1.0;

  /// How many currents rise per meter of the column's width.
  static const currentsPerMeter = 1.6;

  /// How fast the currents rise, in m/s.
  static const currentSpeed = 3.0;

  BallComponent? _ball;
  double _time = 0;
  double _sinceWhoosh = double.infinity;
  Picture? _housing;

  /// Whether the ball is in the column.
  bool get holdsBall => _ball != null;

  double get _width => fan.right - fan.left;

  late final Rect _worldBounds = Rect.fromLTRB(
    fan.left - 1,
    fan.top - 1,
    fan.right + 1,
    fan.base + (inFloor ? 1 : 30),
  );

  @override
  Body createBody() {
    return world.createBody(
      BodyDef(
        position: Vector2((fan.left + fan.right) / 2, (fan.top + fan.base) / 2),
      ),
    )..createShape(
      Polygon.box(_width / 2, fan.height / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is! BallComponent) return;
    _ball = other;
    if (_sinceWhoosh >= whooshGap) other.audio.play(GameSound.whoosh);
    _sinceWhoosh = 0;
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other == _ball) _ball = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _sinceWhoosh += dt;
    final ball = _ball;
    if (ball == null || !ball.isMounted) return;
    final body = ball.body;
    final above = (fan.base - body.position.y).clamp(0.0, fan.height);
    final lift = world.gravity.y * fanLift * (1 - above / fan.height);
    body.applyForce(
      Vector2(0, -body.mass * (lift + damping * body.linearVelocity.y)),
    );
  }

  Picture _recordHousing() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final width = _width;
    if (!inFloor) {
      // A pillar down into the pit.
      const pillar = Rect.fromLTWH(-0.3, 0.25, 0.6, 30);
      canvas.drawRect(
        pillar,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF2A3138), Color(0xFF5E6E7C), Color(0xFF2A3138)],
          ).createShader(pillar),
      );
    }
    final housing = RRect.fromRectAndRadius(
      Rect.fromLTWH(-width / 2, -0.15, width, 0.4),
      const Radius.circular(0.1),
    );
    canvas
      ..drawRRect(
        housing,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB9C6D2), Color(0xFF5E6E7C), Color(0xFF39444E)],
          ).createShader(housing.outerRect),
      )
      // The grille's slots.
      ..save()
      ..clipRRect(housing);
    final slot = Paint()..color = const Color(0xFF1C1F24);
    for (var x = -width / 2 + 0.2; x < width / 2 - 0.1; x += 0.25) {
      canvas.drawRect(Rect.fromLTWH(x, -0.08, 0.1, 0.12), slot);
    }
    canvas.restore();
    ElementPainter.outline(canvas, Path()..addRRect(housing), 0.04);
    return recorder.endRecording();
  }

  static final _bladePaint = Paint()..color = const Color(0xCC9FB0BF);

  @override
  void render(Canvas canvas) {
    if (!game.camera.visibleWorldRect.overlaps(_worldBounds)) return;
    // Local origin at the column's centre.
    final half = fan.height / 2;
    final width = _width;
    // A faint tint over the whole column, thinning towards its top.
    final column = Rect.fromLTWH(-width / 2, -half, width, fan.height);
    canvas.drawRect(
      column,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            ElementPalette.air.withValues(alpha: 0.22),
            ElementPalette.air.withValues(alpha: 0),
          ],
        ).createShader(column),
    );
    // Currents rising, fading as they go: their top shows the reach.
    final count = math.max(2, (width * currentsPerMeter).round());
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 0.06;
    for (var i = 0; i < count; i++) {
      final x = -width / 2 + width * (i + 0.5) / count;
      final offset = (i * 0.37) % 1;
      final travel = (_time * currentSpeed / fan.height + offset) % 1;
      final y = half - travel * fan.height;
      final length = 0.6 + 0.4 * ((i * 0.53) % 1);
      final sway = math.sin(_time * 3 + i) * 0.08;
      stroke.color = ElementPalette.air.withValues(alpha: 0.75 * (1 - travel));
      canvas.drawLine(
        Offset(x + sway, y),
        Offset(x - sway, y + length),
        stroke,
      );
    }
    // The housing at the base, and its blades spinning edge-on.
    canvas
      ..save()
      ..translate(0, half)
      ..drawPicture(_housing ??= _recordHousing());
    final spin = _time * 18;
    for (var b = 0; b < 3; b++) {
      final phase = math.cos(spin + b * 2 * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(phase * width * 0.3, -0.12),
          width: 0.5 * (1 - phase.abs()) + 0.08,
          height: 0.08,
        ),
        _bladePaint,
      );
    }
    canvas.restore();
  }

  @override
  void onRemove() {
    _housing?.dispose();
    _housing = null;
    super.onRemove();
  }
}
