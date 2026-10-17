import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/l10n/gen/app_localizations.dart';

export 'package:puzzle_ball_gklabs/l10n/gen/app_localizations.dart';

/// Delegates for the app's strings plus Material, Cupertino and widgets
/// strings.
///
/// The Material ones come from `material_ui`: the generated
/// `AppLocalizations.localizationsDelegates` uses `flutter_localizations`,
/// whose `MaterialLocalizations` is not the one `material_ui` widgets look up.
const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

/// The interface languages, English first: Flutter falls back to the first
/// supported locale when the device prefers none of them.
const supportedLocales = [Locale('en'), Locale('es'), Locale('ca')];

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
