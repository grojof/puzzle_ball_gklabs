import 'dart:math' as math;
import 'dart:ui' show Picture, PictureRecorder;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show BoostType;
import 'package:puzzle_ball_gklabs/game/components/ball_component.dart';
import 'package:puzzle_ball_gklabs/game/components/hud_layout.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_painter.dart';
import 'package:puzzle_ball_gklabs/game/visuals/element_palette.dart';

/// The boost tray: a short column under the sound button with the running
/// boost's icon, ringed by its remaining time, the orb's icon while its
/// charge is held, and a beating heart during an adrenaline rush (game-hud
/// spec).
class BoostTrayComponent extends PositionComponent {
  new({
    required this.activeBoost,
    required this.boostLeft,
    required this.charged,
    required this.safeArea,
    this.rushing,
  }) : super(anchor: Anchor.topRight);

  /// The system's safe area, which the tray keeps inside.
  final ValueListenable<EdgeInsets> safeArea;

  /// The boost running, if any.
  final BoostType? Function() activeBoost;

  /// The seconds left of the running boost.
  final double Function() boostLeft;

  /// Whether the orb's charge is held.
  final bool Function() charged;

  /// Whether an adrenaline rush is on.
  final bool Function()? rushing;

  /// How often the heart beats, in cycles per second.
  static const beatRate = 1.2;

  double _time = 0;
  Picture? _heart;

  /// Whether the heart shows.
  bool get showsHeart => rushing?.call() ?? false;

  double _icon = HudLayout.minControlSize;
  Vector2 _screen = Vector2.zero();
  final Map<BoostType, Picture> _art = {};

  static final _track = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x55000000);
  static final _ring = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFFFFFF);

  /// The icons shown now, left to right.
  List<BoostType> get shown => [
    ?activeBoost(),
    if (charged()) BoostType.doubleJump,
  ];

  /// The share of the running boost's time left, from 1 to 0.
  double get ringShare =>
      (boostLeft() / BallComponent.boostDuration).clamp(0.0, 1.0);

  @override
  void onMount() {
    super.onMount();
    safeArea.addListener(_place);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final icon = HudLayout.boostIconSize(size);
    if (icon != _icon) _clearArt();
    _icon = icon;
    _screen = size.clone();
    this.size = Vector2(icon, icon * 2.2);
    _place();
  }

  void _place() => position = HudLayout.trayOrigin(_screen, safeArea.value);

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
  }

  Picture _recordHeart() {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final r = _icon / 2 * 0.8;
    ElementPainter.orb(canvas, r, ElementPalette.rush);
    ElementPainter.heartIcon(canvas, r);
    return recorder.endRecording();
  }

  Picture _record(BoostType type) {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final r = _icon / 2 * 0.8;
    ElementPainter.orb(canvas, r, ElementPalette.boost(type));
    ElementPainter.boostIcon(canvas, type, r);
    return recorder.endRecording();
  }

  @override
  void render(Canvas canvas) {
    final icons = shown;
    final step = _icon * 1.2;
    if (showsHeart) {
      final phase = (_time * beatRate) % 1;
      final beat = 1 + 0.12 * math.exp(-30 * phase * phase);
      canvas
        ..save()
        ..translate(_icon / 2, _icon / 2 + icons.length * step)
        ..scale(beat)
        ..drawPicture(_heart ??= _recordHeart())
        ..restore();
    }
    if (icons.isEmpty) return;
    for (var i = 0; i < icons.length; i++) {
      final type = icons[i];
      final center = Offset(_icon / 2, _icon / 2 + i * step);
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..drawPicture(_art[type] ??= _record(type))
        ..restore();
      if (type == BoostType.doubleJump) continue;
      final ring = Rect.fromCircle(center: center, radius: _icon / 2);
      final width = _icon * 0.09;
      canvas
        ..drawCircle(center, _icon / 2, _track..strokeWidth = width)
        ..drawArc(
          ring,
          -math.pi / 2,
          2 * math.pi * ringShare,
          false,
          _ring..strokeWidth = width,
        );
    }
  }

  void _clearArt() {
    for (final picture in _art.values) {
      picture.dispose();
    }
    _art.clear();
    _heart?.dispose();
    _heart = null;
  }

  @override
  void onRemove() {
    safeArea.removeListener(_place);
    _clearArt();
    super.onRemove();
  }
}
