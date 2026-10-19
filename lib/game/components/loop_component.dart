import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show Loop;
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// A vertical loop the ball rides around on its inside (level-mechanics
/// spec, design D5 of add-curved-terrain-and-physics).
///
/// In 2D the way in and the way out cross at the loop's foot, so the track
/// is two one-sided arcs that take turns: the rising half, from the foot up
/// to the top on the right, and the falling half, from the top down to the
/// foot on the left. A ball rolling in meets the rising half; nearing the
/// top it meets the falling half too, and once it is on its way down the
/// left, the rising half stops colliding, so the ball rolls out along the
/// floor. A ball too slow to reach the top, or one that falls in from
/// above, can always roll out: back down the right, or low on the left and
/// heading back, the falling half stops colliding again, so it is never
/// trapped inside. The track resets once the ball has left.
///
/// Drawn as a steel track on struts, with rails and ties, a warm glow inside
/// and chevrons running the way the ball goes round; a ring of light flashes
/// when the ball completes it (game-visuals spec).
class LoopComponent extends Component {
  new({required this.loop, required this.ball});

  final Loop loop;

  /// The ball riding the loop.
  final BallComponent ball;

  /// How far past the loop's sides the ball must be for the rising half to
  /// come back, in meters.
  static const leaveDistance = 0.5;

  late final LoopArcComponent rising = LoopArcComponent(
    loop: loop,
    from: 0,
    to: math.pi,
  );
  late final LoopArcComponent falling = LoopArcComponent(
    loop: loop,
    from: math.pi,
    to: 2 * math.pi,
  );

