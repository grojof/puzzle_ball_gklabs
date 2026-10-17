import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  /// 🎯 Color principal (azul eléctrico vibrante)
  static const Color primary = Color(0xFFE0AC00);

  /// 🌌 Color secundario oscuro, ideal para capas de fondo
  static const Color secondary = Color(0xFF2E365D);

  /// 💡 Color de acento (amarillo eléctrico cálido, para bolas o portales)
  static const Color accent = Color(0xFF804AFF);

  /// 🌃 Fondo principal nocturno
  static const Color background = Color(0xFF0b1627);

  /// ✨ Color de texto lavanda claro para buena legibilidad
  static const Color text = Color(0xFFE6E6FA);

  /// 🔵 Azul neón para efectos brillantes, portales o UI
  static const Color glowBlue = Color(0xFF00CFFF);

  /// 🟣 Morado brillante para brillos místicos o partículas
  static const Color glowPurple = Color(0xFF7B61FF);

  /// 🌫️ Azul apagado para niebla, sombras o capas intermedias
  static const Color fogLayer = Color(0xFF4C5C94);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.background,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.background,
        onPrimary: AppColors.background,
        onSecondary: AppColors.text,
        onSurface: AppColors.text,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: AppColors.background,
          backgroundColor: AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.primary),
        trackColor: WidgetStateProperty.all(AppColors.secondary),
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: TextStyle(color: AppColors.text),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.secondary,
        titleTextStyle: TextStyle(
          color: AppColors.text,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(color: AppColors.text),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(
          color: AppColors.text.withAlpha((0.6 * 255).toInt()),
        ),
        labelStyle: const TextStyle(color: AppColors.text),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.fogLayer,
        thickness: 1,
      ),
    );
  }
}
