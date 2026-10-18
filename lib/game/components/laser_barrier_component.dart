import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show LaserBarrier;
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A laser barrier: a vertical beam hanging in the air that switches on and
/// off on its rhythm, flickering before it lights. Touching it while lit
/// sends the ball back (level-mechanics spec, design D9 of
/// raise-difficulty-and-pace).
class LaserBarrierComponent extends BodyComponent with ContactCallbacks {
  new({required this.barrier, required this.onTouched})
    : super(renderBody: false);

  final LaserBarrier barrier;

  /// Called when the ball touches the lit beam.
  final VoidCallback onTouched;

  /// The sensor's width, in meters.
  static const width = 0.12;

  /// How long the beam flickers before it lights, in seconds.
  static const warning = 0.3;

  /// The emitters' radius, in meters.
  static const emitterRadius = 0.16;

  double _time = 0;
  bool _ballInside = false;

  /// Whether the beam is lit now.
  bool get isOn => barrier.isOnAt(_time);

  /// Whether the beam is about to light.
  bool get isWarning {
    if (isOn) return false;
    final cycle = barrier.on + barrier.off;
    final position = (_time + barrier.phase) % cycle;
    return position >= cycle - warning;
  }

  double get _length => barrier.bottom - barrier.top;

  late final Rect _worldBounds = Rect.fromLTRB(
    barrier.x - emitterRadius * 2,
    barrier.top - emitterRadius * 2,
    barrier.x + emitterRadius * 2,
    barrier.bottom + emitterRadius * 2,
  );

  @override
  Body createBody() {
    return world.createBody(
      BodyDef(position: Vector2(barrier.x, barrier.top + _length / 2)),
    )..createShape(
      Polygon.box(width / 2, _length / 2),
      ShapeDef(isSensor: true, enableSensorEvents: true, userData: this),
    );
  }

  @override
  void beginContact(Object other, Contact contact) {
    if (other is BallComponent) _ballInside = true;
  }

  @override
  void endContact(Object other, Contact contact) {
    if (other is BallComponent) _ballInside = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    // The rhythm runs on its own clock: a respawn does not reset it.
    _time += dt;
    if (_ballInside && isOn) {
      _ballInside = false;
      onTouched();
    }
  }

  static final _glow = Paint()
    ..strokeCap = StrokeCap.round
    ..color = ElementPalette.hazard.withValues(alpha: 0.35);
  static final _core = Paint()
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFFE3E3);
  static final _idle = Paint()
    ..color = ElementPalette.hazard.withValues(alpha: 0.35);
  static final _emitter = Paint()..color = const Color(0xFF2A3138);
  static final _lens = Paint()..color = ElementPalette.hazard;

  @override
  void render(Canvas canvas) {
    if (!game.camera.visibleWorldRect.overlaps(_worldBounds)) return;
    final half = _length / 2;
    final top = Offset(0, -half);
    final bottom = Offset(0, half);
    // Lit, flickering before it lights, or a faint dashed line.
    final flicker = isWarning && (_time * 15).floor().isEven;
    if (isOn || flicker) {
      canvas
        ..drawLine(top, bottom, _glow..strokeWidth = flicker ? 0.12 : 0.3)
        ..drawLine(top, bottom, _core..strokeWidth = flicker ? 0.03 : 0.07);
    } else {
      for (var y = -half; y < half; y += 0.5) {
        canvas.drawRect(Rect.fromLTWH(-0.015, y, 0.03, 0.25), _idle);
      }
    }
    for (final end in [top, bottom]) {
      canvas
        ..drawCircle(end, emitterRadius, _emitter)
        ..drawCircle(end, emitterRadius * 0.45, _lens);
    }
  }
}
