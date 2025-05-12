import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.currentLevel,
    required this.soundEnabled,
    required this.useSensorControl,
  });

  factory SettingsState.initial() => const SettingsState(
        currentLevel: 1,
        soundEnabled: true,
        useSensorControl: false,
      );

  final int currentLevel;
  final bool soundEnabled;
  final bool useSensorControl;

  SettingsState copyWith({
    int? currentLevel,
    bool? soundEnabled,
    bool? useSensorControl,
  }) {
    return SettingsState(
      currentLevel: currentLevel ?? this.currentLevel,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      useSensorControl: useSensorControl ?? this.useSensorControl,
    );
  }

  @override
  List<Object> get props => [currentLevel, soundEnabled, useSensorControl];
}
