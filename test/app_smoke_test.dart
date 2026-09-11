import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/app/app.dart';
import 'package:palabre/core/cache/cache_store.dart';
import 'package:palabre/core/prefs/prefs_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;

/// Sans serveur configuré ni cache : onboarding, puis onglet Question avec
/// le bandeau « serveur non configuré ». Le squelette tient debout.
void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('onboarding puis onglet question', (tester) async {
    SharedPreferences.setMockInitialValues({PrefKeys.locale: 'fr'});
    final prefs = await SharedPreferences.getInstance();
    final cache = MemoryCacheStore();
    await cache.put('country_config', {
      'countries': [{'code': 'SN', 'nom': 'Sénégal', 'fuseau': 'Africa/Dakar', 'langue': 'fr', 'actif': true}],
      'regions': [{'id': 1, 'country_code': 'SN', 'code': 'DK', 'nom': 'Dakar'}],
      'modules': [],
      'app_config': {},
    });

    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), cacheStoreProvider.overrideWithValue(cache)],
      child: const PalabreApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text("L'arbre à palabres"), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();
    expect(find.text('Pays'), findsOneWidget);
    await tester.tap(find.text('Commencer'));
    await tester.pumpAndSettle();

    expect(prefs.getBool(PrefKeys.onboardingDone), isTrue);
    // Sans serveur ni cache, l'onglet le dit plutôt que d'inventer.
    expect(find.textContaining('Serveur non configuré'), findsWidgets);
    expect(find.text('Réessayer'), findsOneWidget);

    // Les quatre onglets répondent.
    await tester.tap(find.text('Testez-vous'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    await tester.tap(find.text('Gouvernement'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Assemblée'));
    await tester.pumpAndSettle();
  });
}
