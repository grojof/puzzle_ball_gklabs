import 'package:app_ui/app_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppTheme.dark', () {
    final theme = AppTheme.dark;

    test('is dark with the brand colors', () {
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, AppColors.primary);
      expect(theme.colorScheme.secondary, AppColors.secondary);
      expect(theme.scaffoldBackgroundColor, AppColors.background);
      expect(theme.appBarTheme.backgroundColor, AppColors.primary);
      expect(theme.dialogTheme.backgroundColor, AppColors.secondary);
      expect(theme.dividerTheme.color, AppColors.fogLayer);
    });

    test('uses the bundled Poppins family for every text style', () {
      const family = 'packages/${AppTheme.fontPackage}/${AppTheme.fontFamily}';
      final styles = [
        theme.textTheme.displayLarge,
        theme.textTheme.titleMedium,
        theme.textTheme.bodyMedium,
        theme.textTheme.labelSmall,
      ];
      for (final style in styles) {
        expect(style?.fontFamily, family);
        expect(style?.color, AppColors.text);
      }
    });

    test('styles buttons, switches, inputs and snack bars', () {
      final button = theme.elevatedButtonTheme.style!;
      expect(button.backgroundColor?.resolve({}), AppColors.primary);
      expect(theme.switchTheme.thumbColor?.resolve({}), AppColors.primary);
      expect(theme.inputDecorationTheme.fillColor, AppColors.secondary);
      expect(theme.snackBarTheme.backgroundColor, AppColors.secondary);
    });

    testWidgets('renders text with the theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const Scaffold(body: Text('Ball Odyssey')),
        ),
      );

      final text = tester.widget<RichText>(find.byType(RichText).first);
      expect(
        text.text.style?.fontFamily,
        'packages/${AppTheme.fontPackage}/${AppTheme.fontFamily}',
      );
    });
  });
}
