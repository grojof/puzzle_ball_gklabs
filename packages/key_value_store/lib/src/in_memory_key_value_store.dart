import 'package:key_value_store/src/key_value_store.dart';

/// A [KeyValueStore] kept in memory, for tests and previews.
class InMemoryKeyValueStore implements KeyValueStore {
  /// Creates a store holding a copy of [initialValues].
  new([Map<String, Object> initialValues = const {}])
    : _values = Map.of(initialValues);

  final Map<String, Object> _values;

  /// A copy of every stored value, by key.
  Map<String, Object> get values => Map.unmodifiable(_values);

  T? _get<T>(String key) {
    final value = _values[key];
    return value is T ? value : null;
  }

  @override
  Future<String?> getString(String key) async => _get<String>(key);

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<bool?> getBool(String key) async => _get<bool>(key);

  @override
  Future<void> setBool(String key, {required bool value}) async =>
      _values[key] = value;

  @override
  Future<double?> getDouble(String key) async => _get<double>(key);

  @override
  Future<void> setDouble(String key, double value) async =>
      _values[key] = value;

  @override
  Future<int?> getInt(String key) async => _get<int>(key);

  @override
  Future<void> setInt(String key, int value) async => _values[key] = value;

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _values[key];
    return value is List<String> ? List.of(value) : null;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _values[key] = List<String>.of(value);

  @override
  Future<bool> containsKey(String key) async => _values.containsKey(key);

  @override
  Future<void> remove(String key) async => _values.remove(key);
}
