/// Persistent storage of simple values by key.
///
/// Getters return `null` when the key is missing or holds a value of another
/// type, so callers can fall back to a default instead of failing.
abstract interface class KeyValueStore {
  /// The string stored under [key], or `null`.
  Future<String?> getString(String key);

  /// Stores [value] under [key].
  Future<void> setString(String key, String value);

  /// The boolean stored under [key], or `null`.
  Future<bool?> getBool(String key);

  /// Stores [value] under [key].
  Future<void> setBool(String key, {required bool value});

  /// The double stored under [key], or `null`.
  Future<double?> getDouble(String key);

  /// Stores [value] under [key].
  Future<void> setDouble(String key, double value);

  /// The integer stored under [key], or `null`.
  Future<int?> getInt(String key);

  /// Stores [value] under [key].
  Future<void> setInt(String key, int value);

  /// The list of strings stored under [key], or `null`.
  Future<List<String>?> getStringList(String key);

  /// Stores [value] under [key].
  Future<void> setStringList(String key, List<String> value);

  /// Whether a value of any type is stored under [key].
  Future<bool> containsKey(String key);

  /// Removes the value stored under [key], if any.
  Future<void> remove(String key);
}
