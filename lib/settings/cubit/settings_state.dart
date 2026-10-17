part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const new({this.settings = const PlayerSettings(), this.isLoaded = false});

  final PlayerSettings settings;

  /// Whether the stored settings have been read.
  final bool isLoaded;

  SettingsState copyWith({PlayerSettings? settings}) =>
      SettingsState(settings: settings ?? this.settings, isLoaded: isLoaded);

  @override
  List<Object> get props => [settings, isLoaded];
}
