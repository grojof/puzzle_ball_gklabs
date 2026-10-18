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

  /// The outline every element carries.
  static const outline = Color(0xFF0E0B16);

  /// The light rim inside the outline: with it, the fill, the outline or the
  /// rim contrasts with any background, dark, light or in between.
  static const rim = Color(0xFFFFFFFF);

  /// Reserved for the next change's elements.
  static const hazard = Color(0xFFFF3B3B);
  static const logicA = Color(0xFF29D3F5);
  static const logicB = Color(0xFFF54BD8);
  static const memory = Color(0x99FFFFFF);

  /// The color of a boost of [type].
  static Color boost(BoostType type) => switch (type) {
    BoostType.jump => jump,
    BoostType.speed => speed,
    BoostType.gravity => gravity,
  };

  /// The WCAG contrast ratio between [a] and [b], from 1 to 21.
  static double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final (light, dark) = la > lb ? (la, lb) : (lb, la);
    return (light + 0.05) / (dark + 0.05);
  }
}
