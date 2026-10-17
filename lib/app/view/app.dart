import 'dart:async';

import 'package:app_ui/app_ui.dart';
import 'package:flame/cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puzzle_ball_gklabs/app/router.dart';
import 'package:puzzle_ball_gklabs/audio/audio_service.dart';
import 'package:puzzle_ball_gklabs/audio/audio_settings_listener.dart';
import 'package:puzzle_ball_gklabs/l10n/l10n.dart';
import 'package:puzzle_ball_gklabs/loading/loading.dart';
import 'package:puzzle_ball_gklabs/settings/settings.dart';
import 'package:puzzle_ball_gklabs/shared/cubit/cubit.dart';
import 'package:puzzle_ball_gklabs/shared/storage/shared_preferences_key_value_store.dart';
import 'package:savegame_repository/savegame_repository.dart';
import 'package:settings_repository/settings_repository.dart';

/// The app, with its repositories, audio and router created once.
class App extends StatefulWidget {
  const new({
    required this.settingsRepository,
    required this.savegameRepository,
    this.audio,
    this.isWeb = kIsWeb,
    this.initialLocation = AppRoutes.loading,
    super.key,
  });

  /// The app on the device's storage.
  factory onDevice() {
    final store = SharedPreferencesKeyValueStore();
    return App(
      settingsRepository: SettingsRepository(store),
      savegameRepository: SavegameRepository(store),
    );
  }

  final SettingsRepository settingsRepository;
  final SavegameRepository savegameRepository;

  /// Audio playback; tests pass one on a fake backend.
  final AudioService? audio;

  /// On the web, audio waits for the first user interaction (game-audio spec).
  final bool isWeb;

  /// Screen shown first; tests open other screens directly.
  final String initialLocation;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _images = Images(prefix: '');
  late final AudioService _audio = widget.audio ?? AudioService();
  late final SettingsCubit _settings = SettingsCubit(widget.settingsRepository);
  late final SavegameCubit _savegames = SavegameCubit(
    widget.savegameRepository,
  );
  late final PreloadCubit _preload = PreloadCubit(_images, _audio);
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );
  late final AppLifecycleListener _lifecycle;
  bool _unlocked = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(_audio.pause()),
      onShow: () => unawaited(_audio.resume()),
    );
    if (widget.isWeb) HardwareKeyboard.instance.addHandler(_unlockOnKey);
    unawaited(_start());
  }

  /// Loads settings, savegames and assets, then starts the music: an explicit
  /// start, so no settings emission can be missed (design D6).
  Future<void> _start() async {
    try {
      await Future.wait<void>([_settings.load(), _savegames.load()]);
      await _preload.loadSequentially();
      await AudioSettingsListener.apply(_audio, _settings.state.settings);
      await _audio.startMusic();
    } on Object catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stack, library: 'app'),
      );
    }
  }

  bool _unlockOnKey(KeyEvent event) {
    unawaited(_unlockAudio());
    return false;
  }

  Future<void> _unlockAudio() async {
    if (_unlocked) return;
    _unlocked = true;
    HardwareKeyboard.instance.removeHandler(_unlockOnKey);
    await _audio.unlock();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_unlockOnKey);
    _lifecycle.dispose();
    _router.dispose();
    unawaited(_preload.close());
    unawaited(_settings.close());
    unawaited(_savegames.close());
    unawaited(_audio.dispose());
    _images.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _images),
        RepositoryProvider.value(value: _audio),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _preload),
          BlocProvider.value(value: _settings),
          BlocProvider.value(value: _savegames),
        ],
        child: AudioSettingsListener(
          child: Listener(
            onPointerDown: widget.isWeb
                ? (_) => unawaited(_unlockAudio())
                : null,
            child: AppView(router: _router),
          ),
        ),
      ),
    );
  }
}

class AppView extends StatelessWidget {
  const new({required this.router, super.key});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    final languageCode = context.select<SettingsCubit, String?>(
      (cubit) => cubit.state.settings.languageCode,
    );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      // Null follows the device, falling back to English (player-settings).
      locale: languageCode == null ? null : Locale(languageCode),
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      onGenerateTitle: (context) => context.l10n.titleAppBarTitle,
    );
  }
}
