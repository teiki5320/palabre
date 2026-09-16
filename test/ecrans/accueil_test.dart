import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/accueil.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/progression.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/sauvegarde/sauvegarde.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contenu contenuDEssai() => Contenu.depuisChaines(
      cartes: '[{"id":"c1","personnage":"general","humeur":"neutre","texte":"La solde a du retard.",'
          '"gauche":{"libelle":"Patientez","effets":{"armee":-10}},'
          '"droite":{"libelle":"On paie","effets":{"armee":10}}}]',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '['
          '{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
          '"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}},'
          '{"id":"professeure","nom":"La professeure d universite","titre":"Madame la Presidente","femme":true,'
          '"depart":{"peuple":55,"armee":40,"caisses":45,"presse":65}},'
          '{"id":"putschiste","nom":"L ancien putschiste","titre":"Monsieur le President","femme":false,'
          '"depart":{"peuple":35,"armee":80,"caisses":50,"presse":30},'
          '"condition_deblocage":"Se faire renverser par l armee"}'
          ']',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
    );

Future<void> montre(WidgetTester tester) async {
  // Un écran assez grand pour que les quatre parcours tiennent sans défilement :
  // la liste ne construit que ce qui est visible, et les tests portent sur le
  // dernier parcours, celui qui est verrouillé.
  tester.view.physicalSize = const Size(1000, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final contenu = contenuDEssai();
  await tester.pumpWidget(ProviderScope(
    overrides: [contenuProvider.overrideWith((ref) => contenu)],
    child: const MaterialApp(home: AccueilEcran()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('les parcours ouverts et verrouilles sont distingues', (tester) async {
    await montre(tester);
    expect(find.text('L ancien general'), findsOneWidget);
    expect(find.text('La professeure d universite'), findsOneWidget);
    expect(find.text('Se faire renverser par l armee'), findsOneWidget);
  });

  testWidgets('le bouton reste inactif sans nom ni parcours', (tester) async {
    await montre(tester);
    final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
    expect(bouton.onPressed, isNull);
  });

  testWidgets('un parcours verrouille ne peut pas etre choisi', (tester) async {
    await montre(tester);
    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.tap(find.text('L ancien putschiste'));
    await tester.pump();
    final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
    expect(bouton.onPressed, isNull);
  });

  testWidgets('choisir un parcours et un nom active le bouton', (tester) async {
    await montre(tester);
    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.tap(find.text('La professeure d universite'));
    await tester.pump();
    final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
    expect(bouton.onPressed, isNotNull);
  });

  testWidgets('une sauvegarde presente affiche le bouton reprendre', (tester) async {
    final etat = EtatPartie(parcours: 'general_parcours', nomJoueur: 'Awa', jauges: Jauges.milieu, jour: 12);
    SharedPreferences.setMockInitialValues({'partie_en_cours': jsonEncode(versJson(etat))});
    await montre(tester);
    expect(find.text('Reprendre le jour 12'), findsOneWidget);
  });

  testWidgets('sans sauvegarde le bouton reprendre n apparait pas', (tester) async {
    await montre(tester);
    expect(find.textContaining('Reprendre le jour'), findsNothing);
  });

  testWidgets('un parcours debloque ne s affiche jamais verrouille, meme le temps d une image',
      (tester) async {
    // Sur l appareil, lire la progression passe par le stockage : elle arrive
    // toujours apres la premiere image. Dessiner les parcours des que le
    // contenu est la montrerait un instant comme verrouille un parcours deja
    // gagne. Le delai ci-dessous reproduit cette attente, que le stockage
    // simule des tests ne produit pas.
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final contenu = contenuDEssai();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        contenuProvider.overrideWith((ref) => contenu),
        progressionProvider.overrideWith((ref) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return Progression.neuve().copie(parcoursDebloques: {'putschiste'});
        }),
      ],
      child: const MaterialApp(home: AccueilEcran()),
    ));

    // Premiere image : le contenu est pret, la progression non. Aucun parcours
    // n est montre, surtout pas avec sa mention de deblocage.
    await tester.pump();
    expect(find.text('L ancien putschiste'), findsNothing);
    expect(find.text('Se faire renverser par l armee'), findsNothing);

    // Une fois la progression lue, le parcours est jouable et sans mention.
    await tester.pumpAndSettle();
    expect(find.text('Se faire renverser par l armee'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Awa');
    await tester.tap(find.text('L ancien putschiste'));
    await tester.pump();
    final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
    expect(bouton.onPressed, isNotNull);
  });
}
