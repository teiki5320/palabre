import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/app/app.dart';
import 'package:palabre/core/cache/cache_store.dart';
import 'package:palabre/core/prefs/prefs_provider.dart';
import 'package:palabre/features/quiz/quiz_models.dart';
import 'package:palabre/features/quiz/quiz_providers.dart';
import 'package:palabre/features/quiz/quiz_result_screen.dart';
import 'package:palabre/features/quiz/quiz_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;

/// Alpha d'accord partout, Bêta mitigé, Gamma sans position : le résultat
/// liste les trois dans l'ordre du moteur, sans rang, et dit « non
/// calculable » plutôt que d'inventer.
QuizBundle _quiz() {
  PartyPosition pp(int s, int o, Position p, [SourceType st = SourceType.documentPublic]) =>
      PartyPosition(id: s * 10 + o, statementId: s, orgId: o, position: p, sourceType: st);
  return QuizBundle(
    id: 1,
    titre: 'Test',
    version: 1,
    statements: const [
      Statement(id: 10, ordre: 1, texte: 's1'),
      Statement(id: 11, ordre: 2, texte: 's2'),
      Statement(id: 12, ordre: 3, texte: 's3'),
    ],
    parties: const [Party(id: 1, nom: 'Alpha'), Party(id: 2, nom: 'Bêta'), Party(id: 3, nom: 'Gamma')],
    positions: [
      pp(10, 1, Position.accord), pp(10, 2, Position.accord), pp(10, 3, Position.sansPosition, SourceType.aucune),
      pp(11, 1, Position.accord), pp(11, 2, Position.neutre), pp(11, 3, Position.sansPosition, SourceType.aucune),
      pp(12, 1, Position.accord), pp(12, 2, Position.desaccord), pp(12, 3, Position.sansPosition, SourceType.aucune),
    ],
  );
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('tous les partis, dans l\'ordre, sans rang', (tester) async {
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
    await cache.put('quiz:SN', {'quiz': _quiz().toJson()});
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs), cacheStoreProvider.overrideWithValue(cache)],
      child: const PalabreApp(),
    ));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(PalabreApp)));
    final session = container.read(quizSessionProvider.notifier);
    session.start(1);
    for (final id in [10, 11, 12]) {
      session.answer(id, Answer.accord);
    }
    await tester.tap(find.text('Testez-vous'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Votre dernier résultat'), 120, scrollable: find.descendant(of: find.byType(QuizTab), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Votre dernier résultat'));
    await tester.pumpAndSettle();

    expect(find.text('Tous les partis, du plus proche au plus éloigné'), findsOneWidget);
    expect(find.text('3 RÉPONSES · CALCULÉ SUR VOTRE TÉLÉPHONE'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
    expect(find.text('NON CALCULABLE'), findsOneWidget);
    final alpha = tester.getTopLeft(find.text('Alpha')).dy;
    final beta = tester.getTopLeft(find.text('Bêta')).dy;
    final gamma = tester.getTopLeft(find.text('Gamma')).dy;
    expect(alpha < beta && beta < gamma, isTrue);
    for (final rank in ['1er', '#1', '🥇', 'Gagnant']) {
      expect(find.textContaining(rank), findsNothing);
    }

    final scrollable = find.descendant(of: find.byType(QuizResultScreen), matching: find.byType(Scrollable)).first;
    await tester.scrollUntilVisible(find.text('Détail par affirmation'), 120, scrollable: scrollable);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Détail par affirmation'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('1. s1'), 200, scrollable: scrollable);
    expect(find.text('1. s1'), findsOneWidget);
  });
}
