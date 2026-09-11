import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cache/cache_store.dart';

/// Chargement « cache d'abord, réseau ensuite » :
///  - s'il existe une copie locale, on l'affiche tout de suite (premier
///    rendu sous la seconde) et on rafraîchit en arrière-plan ;
///  - sinon on charge, on met en cache, on affiche ;
///  - si le réseau échoue et qu'un cache existe, on garde le cache et on
///    signale le mode hors-ligne.
abstract class CachedNotifier<T> extends AsyncNotifier<T> {
  String get cacheKey;
  Future<T> fetchRemote();
  T decode(Map<String, dynamic> json);
  Map<String, dynamic> encode(T value);

  bool _offline = false;
  bool get offline => _offline;

  @override
  Future<T> build() async {
    final store = ref.watch(cacheStoreProvider);
    final cached = await store.get(cacheKey);
    if (cached != null) {
      T? value;
      try {
        value = decode(cached);
      } catch (e) {
        debugPrint('Cache illisible pour $cacheKey : $e');
      }
      if (value != null) {
        unawaited(Future.microtask(refresh));
        return value;
      }
    }
    return _fetchAndStore(store);
  }

  /// Au-delà, on préfère dire « impossible de charger » que tourner à vide.
  static const remoteTimeout = Duration(seconds: 20);

  Future<T> _fetchAndStore(CacheStore store) async {
    final value = await fetchRemote().timeout(remoteTimeout);
    _offline = false;
    try {
      await store.put(cacheKey, encode(value));
    } catch (e) {
      debugPrint('Écriture cache impossible pour $cacheKey : $e');
    }
    return value;
  }

  Future<void> refresh() async {
    final store = ref.read(cacheStoreProvider);
    try {
      final value = await _fetchAndStore(store);
      state = AsyncData(value);
    } catch (e, st) {
      _offline = true;
      if (!state.hasValue) state = AsyncError(e, st);
      // sinon on garde la valeur du cache, marquée hors-ligne
      ref.notifyListeners();
    }
  }
}

/// Erreur levée quand aucun serveur n'est configuré et qu'aucun cache n'existe.
class NotConfiguredException implements Exception {
  const NotConfiguredException();
  @override
  String toString() => 'Supabase non configuré';
}
