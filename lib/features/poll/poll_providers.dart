import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_store.dart';
import '../../core/country/country_providers.dart';
import '../../core/net/cached_notifier.dart';
import '../../core/supabase/supabase_providers.dart';
import 'poll_models.dart';

/// Question de la semaine + archive, par pays. Cache d'abord, réseau ensuite.
class PollFeedNotifier extends CachedNotifier<PollFeed> {
  PollFeedNotifier(this.countryCode);
  final String countryCode;

  @override
  String get cacheKey => 'poll_feed:$countryCode';

  @override
  Future<PollFeed> fetchRemote() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) throw const NotConfiguredException();
    final rows = await client
        .from('poll_public')
        .select()
        .eq('country_code', countryCode)
        .order('semaine', ascending: false)
        .limit(60);
    final polls = rows.map(Poll.fromJson).toList();
    final now = DateTime.now().toUtc();
    // La question courante : ouverte, sinon la prochaine programmée.
    Poll? current;
    for (final p in polls) {
      if (p.statusAt(now) == PollStatus.ouvert) {
        current = p;
        break;
      }
    }
    if (current == null) {
      final upcoming = polls.where((p) => p.statusAt(now) == PollStatus.programme).toList()
        ..sort((a, b) => a.ouverture.compareTo(b.ouverture));
      if (upcoming.isNotEmpty) current = upcoming.first;
    }
    final archive = polls.where((p) => p.statusAt(now) == PollStatus.ferme).toList();
    return PollFeed(current: current, archive: archive);
  }

  @override
  PollFeed decode(Map<String, dynamic> json) => PollFeed.fromJson(json);

  @override
  Map<String, dynamic> encode(PollFeed value) => value.toJson();
}

final pollFeedProvider = AsyncNotifierProvider.family<PollFeedNotifier, PollFeed, String>(PollFeedNotifier.new);

/// Le flux du pays courant.
final currentPollFeedProvider = Provider<AsyncValue<PollFeed>>((ref) {
  final code = ref.watch(selectedCountryProvider);
  return ref.watch(pollFeedProvider(code));
});

/// Mon vote sur un sondage (id d'option), null si aucun. Conservé en cache
/// pour rester visible hors-ligne.
class MyVoteNotifier extends AsyncNotifier<int?> {
  MyVoteNotifier(this.pollId);
  final int pollId;

  String get _key => 'my_vote:$pollId';

  @override
  Future<int?> build() async {
    final store = ref.watch(cacheStoreProvider);
    final cached = await store.get(_key);
    if (cached != null && cached['option_id'] != null) return (cached['option_id'] as num).toInt();
    final client = ref.read(supabaseClientProvider);
    if (client == null || client.auth.currentUser == null) return null;
    try {
      final v = await client.rpc('mon_vote', params: {'p_poll_id': pollId});
      final id = v == null ? null : (v as num).toInt();
      if (id != null) await store.put(_key, {'option_id': id});
      return id;
    } catch (_) {
      return null;
    }
  }

  Future<void> recordLocal(int optionId) async {
    await ref.read(cacheStoreProvider).put(_key, {'option_id': optionId});
    state = AsyncData(optionId);
  }
}

final myVoteProvider = AsyncNotifierProvider.family<MyVoteNotifier, int?, int>(MyVoteNotifier.new);

/// Résultats d'un sondage : null tant qu'on n'a pas voté (le serveur refuse).
class PollResultsNotifier extends AsyncNotifier<PollResults?> {
  PollResultsNotifier(this.pollId);
  final int pollId;

  String get _key => 'poll_results:$pollId';

  @override
  Future<PollResults?> build() async {
    final store = ref.watch(cacheStoreProvider);
    final cached = await store.get(_key);
    final cachedValue = cached == null ? null : PollResults.fromJson(cached);
    // Résultats définitifs en cache : inutile de recharger.
    if (cachedValue != null && cachedValue.isFinal) return cachedValue;
    try {
      final fresh = await _fetch();
      if (fresh != null) await store.put(_key, fresh.toJson());
      return fresh ?? cachedValue;
    } catch (_) {
      return cachedValue;
    }
  }

  Future<PollResults?> _fetch() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) throw const NotConfiguredException();
    final json = await client.rpc('poll_resultats', params: {'p_poll_id': pollId});
    if (json == null) return null;
    return PollResults.fromJson((json as Map).cast<String, dynamic>());
  }

  Future<void> refresh() async {
    try {
      final fresh = await _fetch();
      if (fresh != null) {
        await ref.read(cacheStoreProvider).put(_key, fresh.toJson());
        state = AsyncData(fresh);
      }
    } catch (_) {}
  }

  void set(PollResults r) {
    ref.read(cacheStoreProvider).put(_key, r.toJson());
    state = AsyncData(r);
  }
}

final pollResultsProvider = AsyncNotifierProvider.family<PollResultsNotifier, PollResults?, int>(PollResultsNotifier.new);

/// Voter : un appel RPC, définitif.
class VoteAction {
  VoteAction(this.ref);
  final Ref ref;

  Future<void> vote(Poll poll, int optionId) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) throw const NotConfiguredException();
    final json = await client.rpc('voter', params: {'p_poll_id': poll.id, 'p_option_id': optionId});
    await ref.read(myVoteProvider(poll.id).notifier).recordLocal(optionId);
    if (json != null) {
      ref.read(pollResultsProvider(poll.id).notifier).set(PollResults.fromJson((json as Map).cast<String, dynamic>()));
    } else {
      ref.invalidate(pollResultsProvider(poll.id));
    }
  }
}

final voteActionProvider = Provider<VoteAction>(VoteAction.new);
