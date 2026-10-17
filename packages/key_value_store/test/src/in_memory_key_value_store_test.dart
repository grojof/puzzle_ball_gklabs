import 'package:key_value_store/key_value_store.dart';
import 'package:test/test.dart';

void main() {
  group(InMemoryKeyValueStore, () {
    late InMemoryKeyValueStore store;

    setUp(() => store = InMemoryKeyValueStore());

    test('returns null for missing keys', () async {
      expect(await store.getString('k'), isNull);
      expect(await store.getBool('k'), isNull);
      expect(await store.getDouble('k'), isNull);
      expect(await store.getInt('k'), isNull);
      expect(await store.getStringList('k'), isNull);
      expect(await store.containsKey('k'), isFalse);
    });

    test('stores and reads every type', () async {
      await store.setString('s', 'text');
      await store.setBool('b', value: true);
      await store.setDouble('d', 0.5);
      await store.setInt('i', 3);
      await store.setStringList('l', ['a', 'b']);

      expect(await store.getString('s'), 'text');
      expect(await store.getBool('b'), isTrue);
      expect(await store.getDouble('d'), 0.5);
      expect(await store.getInt('i'), 3);
      expect(await store.getStringList('l'), ['a', 'b']);
      expect(await store.containsKey('s'), isTrue);
    });

    test('returns null when the stored type differs', () async {
      store = InMemoryKeyValueStore({'k': 1, 'l': 'not a list'});

      expect(await store.getString('k'), isNull);
      expect(await store.getBool('k'), isNull);
      expect(await store.getDouble('k'), isNull);
      expect(await store.getStringList('l'), isNull);
      expect(await store.getInt('k'), 1);
    });

    test('removes values', () async {
      await store.setInt('i', 1);
      await store.remove('i');

      expect(await store.containsKey('i'), isFalse);
    });

    test('copies lists in and out', () async {
      final list = ['a'];
      await store.setStringList('l', list);
      list.add('b');
      (await store.getStringList('l'))!.add('c');

      expect(await store.getStringList('l'), ['a']);
    });

    test('exposes an unmodifiable copy of its values', () {
      store = InMemoryKeyValueStore({'k': 'v'});

      expect(store.values, {'k': 'v'});
      expect(() => store.values['x'] = 'y', throwsUnsupportedError);
    });
  });
}