  @override
  Future<void> onLoad() async {
    await addAll([rising, falling]);
    falling.isActive = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!ball.isMounted || !rising.isMounted) return;
    final p = ball.body.position;
    if (p.x > loop.right + leaveDistance ||
        p.x < loop.left - leaveDistance ||
        p.y > loop.foot.y + leaveDistance) {
      _reset();
      return;
    }
    final angle = LoopArcComponent.angleOf(loop, p);
    if (!falling.isActive && angle > 0.6 * math.pi && angle <= math.pi) {
      // Nearing the top: the falling half takes over past it.
      falling.isActive = true;
    } else if (falling.isActive &&
        rising.isActive &&
        angle > 1.2 * math.pi &&
        angle < 1.9 * math.pi) {
      // On its way down the left: the way out opens, and the loop is done.
      rising.isActive = false;
      _sinceLap = 0;
    } else if (falling.isActive && rising.isActive && angle < 0.5 * math.pi) {
      // Fell back down the right: it rolls out the way it came.
      falling.isActive = false;
    } else if (falling.isActive &&
        !rising.isActive &&
        angle > 1.6 * math.pi &&
        ball.body.linearVelocity.x < -0.5) {
      // Low on the left and heading back, not out: it may go back.
      _reset();
    }
  }

  void _reset() {
    rising.isActive = true;
    falling.isActive = false;
  }

  /// Puts the track back as it was: after a respawn.
  void restore() {
    if (rising.isMounted) _reset();
  }

  /// Seconds since the loop appeared, to run its chevrons.
  double _time = 0;

  /// Seconds since the ball last completed the loop.
  double _sinceLap = double.infinity;

  /// How long the flash of a completed loop lasts, in seconds.
  static const lapFlash = 0.6;

  /// Whether a completed loop is flashing.
  bool get isFlashing => _sinceLap < lapFlash;

  @override
  void updateTree(double dt) {
    _time += dt;
    _sinceLap += dt;
    super.updateTree(dt);
  }

  /// The track's width, outside the circle the ball rolls on, in meters.
  static const trackWidth = 0.26;

  /// How many chevrons run round the track, and how fast, in turns per
  /// second.
  static const chevrons = 9;
  static const chevronSpeed = 0.35;

  /// The point at [angle] on a circle of [radius] around the centre: 0 at
  /// the foot, a quarter turn on the right, half a turn at the top.
  Offset _at(double angle, double radius) {
    final c = loop.center;
    return Offset(
      c.x + radius * math.sin(angle),
      c.y + radius * math.cos(angle),
    );
  }

  late final Rect _bounds =
      Rect.fromCircle(
        center: Offset(loop.center.x, loop.center.y),
        radius: loop.radius + trackWidth + 0.5,
      ).expandToInclude(
        Rect.fromLTWH(
          loop.left - 0.5,
          loop.foot.y - 0.1,
          2 * loop.radius + 1,
          0.2,
        ),
      );

  /// The track, struts and glow, recorded once and replayed every frame.
  late final Picture _art = _record();

  Picture _record() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final c = Offset(loop.center.x, loop.center.y);
    final r = loop.radius;
    const outline = ElementPalette.outline;
    final steel = Color.lerp(ElementPalette.track, outline, 0.55)!;
    // Struts from the track's sides down to the run, braced, on a base.
    final strut = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.09
      ..strokeCap = StrokeCap.round
      ..color = steel;
    final brace = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.04
      ..color = steel;
    final ground = loop.foot.y;
    for (final side in [-1.0, 1.0]) {
      final top = _at(side * 0.62 * math.pi, r + trackWidth);
      final foot = Offset(c.dx + side * (r + 0.35), ground);
      final inner = Offset(c.dx + side * (r - 0.25), ground);
      canvas
        ..drawLine(top, foot, strut)
        ..drawLine(top, inner, strut);
      for (var t = 0.25; t < 1; t += 0.25) {
        canvas.drawLine(
          Offset.lerp(top, foot, t)!,
          Offset.lerp(top, inner, t + 0.25)!,
          brace,
        );
      }
    }
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - r - 0.5, ground - 0.12, 2 * r + 1, 0.12),
          const Radius.circular(0.05),
        ),
        Paint()..color = steel,
      )
      // A warm glow inside, the colour of the speed boost that feeds it.
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              ElementPalette.speed.withValues(alpha: 0),
              ElementPalette.speed.withValues(alpha: 0),
              ElementPalette.speed.withValues(alpha: 0.28),
            ],
            stops: const [0, 0.72, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    // The track: a shadow, the band lit from the top left, rails and ties.
    final band = Rect.fromCircle(center: c, radius: r + trackWidth / 2);
    canvas
      ..drawOval(
        band.shift(const Offset(0.1, 0.12)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackWidth
          ..color = const Color(0x44000000),
      )
      ..drawOval(
        band,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = trackWidth
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(ElementPalette.track, const Color(0xFFFFFFFF), 0.4)!,
              ElementPalette.track,
              steel,
            ],
          ).createShader(band.inflate(trackWidth)),
      );
    final tie = Paint()
      ..strokeWidth = 0.03
      ..color = steel;
    for (var i = 0; i < 36; i++) {
      final angle = 2 * math.pi * i / 36;
      canvas.drawLine(
        _at(angle, r + 0.05),
        _at(angle, r + trackWidth - 0.05),
        tie,
      );
    }
    final rail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.05;
    canvas
      ..drawCircle(c, r + 0.025, rail..color = const Color(0xFFFFFFFF))
      ..drawCircle(c, r + trackWidth - 0.025, rail..color = steel)
      ..drawCircle(
        c,
        r - 0.01,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.02
          ..color = outline,
      )
      ..drawCircle(
        c,
        r + trackWidth + 0.01,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.03
          ..color = outline,
      );
    return recorder.endRecording();
  }

  static final _chevron = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.06
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = ElementPalette.speed;

  /// Chevrons in the band, running the way the ball goes round.
  void _renderChevrons(Canvas canvas) {
    final r = loop.radius + trackWidth / 2;
    const size = 0.09;
    final path = Path();
    for (var i = 0; i < chevrons; i++) {
      final angle = 2 * math.pi * (i / chevrons + (_time * chevronSpeed) % 1);
      final tip = _at(angle, r);
      // Along the track and out from the centre, at this angle.
      final along = Offset(math.cos(angle), -math.sin(angle));
      final out = Offset(math.sin(angle), math.cos(angle));
      path
        ..moveTo(
          tip.dx - along.dx * size + out.dx * size,
          tip.dy - along.dy * size + out.dy * size,
        )
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(
          tip.dx - along.dx * size - out.dx * size,
          tip.dy - along.dy * size - out.dy * size,
        );
    }
    canvas.drawPath(path, _chevron);
  }

  /// A ring of light spreading from the track after a completed loop.
  void _renderFlash(Canvas canvas) {
    final t = _sinceLap / lapFlash;
    canvas.drawCircle(
      Offset(loop.center.x, loop.center.y),
      loop.radius + trackWidth + t * 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.18 * (1 - t) + 0.02
        ..color = ElementPalette.speed.withValues(alpha: 0.8 * (1 - t)),
    );
  }

  @override
  void render(Canvas canvas) {
    final camera = findGame()?.camera;
    if (camera != null && !camera.visibleWorldRect.overlaps(_bounds)) return;
    canvas.drawPicture(_art);
    _renderChevrons(canvas);
    if (isFlashing) _renderFlash(canvas);
  }
}

