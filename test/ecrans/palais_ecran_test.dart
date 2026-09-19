import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/partie_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/ecrans/theme.dart';
import 'package:president/moteur/progression.dart';
import 'package:shared_preferences/shared_preferences.dart';


const _objets = '['
    '{"id":"ventilateur","piece":"bureau","nom":"Le ventilateur de plafond",'
    '"description":"Il tourne au-dessus du bureau.","prix":4,"natures":["decor"]},'
    '{"id":"coffre_fort","piece":"bureau","nom":"Le coffre-fort",'
    '"description":"Dix points de cote.","prix":14,"natures":["bonus"]},'
    '{"id":"jardinieres","piece":"balcon","nom":"Les jardinieres",'
    '"description":"Sur la rambarde.","prix":4,"natures":["decor"]}'
    ']';

Contenu _contenu() => Contenu.depuisChaines(
      cartes: '['
          '{"id":"c1","personnage":"general","humeur":"neutre","texte":"La solde a du retard.",'
          '"gauche":{"libelle":"Patientez","effets":{"armee":-10}},'
          '"droite":{"libelle":"On paie","effets":{"armee":10,"caisses":-10}}}'
          ']',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}]',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
      objets: _objets,
    );

Future<void> _ouvreLeTiroir(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.expand_less));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

Future<void> _ouvreLePalais(WidgetTester tester, {Progression? progression}) async {
  final contenu = _contenu();
  await tester.pumpWidget(ProviderScope(
    overrides: [
      contenuProvider.overrideWith((ref) => contenu),
      if (progression != null) progressionProvider.overrideWith((ref) => progression),
    ],
    child: MaterialApp(
      theme: theme(),
      home: Consumer(builder: (context, ref, _) {
        return TextButton(
          onPressed: () {
            ref.read(sessionProvider.notifier).demarre(
                  parcours: contenu.parcours.first,
                  nom: 'Awa',
                  graine: 1,
                );
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartieEcran()));
          },
          child: const Text('commencer'),
        );
      }),
    ),
  ));
  await tester.pump();
  await tester.tap(find.text('commencer'));
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Le palais'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('le palais s ouvre sur le bureau et annonce son état', (tester) async {
    await _ouvreLePalais(tester);
    expect(find.text('Le bureau'), findsWidgets);
    expect(find.text('Le bureau de travail'), findsOneWidget);
  });

  testWidgets('le bureau montre ses trois ouvertures, et aucune pastille', (tester) async {
    await _ouvreLePalais(tester);
    for (final nom in ['Le balcon', 'Le couloir', 'Le jardin']) {
      expect(find.text(nom), findsOneWidget, reason: 'l\'ouverture « $nom » manque');
    }
    // Les anciennes pastilles nommaient les pièces où l'on n'est pas ;
    // les ouvertures nomment ce qu'on voit.
    expect(find.text('La cour des voitures'), findsNothing);
    expect(find.text('La piscine'), findsNothing);
  });

  testWidgets('le bureau n a pas de demi-tour : on y est déjà', (tester) async {
    await _ouvreLePalais(tester);
    expect(find.text('Revenir au bureau'), findsNothing);
  });

  testWidgets('la baie vitrée mène au balcon, et le demi-tour ramène', (tester) async {
    await _ouvreLePalais(tester);
    expect(find.text('Le bureau de travail'), findsOneWidget);
    await tester.tap(find.text('Le balcon'));
    await tester.pumpAndSettle();
    expect(find.text("L'avenue ordinaire"), findsOneWidget);

    await tester.tap(find.text('Revenir au bureau'));
    await tester.pumpAndSettle();
    expect(find.text('Le bureau de travail'), findsOneWidget);
  });

  testWidgets('le catalogue est replié, et s ouvre d une main', (tester) async {
    await _ouvreLePalais(tester);
    expect(find.text('Le ventilateur de plafond'), findsNothing);
    expect(find.textContaining('à partir de 4'), findsOneWidget);
    await _ouvreLeTiroir(tester);
    expect(find.text('Le ventilateur de plafond'), findsOneWidget);
  });

  testWidgets('le bureau propose ses objets avec leur prix', (tester) async {
    await _ouvreLePalais(tester);
    await _ouvreLeTiroir(tester);
    expect(find.text('Le ventilateur de plafond'), findsOneWidget);
    expect(find.text('4'), findsWidgets);
    expect(find.text('Le coffre-fort'), findsOneWidget);
  });

  testWidgets('un objet déjà au palais est montré mais éteint', (tester) async {
    await _ouvreLePalais(
      tester,
      progression: Progression.neuve().copie(objets: {'ventilateur'}),
    );
    await _ouvreLeTiroir(tester);
    expect(find.text('Le ventilateur de plafond'), findsOneWidget);
    expect(find.text('Au palais'), findsOneWidget);
  });

  testWidgets('acheter un objet prend son prix sur les caisses', (tester) async {
    // Sans surcharge du fournisseur : l'objet doit vraiment faire l'aller
    // et retour par le disque, sinon le test ne prouve rien de l'achat.
    await _ouvreLePalais(tester);
    await _ouvreLeTiroir(tester);
    expect(find.text('50'), findsOneWidget); // les caisses de départ
    await tester.tap(find.text('Le ventilateur de plafond'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('46'), findsOneWidget);
    expect(find.text('Au palais'), findsOneWidget);
  });

  testWidgets('on revient à la journée par la flèche', (tester) async {
    await _ouvreLePalais(tester);
    await tester.tap(find.byTooltip('Retour à la journée'));
    await tester.pumpAndSettle();
    expect(find.text('JOUR 1'), findsOneWidget);
  });

  testWidgets('visiter le palais ne consomme pas un jour', (tester) async {
    await _ouvreLePalais(tester);
    await tester.tap(find.text('Le jardin'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Retour à la journée'));
    await tester.pumpAndSettle();
    expect(find.text('JOUR 1'), findsOneWidget);
  });
}
