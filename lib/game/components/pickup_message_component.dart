import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show BoostType;
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// What a pickup message reports (game-hud spec).
enum HudMessage {
  /// A double-jump orb was collected.
  doubleJump,

  /// A checkpoint was reached.
  checkpoint;

  /// The element's color.
  Color get color => switch (this) {
    doubleJump => ElementPalette.orb,
    checkpoint => ElementPalette.checkpointActive,
  };
}

/// A short message above the ball: a small pill in the element's color with
/// its icon and text, rising a little over the ball as it moves and fading
/// out within [duration] (game-hud spec, design D3 of add-hud-indicators).
class PickupMessageComponent extends PositionComponent {
  new({
    required this.message,
    required this.text,
    required this.style,
    required this.above,
  }) : super(anchor: Anchor.bottomCenter, priority: 900);

  /// How long the message shows, in seconds.
  static const duration = 0.9;

  /// How far it rises, in logical pixels.
  static const rise = 20.0;

  final HudMessage message;
  final String text;
  final TextStyle style;

  /// The point above the ball, in screen coordinates.
  final Vector2 Function() above;

  double _elapsed = 0;
  Picture? _art;

  /// The current opacity, from 0 to 1.
  double get opacity {
    if (_elapsed < 0.15) return _elapsed / 0.15;
    if (_elapsed < 0.5) return 1;
    return (1 - (_elapsed - 0.5) / (duration - 0.5)).clamp(0.0, 1.0);
  }

  @override
  Future<void> onLoad() async {
    _follow();
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final font = style.fontSize ?? 18;
    final icon = font * 1.1;
    final pad = font * 0.5;
    size = Vector2(pad * 3 + icon + painter.width, pad * 1.2 + painter.height);
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final pill = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      Radius.circular(size.y / 2),
    );
    final color = message.color;
    canvas.drawRRect(
      pill,
      Paint()..color = Color.lerp(color, ElementPalette.outline, 0.6)!,
    );
    ElementPainter.outline(canvas, Path()..addRRect(pill), font * 0.12);
    canvas
      ..drawRRect(
        pill.deflate(font * 0.12),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = font * 0.08
          ..color = color,
      )
      ..save()
      ..translate(pad + icon / 2, size.y / 2);
    _icon(canvas, icon / 2);
    canvas.restore();
    painter.paint(
      canvas,
      Offset(pad * 2 + icon, (size.y - painter.height) / 2),
    );
    _art = recorder.endRecording();
  }

  void _icon(Canvas canvas, double radius) {
    switch (message) {
      case HudMessage.doubleJump:
        ElementPainter.orb(canvas, radius, message.color);
        ElementPainter.boostIcon(canvas, BoostType.doubleJump, radius);
      case HudMessage.checkpoint:
        final pennant = Path()
          ..moveTo(-radius * 0.5, -radius)
          ..lineTo(radius * 0.8, -radius * 0.55)
          ..lineTo(-radius * 0.5, -radius * 0.1)
          ..close();
        canvas
          ..drawRect(
            Rect.fromLTWH(-radius * 0.65, -radius, radius * 0.18, radius * 2),
            Paint()..color = const Color(0xFFE8EDF2),
          )
          ..drawPath(pennant, Paint()..color = message.color);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) {
      removeFromParent();
      return;
    }
    _follow();
  }

  /// Stays over the ball, raised by up to [rise] in the first 0.3 s.
  void _follow() {
    final t = (_elapsed / 0.3).clamp(0.0, 1.0);
    position = above() - Vector2(0, rise * (1 - (1 - t) * (1 - t)));
  }

  @override
  void render(Canvas canvas) {
    final art = _art;
    if (art == null) return;
    canvas
      ..saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, opacity))
      ..drawPicture(art)
      ..restore();
  }

  @override
  void onRemove() {
    _art?.dispose();
    _art = null;
    super.onRemove();
  }
}
