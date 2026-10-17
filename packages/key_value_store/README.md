# key_value_store

A typed key-value storage interface for Ball Odyssey's repositories, with an in-memory implementation for tests.

The app provides the platform implementation (backed by `shared_preferences`); repositories depend only on
`KeyValueStore`.

```dart
final store = InMemoryKeyValueStore({'muted': true});
final muted = await store.getBool('muted'); // true
await store.setDouble('musicVolume', 0.5);
```

Getters return `null` when a key is missing or holds another type.
