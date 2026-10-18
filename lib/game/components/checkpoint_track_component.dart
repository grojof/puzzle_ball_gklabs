import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/painting.dart';
import 'package:puzzle_ball_gklabs/game/components/hud_layout.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// The checkpoint track: one small flag per checkpoint of the level, in a
/// row under the pause button, grey until reached and gold after (game-hud
/// spec). Beyond [maxFlags] it shows a count instead.
class CheckpointTrackComponent extends PositionComponent {
  new({required this.reached, required this.safeArea});

  /// Whether each checkpoint of the level, in course order, is reached.
  final List<bool> Function() reached;

  /// The system's safe area, which the track keeps inside.
  final ValueListenable<EdgeInsets> safeArea;

  /// The most flags drawn before the track shows a count.
  static const maxFlags = 8;

  /// The distance between flags, in flag heights.
  static const spacing = 1.25;

  double _flag = HudLayout.minControlSize;
  final Map<bool, Picture> _art = {};
  TextPainter? _count;
  String _countText = '';

  /// What the track shows now: the flags' states, or a count beyond
  /// [maxFlags].
  List<bool> get shown => reached();

  @override
  void onMount() {
    super.onMount();
    safeArea.addListener(_place);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final flag = HudLayout.flagSize(size);
    if (flag != _flag) _clearArt();
    _flag = flag;
    this.size = Vector2(0, flag);
    _place();
  }

  void _place() => position = HudLayout.trackOrigin(safeArea.value);

  @override
  void update(double dt) {
    super.update(dt);
    // As wide as what it shows: the flags, or a flag and a count.
    final count = reached().length;
    size.x = count > maxFlags ? 4 * _flag : count * spacing * _flag;
  }

  Picture _record({required bool reached}) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final h = _flag;
    final pole = Rect.fromLTWH(h * 0.1, 0, h * 0.1, h);
    final pennant = Path()
      ..moveTo(h * 0.2, h * 0.05)
      ..lineTo(h * 0.75, h * 0.25)
      ..lineTo(h * 0.2, h * 0.45)
      ..close();
    final color = reached
        ? ElementPalette.checkpointActive
        : ElementPalette.checkpointIdle;
    canvas
      ..drawRect(pole, Paint()..color = const Color(0xFFE8EDF2))
      ..drawPath(pennant, Paint()..color = color);
    ElementPainter.outline(canvas, Path()..addRect(pole), h * 0.06);
    ElementPainter.outline(canvas, pennant, h * 0.06);
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final states = reached();
    if (states.isEmpty) return;
    if (states.length > maxFlags) {
      _renderCount(canvas, states);
      return;
    }
    for (var i = 0; i < states.length; i++) {
      final art = _art[states[i]] ??= _record(reached: states[i]);
      canvas
        ..save()
        ..translate(i * spacing * _flag, 0)
        ..drawPicture(art)
        ..restore();
    }
  }

  /// A gold flag and "reached/total".
  void _renderCount(Canvas canvas, List<bool> states) {
    final done = states.where((s) => s).length;
    final text = '$done/${states.length}';
    if (text != _countText || _count == null) {
      _countText = text;
      _count = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: _flag * 0.8,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFFFFFFF),
            shadows: const [Shadow(blurRadius: 2, color: Color(0xAA000000))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    canvas.drawPicture(_art[true] ??= _record(reached: true));
    _count!.paint(
      canvas,
      Offset(_flag * spacing * 0.8, (_flag - _count!.height) / 2),
    );
  }

  void _clearArt() {
    for (final picture in _art.values) {
      picture.dispose();
    }
    _art.clear();
    _count = null;
  }

  @override
  void onRemove() {
    safeArea.removeListener(_place);
    _clearArt();
    super.onRemove();
  }
}
