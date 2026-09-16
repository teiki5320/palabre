import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/partie_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/ecrans/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contenu contenuDEssai() => Contenu.depuisChaines(
      cartes: '['
          '{"id":"c1","personnage":"general","humeur":"neutre","texte":"{nom}, la solde a du retard.",'
          '"gauche":{"libelle":"Patientez","effets":{"armee":-10}},'
          '"droite":{"libelle":"On paie","effets":{"armee":10,"caisses":-10}}},'
          '{"id":"c2","personnage":"general","humeur":"neutre","texte":"Les casernes murmurent.",'
          '"gauche":{"libelle":"Ignorer","effets":{"armee":-5}},'
          '"droite":{"libelle":"Ecouter","effets":{"armee":5}}}'
          ']',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}]',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
    );

Future<void> lance(WidgetTester tester) async {
  final contenu = contenuDEssai();
  await tester.pumpWidget(ProviderScope(
    overrides: [contenuProvider.overrideWith((ref) => contenu)],
    child: MaterialApp(
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
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la partie affiche le jour, les jauges et une carte', (tester) async {
    await lance(tester);
    expect(find.text('JOUR 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('jauge_armee')), findsOneWidget);
    expect(find.textContaining('solde'), findsOneWidget);
  });

  testWidgets('repondre avance au jour suivant et change de carte', (tester) async {
    await lance(tester);
    await tester.drag(find.textContaining('solde'), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('JOUR 2'), findsOneWidget);
    expect(find.textContaining('casernes'), findsOneWidget);
  });

  testWidgets('le nom du joueur remplace le gabarit', (tester) async {
    await lance(tester);
    expect(find.textContaining('Awa'), findsWidgets);
  });

  /// La hauteur de la barre de remplissage d'une jauge : 6 au repos, 8 quand
  /// la reponse pressentie la touche, 10 quand elle l aggrave en zone mortelle.
  double hauteurBarre(WidgetTester tester, String jauge) => tester
      .widget<AnimatedContainer>(find.byKey(ValueKey('barre_$jauge')))
      .constraints!
      .maxHeight;

  testWidgets('pencher a droite allume les jauges de cette reponse, pas les autres', (tester) async {
    await lance(tester);
    final geste = await tester.startGesture(tester.getCenter(find.textContaining('solde')));

    // La carte fait la largeur de l ecran moins les marges ; 120 depasse
    // largement le seuil d intention, qui est a 8 %.
    await geste.moveBy(const Offset(120, 0));
    await tester.pump();

    // « On paie » : +10 a l armee, −10 aux caisses. Le peuple et la presse
    // ne bougent pas.
    expect(hauteurBarre(tester, 'armee'), 8);
    expect(hauteurBarre(tester, 'caisses'), 8);
    expect(hauteurBarre(tester, 'peuple'), 6);
    expect(find.text('+10'), findsOneWidget);
    expect(find.text('\u221210'), findsOneWidget);

    await geste.up();
    await tester.pumpAndSettle();
  });

  testWidgets('un mouvement sous le seuil d intention ne montre aucun delta', (tester) async {
    await lance(tester);
    final geste = await tester.startGesture(tester.getCenter(find.textContaining('solde')));
    await geste.moveBy(const Offset(10, 0));
    await tester.pump();

    expect(hauteurBarre(tester, 'armee'), 6);
    // Le delta garde sa place mais reste invisible : rien ne doit sauter.
    final opacite = tester.widget<AnimatedOpacity>(
      find.descendant(of: find.byKey(const ValueKey('jauge_armee')), matching: find.byType(AnimatedOpacity)),
    );
    expect(opacite.opacity, 0);

    await geste.up();
    await tester.pumpAndSettle();
  });

  testWidgets('les deux reponses sont rappelees sous la carte', (tester) async {
    await lance(tester);
    expect(find.text('PATIENTEZ'), findsOneWidget);
    expect(find.text('ON PAIE'), findsOneWidget);
  });

  testWidgets('l echeance du mandat est annoncee a cote du jour', (tester) async {
    await lance(tester);
    expect(find.text('élection au jour 30'), findsOneWidget);
  });

  testWidgets('une jauge au bord du gouffre est signalee sans chiffre', (tester) async {
    // Meme contenu, mais l armee part a 12 : en dessous de 15, la jauge est
    // mortelle et doit se signaler d elle-meme, au repos.
    final contenu = Contenu.depuisChaines(
      cartes: '['
          '{"id":"c1","personnage":"general","humeur":"neutre","texte":"La solde a du retard.",'
          '"gauche":{"libelle":"Patientez","effets":{"armee":-10}},'
          '"droite":{"libelle":"On paie","effets":{"armee":10,"caisses":-10}}}'
          ']',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":50,"armee":12,"caisses":50,"presse":50}}]',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [contenuProvider.overrideWith((ref) => contenu)],
      child: MaterialApp(
        home: Consumer(builder: (context, ref, _) {
          return TextButton(
            onPressed: () {
              ref.read(sessionProvider.notifier).demarre(parcours: contenu.parcours.first, nom: 'Awa', graine: 1);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PartieEcran()));
            },
            child: const Text('commencer'),
          );
        }),
      ),
    ));
    await tester.pump();
    await tester.tap(find.text('commencer'));
    // Pas de pumpAndSettle : la pulsation de l alerte ne s arrete jamais.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final armee = tester.widget<AnimatedContainer>(find.byKey(const ValueKey('barre_armee')));
    final peuple = tester.widget<AnimatedContainer>(find.byKey(const ValueKey('barre_peuple')));
    Color remplissage(AnimatedContainer c) => (c.decoration! as BoxDecoration).color!;

    // L armee bat en or (la teinte est celle de l or, seule l opacite
    // respire), le peuple reste creme.
    expect(remplissage(armee).r, Couleurs.or.r);
    expect(remplissage(armee).g, Couleurs.or.g);
    expect(remplissage(armee).b, Couleurs.or.b);
    expect(remplissage(armee).a, lessThan(1.0));
    expect(remplissage(peuple), Couleurs.creme);

    // Et surtout, aucun chiffre de jauge nulle part.
    expect(find.text('12'), findsNothing);
  });
}
