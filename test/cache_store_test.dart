import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/core/cache/cache_store.dart';
import 'package:palabre/core/cache/database.dart';

void main() {
  test('le cache Drift écrit, relit et écrase une clé', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final store = DriftCacheStore(db);
    expect(await store.get('x'), isNull);
    await store.put('x', {'a': 1});
    expect(await store.get('x'), {'a': 1});
    await store.put('x', {'a': 2, 'b': [1, 2]});
    expect(await store.get('x'), {'a': 2, 'b': [1, 2]});
    await store.clear();
    expect(await store.get('x'), isNull);
    await db.close();
  });
}
