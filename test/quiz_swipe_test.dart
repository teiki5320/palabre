import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:palabre/app/app.dart';
import 'package:palabre/core/cache/cache_store.dart';
import 'package:palabre/core/prefs/prefs_provider.dart';
import 'package:palabre/features/quiz/quiz_models.dart';
import 'package:palabre/features/quiz/quiz_providers.dart';
import 'package:palabre/features/quiz/quiz_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_10y.dart' as tzdata;

QuizBundle _quiz(int n) => QuizBundle(
      id: 1,
      titre: 'Test',
      version: 1,
      statements: [for (var i = 0; i < n; i++) Statement(id: 10 + i, ordre: i + 1, texte: 'Affirmation ${i + 1}', theme: 'Thème')],
      parties: const [Party(id: 1, nom: 'Alpha'), Party(id: 2, nom: 'Bêta')],
      positions: [
        for (var i = 0; i < n; i++) ...[
          PartyPosition(id: (10 + i) * 10 + 1, statementId: 10 + i, orgId: 1, position: Position.accord, sourceType: SourceType.documentPublic),
          PartyPosition(id: (10 + i) * 10 + 2, statementId: 10 + i, orgId: 2, position: Position.desaccord, sourceType: SourceType.documentPublic),
        ],
      ],
    );

Future<ProviderContainer> _openQuiz(WidgetTester tester, QuizBundle quiz) async {
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
  await cache.put('quiz:SN', {'quiz': quiz.toJson()});
  await tester.pumpWidget(ProviderScope(
    overrides: [sharedPrefsProvider.overrideWithValue(prefs), cacheStoreProvider.overrideWithValue(cache)],
    child: const PalabreApp(),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Testez-vous'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(find.text('Commencer'), 120, scrollable: find.descendant(of: find.byType(QuizTab), matching: find.byType(Scrollable)).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Commencer'));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(PalabreApp)));
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('balayage à droite, à gauche, vers le haut, passer', (tester) async {
    final container = await _openQuiz(tester, _quiz(3));
    expect(find.byKey(const ValueKey('statement-card-10')), findsOneWidget);
    expect(find.text('1/3', findRichText: true), findsOneWidget);

    // Un balayage court revient en place.
    await tester.drag(find.byKey(const ValueKey('statement-card-10')), const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('statement-card-10')), findsOneWidget);
    expect(container.read(quizSessionProvider).answers, isEmpty);

    await tester.drag(find.byKey(const ValueKey('statement-card-10')), const Offset(320, 0));
    await tester.pumpAndSettle();
    expect(container.read(quizSessionProvider).answers[10], Answer.accord);
    expect(find.byKey(const ValueKey('statement-card-11')), findsOneWidget);
    expect(find.text('2/3', findRichText: true), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey('statement-card-11')), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(container.read(quizSessionProvider).answers[11], Answer.desaccord);
    expect(find.byKey(const ValueKey('statement-card-12')), findsOneWidget);

    await tester.tap(find.text('Passer cette affirmation'));
    await tester.pumpAndSettle();
    expect(container.read(quizSessionProvider).answers[12], Answer.passer);
    expect(find.byKey(const ValueKey('statement-card-12')), findsNothing);
  });

  testWidgets('balayage vers le haut = neutre', (tester) async {
    final container = await _openQuiz(tester, _quiz(2));
    await tester.drag(find.byKey(const ValueKey('statement-card-10')), const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(container.read(quizSessionProvider).answers[10], Answer.neutre);
    expect(find.byKey(const ValueKey('statement-card-11')), findsOneWidget);
  });

  testWidgets("l'interrupteur « important » se bloque à cinq", (tester) async {
    final container = await _openQuiz(tester, _quiz(6));
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const ValueKey('answer-important')));
      await tester.pumpAndSettle();
      await tester.drag(find.byKey(ValueKey('statement-card-${10 + i}')), const Offset(320, 0));
      await tester.pumpAndSettle();
    }
    expect(container.read(quizSessionProvider).important.length, 5);
    await tester.tap(find.byKey(const ValueKey('answer-important')));
    await tester.pumpAndSettle();
    expect(container.read(quizSessionProvider).important.length, 5);
    expect(find.text('Vous pouvez marquer 5 affirmations au maximum.'), findsOneWidget);
  });
}
