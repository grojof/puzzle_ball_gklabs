# savegame_repository

Ball Odyssey savegames: a seed, the number of levels and the furthest level reached. They are stored in any
`KeyValueStore`.

```dart
final repository = SavegameRepository(store);
final games = await repository.loadAll();
await repository.update(games.first.copyWith(currentLevel: 4));
```

- The storage format is the one earlier versions used: a list of JSON strings under `savedGames`. Existing saves load as
  they are.
- `update` never lowers the current level and always stamps the last-played time.
- Malformed stored entries are skipped instead of failing the whole list.
