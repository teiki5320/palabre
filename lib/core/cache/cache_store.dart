import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Abstraction du cache pour pouvoir substituer une version mémoire en test.
abstract class CacheStore {
  Future<Map<String, dynamic>?> get(String key);
  Future<void> put(String key, Map<String, dynamic> value);
  Future<void> clear();
}

class DriftCacheStore implements CacheStore {
  DriftCacheStore(this._db);
  final AppDatabase _db;

  @override
  Future<Map<String, dynamic>?> get(String key) async {
    final row = await _db.read(key);
    if (row == null) return null;
    try {
      return jsonDecode(row.json) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> put(String key, Map<String, dynamic> value) =>
      _db.write(key, jsonEncode(value));

  @override
  Future<void> clear() => _db.clear();
}

class MemoryCacheStore implements CacheStore {
  final Map<String, Map<String, dynamic>> _data = {};

  @override
  Future<Map<String, dynamic>?> get(String key) async => _data[key];

  @override
  Future<void> put(String key, Map<String, dynamic> value) async =>
      _data[key] = value;

  @override
  Future<void> clear() async => _data.clear();
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final cacheStoreProvider = Provider<CacheStore>(
  (ref) => DriftCacheStore(ref.watch(appDatabaseProvider)),
);
