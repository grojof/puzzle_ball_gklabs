import 'package:level_generator/src/random.dart';
import 'package:test/test.dart';

void main() {
  group('mul32', () {
    test('matches 64-bit multiplication modulo 2^32', () {
      const pairs = [
        (0xffffffff, 0xffffffff),
        (0x9e3779b9, 0x85ebca6b),
        (123456789, 987654321),
        (0, 0xdeadbeef),
      ];
      for (final (a, b) in pairs) {
        final expected =
            (BigInt.from(a) * BigInt.from(b)) % BigInt.from(4294967296);
        expect(mul32(a, b), expected.toInt());
      }
    });
  });

  group('fnv1a32', () {
    test('matches the reference values', () {
      expect(fnv1a32(''), 0x811c9dc5);
      expect(fnv1a32('a'), 0xe40c292c);
      expect(fnv1a32('foobar'), 0xbf9cf968);
    });
  });

  group('Mulberry32', () {
    test('produces the same golden sequence on every platform', () {
      final rng = Mulberry32(42);
      expect([for (var i = 0; i < 5; i++) rng.nextUint32()], golden42);
    });

    test('values stay in range', () {
      final rng = Mulberry32(7);
      for (var i = 0; i < 1000; i++) {
        final d = rng.nextDouble();
        expect(d, inInclusiveRange(0, 1));
        expect(d, lessThan(1));
        expect(rng.range(2, 3), inInclusiveRange(2, 3));
        expect(rng.intIn(1, 3), inInclusiveRange(1, 3));
      }
    });

    test('chance and weighted follow their inputs', () {
      final rng = Mulberry32(1);
      expect(rng.chance(0), isFalse);
      expect(rng.chance(1), isTrue);
      final picks = <String, int>{'a': 0, 'b': 0};
      for (var i = 0; i < 2000; i++) {
        final key = rng.weighted({'a': 3.0, 'b': 1.0});
        picks[key] = picks[key]! + 1;
      }
      expect(picks['a']! / 2000, closeTo(0.75, 0.05));
      expect(rng.weighted({'only': 0.0}), 'only');
    });
  });

  group('levelSeed', () {
    test('differs by seed and by level, and is stable', () {
      expect(levelSeed('abc', 1), isNot(levelSeed('abc', 2)));
      expect(levelSeed('abc', 1), isNot(levelSeed('abd', 1)));
      expect(levelSeed('abc', 37), goldenAbc37);
    });
  });
}

/// Golden values, computed once on the VM; the suite runs on the VM and in
/// Chrome, so any platform difference fails here.
const golden42 = [2581720956, 1925393290, 3661312704, 2876485805, 750819978];
const goldenAbc37 = 2400956408;
