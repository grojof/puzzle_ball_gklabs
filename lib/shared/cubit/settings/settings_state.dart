import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';

class SettingsState extends Equatable {
  const new({
    required this.currentLevel,
    required this.languageCode,
    required this.soundEnabled,
    required this.useSensorControl,
  });

  factory initial() => const SettingsState(
    currentLevel: 1,
    languageCode: 'es',
    soundEnabled: true,
    useSensorControl: false,
  );

  final int currentLevel;
  final String languageCode;
  final bool soundEnabled;
  final bool useSensorControl;

  /// Getter que Flutter usará para cambiar el idioma en `MaterialApp.router`
  Locale get locale => Locale(languageCode);

  SettingsState copyWith({
    int? currentLevel,
    String? languageCode,
    bool? soundEnabled,
    bool? useSensorControl,
  }) {
    return SettingsState(
      currentLevel: currentLevel ?? this.currentLevel,
      languageCode: languageCode ?? this.languageCode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      useSensorControl: useSensorControl ?? this.useSensorControl,
    );
  }

  @override
  List<Object> get props => [
    currentLevel,
    languageCode,
    soundEnabled,
    useSensorControl,
  ];
}
