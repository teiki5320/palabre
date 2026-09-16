import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/accueil.dart';
import 'package:president/ecrans/collection_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/moteur/progression.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Contenu d'essai avec deux exploits, trois fins (une jauge, une election)
/// et un parcours verrouille que seule la progression peut ouvrir.
Contenu contenuDEssai() => Contenu.depuisChaines(
      cartes: '[{"id":"c1","personnage":"general","humeur":"neutre","texte":"t",'
          '"gauche":{"libelle":"A","effets":{}},"droite":{"libelle":"B","effets":{}}}]',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '['
          '{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President","femme":false,'
          '"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}},'
          '{"id":"putschiste","nom":"L ancien putschiste","titre":"Monsieur le President","femme":false,'
          '"depart":{"peuple":35,"armee":80,"caisses":50,"presse":30},'
          '"condition_deblocage":"Se faire renverser par l armee",'
          '"condition":{"fin":"armee_bas"}}'
          ']',
      fins: '[{"id":"armee_bas","jauge":"armee","vers_le_haut":false,"titre":"Le palais est pris",'
          '"texte":"t","image":"i"},'
          '{"id":"peuple_haut","jauge":"peuple","vers_le_haut":true,"titre":"L homme providentiel",'
          '"texte":"t","image":"i"},'
          '{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"}]',
      exploits: '[{"id":"marathon","titre":"Le marathon du pouvoir","description":"Tenir jusqu au bout",'
          '"condition":{"jours_min":30}},'
          '{"id":"caisses_pleines","titre":"Les coffres pleins","description":"Finir avec les caisses hautes",'
          '"condition":{"caisses_min":80}}]',
    );

Progression progressionDEssai() => const Progression(
      parcoursDebloques: {},
      exploits: {'marathon'},
      finsDecouvertes: {'armee_bas'},
      mandatsJoues: 1,
      meilleurJour: 30,
    );

Future<void> montreCollection(WidgetTester tester, {Progression? progression}) async {
  final contenu = contenuDEssai();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      contenuProvider.overrideWith((ref) => contenu),
      progressionProvider.overrideWith((ref) => progression ?? progressionDEssai()),
    ],
    child: const MaterialApp(home: CollectionEcran()),
  ));
  await tester.pumpAndSettle();
}

Future<void> montreAccueil(WidgetTester tester, {Progression? progression}) async {
  tester.view.physicalSize = const Size(1000, 2200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final contenu = contenuDEssai();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      contenuProvider.overrideWith((ref) => contenu),
      if (progression != null) progressionProvider.overrideWith((ref) => progression),
    ],
    child: const MaterialApp(home: AccueilEcran()),
  ));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('CollectionEcran', () {
    testWidgets('un exploit obtenu affiche son titre et sa description', (tester) async {
      await montreCollection(tester);
      expect(find.text('Le marathon du pouvoir'), findsOneWidget);
      expect(find.textContaining('Tenir jusqu au bout'), findsOneWidget);
    });

    testWidgets('un exploit non obtenu n affiche pas son titre mais garde sa description en indice',
        (tester) async {
      await montreCollection(tester);
      expect(find.text('Les coffres pleins'), findsNothing);
      expect(find.textContaining('Finir avec les caisses hautes'), findsOneWidget);
    });

    testWidgets('une fin decouverte affiche son titre', (tester) async {
      await montreCollection(tester);
      expect(find.text('Le palais est pris'), findsOneWidget);
    });

    testWidgets('une fin inconnue liee a une jauge ne montre pas son titre mais nomme la jauge',
        (tester) async {
      await montreCollection(tester);
      expect(find.text('L homme providentiel'), findsNothing);
      expect(find.textContaining('Fin inconnue'), findsWidgets);
      expect(find.textContaining('Peuple'), findsOneWidget);
    });

    testWidgets('une fin d election inconnue nomme les urnes', (tester) async {
      await montreCollection(tester);
      expect(find.text('Reelu'), findsNothing);
      expect(find.textContaining('les urnes'), findsOneWidget);
    });

    testWidgets('le comptage des exploits et des fins est juste', (tester) async {
      await montreCollection(tester);
      expect(find.textContaining('1 exploit'), findsOneWidget);
      expect(find.textContaining('sur 2'), findsWidgets);
      expect(find.textContaining('1 fin'), findsOneWidget);
      expect(find.textContaining('sur 3'), findsWidgets);
    });
  });

  group('Accueil et deblocage par la progression', () {
    testWidgets('un parcours verrouille reste verrouille sans progression', (tester) async {
      await montreAccueil(tester);
      await tester.tap(find.byKey(const ValueKey('vignette-putschiste')));
      await tester.pumpAndSettle();
      expect(find.text('Se faire renverser par l armee'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Awa');
      await tester.pump();
      final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
      expect(bouton.onPressed, isNull);
    });

    testWidgets('un parcours debloque par la progression est selectionnable et sans indice ni cadenas',
        (tester) async {
      final progression = const Progression(
        parcoursDebloques: {'putschiste'},
        exploits: {},
        finsDecouvertes: {},
        mandatsJoues: 1,
        meilleurJour: 12,
      );
      await montreAccueil(tester, progression: progression);
      expect(find.text('Se faire renverser par l armee'), findsNothing);
      expect(find.byIcon(Icons.lock_outline), findsNothing);

      await tester.tap(find.byKey(const ValueKey('vignette-putschiste')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Awa');
      await tester.pump();
      final bouton = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Prendre mes fonctions'));
      expect(bouton.onPressed, isNotNull);
    });

    testWidgets('un bouton discret mene a la collection', (tester) async {
      await montreAccueil(tester);
      expect(find.byType(IconButton), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.byType(CollectionEcran), findsOneWidget);
    });
  });
}
