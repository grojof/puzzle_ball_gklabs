import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The asset key of the Poppins license, as seen from the app.
const poppinsLicenseAsset = 'packages/app_ui/assets/fonts/poppins/OFL.txt';

/// Registers the licenses of the assets bundled by this package, so they show
/// up in the app's license page.
///
/// Call it once at startup. [bundle] defaults to the root bundle.
void registerAppUiLicenses({AssetBundle? bundle}) {
  LicenseRegistry.addLicense(() async* {
    final text = await (bundle ?? rootBundle).loadString(poppinsLicenseAsset);
    yield LicenseEntryWithLineBreaks(const ['Poppins'], text);
  });
}
