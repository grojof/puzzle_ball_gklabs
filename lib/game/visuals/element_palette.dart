import 'package:flutter/painting.dart';
import 'package:level_generator/level_generator.dart' show BoostType;

/// The colors of gameplay elements: fixed, the same in every biome, and
/// kept apart from each other (design D5). Each element is drawn with
/// depth and a dark [outline], which keeps it readable against any biome.
abstract final class ElementPalette {
  static const jump = Color(0xFF43D17A);
  static const speed = Color(0xFFFF8F1F);
  static const gravity = Color(0xFFA66BFF);
  static const checkpointIdle = Color(0xFFC7D2DB);
  static const checkpointActive = Color(0xFFFFC531);
  static const portal = Color(0xFF4FE3FF);
  static const orb = Color(0xFF35B0FF);

  /// The outline every element carries.
  static const outline = Color(0xFF0E0B16);

  /// The light rim inside the outline: with it, the fill, the outline or the
  /// rim contrasts with any background, dark, light or in between.
  static const rim = Color(0xFFFFFFFF);

  /// The red of spike tips.
  static const hazard = Color(0xFFFF3B3B);

  /// A trampoline's springy pad.
  static const trampoline = Color(0xFFFF5FA2);

  /// A conveyor belt's rubber, and the marks that show its direction.
  static const belt = Color(0xFF3A3F47);
  static const beltMark = Color(0xFFFFD23F);

  /// Ice, glassy and pale, and mud, dark and soft.
  static const ice = Color(0xFFBFEFFF);
  static const mud = Color(0xFF6B4423);

  /// A loop's steel track.
  static const track = Color(0xFFE8ECF2);

  /// The adrenaline rush: a heart's crimson.
  static const rush = Color(0xFFE8124F);

  /// Reserved for the next change's elements.
  static const logicA = Color(0xFF29D3F5);
  static const logicB = Color(0xFFF54BD8);
  static const memory = Color(0x99FFFFFF);

  /// The color of a boost of [type].
  static Color boost(BoostType type) => switch (type) {
    BoostType.jump => jump,
    BoostType.speed => speed,
    BoostType.gravity => gravity,
    BoostType.doubleJump => orb,
  };

  /// The WCAG contrast ratio between [a] and [b], from 1 to 21.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (light, dark) = la > lb ? (la, lb) : (lb, la);
    return (light + 0.05) / (dark + 0.05);
  }
}
