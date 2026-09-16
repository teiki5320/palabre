import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/fin_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Une carte toujours jouable (aucune condition, répétable), pour que le
// second mandat reste en jeu au lieu de s'arrêter tout seul faute de carte.
Contenu contenuDEssai({String exploits = '', String parcoursSupplementaire = ''}) => Contenu.depuisChaines(
      cartes: '[{"id":"c1","personnage":"general","humeur":"neutre","texte":"Une phrase.",'
          '"gauche":{"libelle":"A","effets":{"armee":1}},'
          '"droite":{"libelle":"B","effets":{"armee":-1}},"repetable":true}]',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}'
          '$parcoursSupplementaire]',
      fins: '[{"id":"armee_bas","jauge":"armee","vers_le_haut":false,"titre":"Le palais est pris",'
          '"texte":"Les blindes sont entres a l aube.","image":"fins/coup.jpg"},'
          '{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
      exploits: exploits,
    );

/// Contenu avec un exploit gagnable dès la chute et un parcours qui se
/// débloque avec les jauges de [etatChute] (peuple et caisses à 50).
Contenu contenuAvecUnExploit() => contenuDEssai(
      exploits: '[{"id":"survivant","titre":"Survivant","description":"Tenir malgre la chute",'
          '"condition":{"jours_min":10}}]',
    );

Contenu contenuAvecDeuxExploits() => contenuDEssai(
      exploits: '[{"id":"survivant","titre":"Survivant","description":"Tenir malgre la chute",'
          '"condition":{"jours_min":10}},'
          '{"id":"gardien_des_caisses","titre":"Gardien des caisses","description":"Finir avec les caisses pleines",'
          '"condition":{"caisses_min":40}}]',
    );

Contenu contenuAvecParcoursDebloque() => contenuDEssai(
      parcoursSupplementaire: ',{"id":"artiste","nom":"L artiste engagee","titre":"Madame la Presidente",'
          '"femme":true,"depart":{"peuple":60,"armee":40,"caisses":40,"presse":60},'
          '"condition_deblocage":"Finir un mandat avec le peuple au-dessus de 40",'
          '"condition":{"peuple_min":40}}',
    );

const etatChute = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 50, armee: 0, caisses: 50, presse: 50),
  jour: 12,
);

final etatReelu = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 60, armee: 50, caisses: 50, presse: 60),
  jour: dureeMandat + 1,
);

final etatBattu = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 30, armee: 50, caisses: 50, presse: 30),
  jour: dureeMandat + 1,
);

/// Le conteneur est monté à la main : on prépare la session AVANT le premier
/// rendu, car on n appelle jamais un notifier pendant un build.
Future<ProviderContainer> montre(WidgetTester tester, {Contenu? contenu, EtatPartie etat = etatChute}) async {
  final c = contenu ?? contenuDEssai();
  final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => c)]);
  addTearDown(container.dispose);
  await container.read(contenuProvider.future);
  container.read(sessionProvider.notifier).reprend(etat, graine: 1);

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

  testWidgets('rien ne s affiche quand aucune nouveaute n a ete gagnee', (tester) async {
    await montre(tester);
    expect(find.text('Vous avez débloqué'), findsNothing);
  });

  testWidgets('un exploit gagne s affiche avec son titre et sa description', (tester) async {
    await montre(tester, contenu: contenuAvecUnExploit());
    expect(find.text('Vous avez débloqué'), findsOneWidget);
    expect(find.text('Survivant'), findsOneWidget);
    expect(find.textContaining('Tenir malgre la chute'), findsOneWidget);
  });

  testWidgets('deux exploits gagnes s affichent tous les deux', (tester) async {
    await montre(tester, contenu: contenuAvecDeuxExploits());
    expect(find.text('Survivant'), findsOneWidget);
    expect(find.textContaining('Tenir malgre la chute'), findsOneWidget);
    expect(find.text('Gardien des caisses'), findsOneWidget);
    expect(find.textContaining('caisses pleines'), findsOneWidget);
  });

  testWidgets('un parcours debloque s affiche avec son nom', (tester) async {
    await montre(tester, contenu: contenuAvecParcoursDebloque());
    expect(find.text('Vous avez débloqué'), findsOneWidget);
    expect(find.textContaining('L artiste engagee'), findsOneWidget);
  });

  testWidgets('le bouton de second mandat n apparait pas apres une chute', (tester) async {
    await montre(tester, etat: etatChute);
    expect(find.text('Continuer, deuxième mandat'), findsNothing);
  });

  testWidgets('le bouton de second mandat n apparait pas apres une election perdue', (tester) async {
    await montre(tester, etat: etatBattu);
    expect(find.text('Continuer, deuxième mandat'), findsNothing);
  });

  testWidgets('apres une reelection, le bouton continuer deuxieme mandat appelle mandatSuivant',
      (tester) async {
    final container = await montre(tester, etat: etatReelu);
    expect(find.text('Reprendre ses fonctions'), findsOneWidget);
    expect(find.text('Continuer, deuxième mandat'), findsOneWidget);

    await tester.tap(find.text('Continuer, deuxième mandat'));
    await tester.pumpAndSettle();

    final suite = container.read(sessionProvider);
    expect(suite, isNotNull);
    expect(suite!.terminee, isFalse);
    expect(suite.etat.jour, 1);
    expect(suite.etat.mandat, 2);
  });
}
