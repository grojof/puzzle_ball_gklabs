import 'package:app_ui/app_ui.dart';
import 'package:flame/cache.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_value_store/key_value_store.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/audio/audio_settings_listener.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/loading/loading.dart';
import 'package:puzzle_ball_gklabs/settings/settings.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/cubit.dart';
import 'package:savegame_repository/savegame_repository.dart';
import 'package:settings_repository/settings_repository.dart';

import '../audio/audio_service_test.dart' show FakeBackend;

/// The app's providers on in-memory storage and fake audio.
class TestDependencies {
  new({KeyValueStore? store, FakeBackend? backend, Images? images})
    : store = store ?? InMemoryKeyValueStore(),
      backend = backend ?? FakeBackend(),
      images = images ?? Images(prefix: '');

  final KeyValueStore store;
  final FakeBackend backend;
  final Images images;
  late final AudioService audio = AudioService(backend: backend);
  late final SettingsCubit settings = SettingsCubit(SettingsRepository(store));
  late final SavegameCubit savegames = SavegameCubit(SavegameRepository(store));
  late final PreloadCubit preload = PreloadCubit(images, audio);

  /// Loads settings and savegames, and preloads the fake audio.
  Future<void> load() async {
    await settings.load();
    await savegames.load();
    await audio.preload();
  }

  Widget wrap(Widget child) => MultiRepositoryProvider(
    providers: [
      RepositoryProvider.value(value: images),
      RepositoryProvider.value(value: audio),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: settings),
        BlocProvider.value(value: savegames),
        BlocProvider.value(value: preload),
      ],
      child: AudioSettingsListener(child: child),
    ),
  );
}

extension PumpApp on WidgetTester {
  /// Pumps [widget] in a themed, localized app in [locale].
  Future<TestDependencies> pumpApp(
    Widget widget, {
    Locale locale = const Locale('en'),
    TestDependencies? dependencies,
  }) async {
    final deps = dependencies ?? TestDependencies();
    await pumpWidget(
      deps.wrap(
        MaterialApp(
          theme: AppTheme.dark,
          locale: locale,
          localizationsDelegates: localizationsDelegates,
          supportedLocales: supportedLocales,
          home: widget,
        ),
      ),
    );
    return deps;
  }
}
