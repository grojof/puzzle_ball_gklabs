import 'dart:convert';

import 'package:app_ui/app_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBundle extends CachingAssetBundle {
  final requested = <String>[];

  @override
  Future<ByteData> load(String key) async {
    requested.add(key);
    final bytes = utf8.encode('Poppins license text');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('registerAppUiLicenses adds the Poppins license', () async {
    final bundle = _FakeBundle();

    registerAppUiLicenses(bundle: bundle);
    final entries = await LicenseRegistry.licenses.toList();
    final poppins = entries.where((e) => e.packages.contains('Poppins'));

    expect(poppins, isNotEmpty);
    expect(
      poppins.first.paragraphs.map((p) => p.text).join(),
      contains('Poppins license text'),
    );
    expect(bundle.requested, [poppinsLicenseAsset]);
  });

  test('registerAppUiLicenses defaults to the root bundle', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          expect(key, poppinsLicenseAsset);
          return ByteData.sublistView(utf8.encode('root license'));
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler('flutter/assets', null),
    );
    LicenseRegistry.reset();

    registerAppUiLicenses();
    final entries = await LicenseRegistry.licenses.toList();

    expect(
      entries.single.paragraphs.map((p) => p.text).join(),
      contains('root license'),
    );
  });
}
