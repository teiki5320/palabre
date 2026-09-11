import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Cache clé → JSON. La question en cours, l'archive, le quiz, le
/// gouvernement et l'assemblée doivent rester consultables hors-ligne.
class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();
  DateTimeColumn get maj => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [CacheEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// Fichier SQLite dans le dossier de support de l'app, ouvert dans
  /// l'isolate principal : le cache est petit, et une ouverture qui échoue
  /// doit lever une erreur visible plutôt que rester en attente.
  static LazyDatabase _open() => LazyDatabase(() async {
        final dir = await getApplicationSupportDirectory();
        return NativeDatabase(File('${dir.path}/palabre_cache.sqlite'));
      });

  @override
  int get schemaVersion => 1;

  Future<CacheEntry?> read(String key) =>
      (select(cacheEntries)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<void> write(String key, String json) => into(cacheEntries).insertOnConflictUpdate(
        CacheEntriesCompanion.insert(key: key, json: json, maj: DateTime.now()),
      );

  Future<void> clear() => delete(cacheEntries).go();
}
