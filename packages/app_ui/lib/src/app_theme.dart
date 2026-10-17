import 'package:app_ui/src/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// The themes of Ball Odyssey.
abstract final class AppTheme {
  /// The font family bundled by this package.
  static const String fontFamily = 'Poppins';

  /// The package that bundles [fontFamily], needed to resolve it from the app.
  static const String fontPackage = 'app_ui';

  /// The dark theme: night background, gold primary color and Poppins text.
  static ThemeData get dark {
    final base = ThemeData(
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      package: fontPackage,
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
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: TextStyle(color: AppColors.text.withValues(alpha: 0.6)),
        labelStyle: const TextStyle(color: AppColors.text),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.fogLayer,
        thickness: 1,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
    );
  }
}
