import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/fin_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contenu contenuDEssai() => Contenu.depuisChaines(
      cartes: '[]',
      personnages: '[]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}]',
      fins: '[{"id":"armee_bas","jauge":"armee","vers_le_haut":false,"titre":"Le palais est pris",'
          '"texte":"Les blindes sont entres a l aube.","image":"fins/coup.jpg"},'
          '{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
    );

const etatChute = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 50, armee: 0, caisses: 50, presse: 50),
  jour: 12,
);

/// Le conteneur est monté à la main : on prépare la session AVANT le premier
/// rendu, car on n appelle jamais un notifier pendant un build.
Future<ProviderContainer> montre(WidgetTester tester) async {
  final contenu = contenuDEssai();
  final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
  addTearDown(container.dispose);
  await container.read(contenuProvider.future);
  container.read(sessionProvider.notifier).reprend(etatChute, graine: 1);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: FinEcran()),
  ));
  await tester.pumpAndSettle();
  return container;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la fin montre son titre, son texte et les jours tenus', (tester) async {
    await montre(tester);
    expect(find.text('Le palais est pris'), findsOneWidget);
    expect(find.textContaining('blindes'), findsOneWidget);
    expect(find.textContaining('11 jours'), findsOneWidget);
  });

  testWidgets('reprendre ses fonctions vide la session', (tester) async {
    final container = await montre(tester);
    await tester.tap(find.text('Reprendre ses fonctions'));
    await tester.pumpAndSettle();
    expect(container.read(sessionProvider), isNull);
  });
}
