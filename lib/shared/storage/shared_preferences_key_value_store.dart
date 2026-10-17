import 'package:key_value_store/key_value_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A [KeyValueStore] on the device's shared preferences.
///
/// Uses the legacy `SharedPreferences` API on purpose: on Android the newer
/// `SharedPreferencesAsync` defaults to a different backend, which would hide
/// the settings and savegames stored by earlier versions (design D8).
class SharedPreferencesKeyValueStore implements KeyValueStore {
  new({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  @override
  Future<String?> getString(String key) async {
    final value = (await _preferences()).get(key);
    return value is String ? value : null;
  }

  @override
  Future<void> setString(String key, String value) async {
    await (await _preferences()).setString(key, value);
  }

  @override
  Future<bool?> getBool(String key) async {
    final value = (await _preferences()).get(key);
    return value is bool ? value : null;
  }

  @override
  Future<void> setBool(String key, {required bool value}) async {
    await (await _preferences()).setBool(key, value);
  }

  @override
  Future<double?> getDouble(String key) async {
    final value = (await _preferences()).get(key);
    return value is double ? value : null;
  }

  @override
  Future<void> setDouble(String key, double value) async {
    await (await _preferences()).setDouble(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    final value = (await _preferences()).get(key);
    return value is int ? value : null;
  }

  @override
  Future<void> setInt(String key, int value) async {
    await (await _preferences()).setInt(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = (await _preferences()).get(key);
    return value is List ? value.whereType<String>().toList() : null;
  }

  @override
  Future<void> setStringList(String key, List<String> value) async {
    await (await _preferences()).setStringList(key, value);
  }

  @override
  Future<bool> containsKey(String key) async =>
      (await _preferences()).containsKey(key);

  @override
  Future<void> remove(String key) async {
    await (await _preferences()).remove(key);
  }
}
