import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/app/app.dart';
import 'package:palabre/core/cache/cache_store.dart';
import 'package:palabre/core/prefs/prefs_provider.dart';
import 'package:palabre/features/poll/poll_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;

Poll _poll({required int id, required DateTime ouverture, required DateTime fermeture, required String question}) => Poll(
      id: id,
      countryCode: 'SN',
      semaine: DateTime.utc(2026, 9, 14),
      question: question,
      contexte: 'Un contexte court.',
      sources: const [PollSource(titre: 'Primature', url: 'https://example.org')],
      ouverture: ouverture,
      fermeture: fermeture,
      options: const [
        PollOption(id: 1, ordre: 1, libelle: 'Oui', neutre: false),
        PollOption(id: 2, ordre: 2, libelle: 'Non', neutre: false),
        PollOption(id: 3, ordre: 3, libelle: 'Sans avis', neutre: true),
      ],
      repondants: 42,
      suspect: false,
      resultatFinal: false,
    );

/// Depuis le cache seul : question programmée (pas de bouton Voter), contexte
/// replié avec le compte de sources, archive listée.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('question programmée et archive', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({PrefKeys.locale: 'fr', PrefKeys.onboardingDone: true, PrefKeys.country: 'SN'});
    final prefs = await SharedPreferences.getInstance();
    final cache = MemoryCacheStore();
    await cache.put('country_config', {
      'countries': [{'code': 'SN', 'nom': 'Sénégal', 'fuseau': 'Africa/Dakar', 'langue': 'fr', 'actif': true}],
      'regions': [],
      'modules': [],
      'app_config': {},
    });
    final now = DateTime.now().toUtc();
    final feed = PollFeed(
      current: _poll(id: 1, ouverture: now.add(const Duration(days: 1)), fermeture: now.add(const Duration(days: 7)), question: 'Question à venir ?'),
      archive: [_poll(id: 2, ouverture: now.subtract(const Duration(days: 14)), fermeture: now.subtract(const Duration(days: 8)), question: 'Question passée ?')],
    );
    await cache.put('poll_feed:SN', feed.toJson());

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), cacheStoreProvider.overrideWithValue(cache)],
      child: const PalabreApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('SEMAINE DU'), findsWidgets);
    expect(find.text('Question à venir ?'), findsOneWidget);
    expect(find.text('Voter'), findsNothing);
    expect(find.text('Contexte · 1 source'), findsOneWidget);
    CrossFadeState contextState() => tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade).first).crossFadeState;
    expect(contextState(), CrossFadeState.showFirst);
    await tester.ensureVisible(find.text('Contexte · 1 source'));
    await tester.tap(find.text('Contexte · 1 source'));
    await tester.pumpAndSettle();
    expect(contextState(), CrossFadeState.showSecond);
    expect(find.text('Un contexte court.'), findsOneWidget);
    await tester.ensureVisible(find.text('Semaines précédentes'));
    await tester.tap(find.text('Semaines précédentes'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Question passée ?'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Question passée ?'), findsOneWidget);
    expect(find.text('Affiner les résultats'), findsNothing);
  });
}
