# settings_repository

The player's persisted preferences for Ball Odyssey: music and effects volumes, mute, control mode and language.

```dart
final repository = SettingsRepository(store); // any KeyValueStore
final settings = await repository.load();
await repository.save(settings.copyWith(musicVolume: 0.5));
```

- Each stored value is validated on its own; anything missing, mistyped or out of range falls back to its default.
- Settings written by earlier versions are read too: `soundEnabled: false` becomes `muted`, and `languageCode` and
  `useSensorControl` keep their meaning. `soundEnabled` is still written, so an older build sees the mute choice.
- A `null` language code means "follow the device language".
