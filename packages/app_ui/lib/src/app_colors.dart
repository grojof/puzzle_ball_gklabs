import 'package:material_ui/material_ui.dart';

/// The color palette of Ball Odyssey: a night sky with warm gold accents.
abstract final class AppColors {
  /// Warm gold for primary actions, app bars and highlights.
  static const Color primary = Color(0xFFE0AC00);

  /// Deep indigo for surfaces such as dialogs, inputs and snack bars.
  static const Color secondary = Color(0xFF2E365D);

  /// Vivid violet for accents.
  static const Color accent = Color(0xFF804AFF);

  /// Night navy used as the main background.
  static const Color background = Color(0xFF0B1627);

  /// Light lavender for text on dark backgrounds.
  static const Color text = Color(0xFFE6E6FA);

  /// Neon cyan for glows and portals.
  static const Color glowBlue = Color(0xFF00CFFF);

  /// Bright purple for mystic glows and particles.
  static const Color glowPurple = Color(0xFF7B61FF);

  /// Muted blue for fog, shadows, dividers and middle layers.
  static const Color fogLayer = Color(0xFF4C5C94);
}
