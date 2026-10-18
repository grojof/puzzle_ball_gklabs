# level_generator

Deterministic, infinite procedural levels for Ball Odyssey.

```dart
final generator = LevelGenerator(envelope: myEnvelope);
final level = generator.generate(seed: 'abc', level: 12);
```

- The same seed and level give the same level on every platform, the web included.
- Gaps and climbs stay within a `MovementEnvelope` (what the ball can do), with margins from the
  `DifficultyCurve`.
- `LevelValidator` checks any `LevelData` against the envelope.

Pure Dart: no Flutter or physics dependency. See `docs/decisions/0009-level-generator-and-movement-envelope.md` in the app.