/// One half of a loop's track: a one-sided chain the ball rides on its
/// inside, from angle [from] to [to] (0 at the foot, a quarter turn on the
/// right, half a turn at the top).
class LoopArcComponent extends BodyComponent {
  new({required this.loop, required this.from, required this.to})
    : super(renderBody: false);

  final Loop loop;
  final double from;
  final double to;

  /// How many segments make up the arc.
  static const segments = 48;

  /// How far from the foot, as an angle, the ball counts as riding the
  /// track: at the foot it still rolls on the floor.
  static const footAngle = 0.12;

  bool _active = true;

  /// The chain's segments, whose filters switch the arc on and off.
  List<Shape> _segments = const [];

  /// Whether the arc collides. Switched through the segments' filters,
  /// which Box2D re-applies to the contacts at once.
  bool get isActive => _active;
  set isActive(bool value) {
    if (value == _active) return;
    _active = value;
    for (final segment in _segments) {
      segment.filter = Filter(maskBits: value ? Filter.allCategories : 0);
    }
  }

  /// The point of the track at angle [angle].
  Vector2 _at(double angle) {
    final center = loop.center;
    return Vector2(
      center.x + loop.radius * math.sin(angle),
      center.y + loop.radius * math.cos(angle),
    );
  }

  /// Where [point] lies around [loop], as an angle from 0 at the foot,
  /// through a quarter turn on the right and half a turn at the top, to a
  /// full turn.
  static double angleOf(Loop loop, Vector2 point) {
    final c = loop.center;
    final angle = math.atan2(point.x - c.x, point.y - c.y);
    return angle < 0 ? angle + 2 * math.pi : angle;
  }

  /// Whether a ball centered at [center] rides this arc: touching it, away
  /// from the foot.
  bool holds(Vector2 center) {
    final c = loop.center;
    final angle = angleOf(loop, center);
    final lo = math.max(from, footAngle);
    final hi = math.min(to, 2 * math.pi - footAngle);
    return angle >= lo &&
        angle <= hi &&
        center.distanceTo(Vector2(c.x, c.y)) > loop.radius - 0.6;
  }

  @override
  Body createBody() {
    final body = world.createBody(BodyDef(userData: this));
    final step = (to - from) / segments;
    final chain = body.createChain(
      ChainDef(
        // Turning this way, the solid side faces the loop's centre; the
        // first and last points are ghosts.
        points: [for (var i = -1; i <= segments + 1; i++) _at(from + step * i)],
        materials: [SurfaceMaterial(friction: 0)],
      ),
    );
    _segments = chain.segments;
    for (final segment in _segments) {
      segment
        ..contactEventsEnabled = true
        ..filter = Filter(maskBits: _active ? Filter.allCategories : 0);
    }
    return body;
  }
}
