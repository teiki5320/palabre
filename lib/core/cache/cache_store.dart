import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// Abstraction du cache pour pouvoir substituer une version mémoire en test.
abstract class CacheStore {
  Future<Map<String, dynamic>?> get(String key);
  Future<void> put(String key, Map<String, dynamic> value);
  Future<void> clear();
}

/// Le cache ne doit jamais bloquer l'écran : si la base locale ne répond pas
/// dans le délai, on fait comme s'il n'y avait rien en cache.
class DriftCacheStore implements CacheStore {
  DriftCacheStore(this._db);
  final AppDatabase _db;

  static const timeout = Duration(seconds: 3);

  @override
  Future<Map<String, dynamic>?> get(String key) async {
    final CacheEntry? row;
    try {
      row = await _db.read(key).timeout(timeout);
    } catch (e) {
      debugPrint('Cache local indisponible en lecture ($key) : $e');
      return null;
    }
    if (row == null) return null;
    try {
      return jsonDecode(row.json) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> put(String key, Map<String, dynamic> value) async {
    try {
      await _db.write(key, jsonEncode(value)).timeout(timeout);
    } catch (e) {
      debugPrint('Cache local indisponible en écriture ($key) : $e');
    }
  }

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
