import 'dart:convert';

/// The version of the generator's output.
///
/// Bump it whenever a change makes the same seed and level produce a
/// different level, so shared seeds can say which generator they belong to.
const generatorVersion = 2;

const _mask32 = 0xffffffff;

/// Multiplies two 32-bit unsigned integers modulo 2³².
///
/// Split into 16-bit halves so that every intermediate value stays below
/// 2⁵³, which keeps the result exact on the web, where integers are doubles.
int mul32(int a, int b) {
  final aLow = a & 0xffff;
  final aHigh = (a >>> 16) & 0xffff;
  final bLow = b & 0xffff;
  final bHigh = (b >>> 16) & 0xffff;
  final cross = ((aHigh * bLow + aLow * bHigh) & 0xffff) * 0x10000;
  return (aLow * bLow + cross) & _mask32;
}

/// FNV-1a 32-bit hash of the UTF-8 bytes of [text].
int fnv1a32(String text) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(text)) {
    hash = mul32(hash ^ byte, 0x01000193);
  }
  return hash;
}

/// The seed of the random stream for [level] of [seed].
int levelSeed(String seed, int level) {
  var mixed = mul32((level & _mask32) ^ 0x9e3779b9, 0x85ebca6b);
  mixed = (mixed ^ (mixed >>> 13)) & _mask32;
  return (fnv1a32(seed) ^ mixed) & _mask32;
}

/// The mulberry32 generator, on 32-bit operations only, so a seed gives the
/// same sequence on the Dart VM and on the web.
///
/// `dart:math`'s `Random` makes no such promise across platforms.
class Mulberry32 {
  /// A generator whose sequence is fully determined by [seed].
  new(int seed) : _state = seed & _mask32;

  int _state;

  /// The next value in [0, 2³²).
  int nextUint32() {
    _state = (_state + 0x6d2b79f5) & _mask32;
    var t = _state;
    t = mul32(t ^ (t >>> 15), t | 1);
    t = (t ^ ((t + mul32(t ^ (t >>> 7), t | 61)) & _mask32)) & _mask32;
    return (t ^ (t >>> 14)) & _mask32;
  }

  /// The next value in [0, 1).
  double nextDouble() => nextUint32() / 4294967296;

  /// A value in [min, max).
  double range(double min, double max) => min + nextDouble() * (max - min);

  /// An integer in [min, max], both included.
  int intIn(int min, int max) => min + (nextDouble() * (max - min + 1)).floor();

  /// True with probability [probability].
  bool chance(double probability) => nextDouble() < probability;

  /// Picks a key of [weights] with probability proportional to its weight.
  ///
  /// Iterates in the map's order, so callers pass maps with a fixed order.
  T weighted<T>(Map<T, double> weights) {
    final total = weights.values.fold<double>(0, (sum, w) => sum + w);
    var roll = nextDouble() * total;
    for (final MapEntry(:key, :value) in weights.entries) {
      roll -= value;
      if (roll < 0) return key;
    }
    return weights.keys.last;
  }
}
