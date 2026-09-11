import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

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
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'palabre_cache'));

  @override
  int get schemaVersion => 1;

  Future<CacheEntry?> read(String key) =>
      (select(cacheEntries)..where((t) => t.key.equals(key))).getSingleOrNull();

  Future<void> write(String key, String json) => into(cacheEntries).insertOnConflictUpdate(
        CacheEntriesCompanion.insert(key: key, json: json, maj: DateTime.now()),
      );

  Future<void> clear() => delete(cacheEntries).go();
}
