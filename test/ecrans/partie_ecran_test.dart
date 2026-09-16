import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/partie_ecran.dart';
import 'package:president/ecrans/session.dart';

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
  testWidgets('la partie affiche le jour, les jauges et une carte', (tester) async {
    await lance(tester);
    expect(find.text('Jour 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('jauge_armee')), findsOneWidget);
    expect(find.textContaining('solde'), findsOneWidget);
  });

  testWidgets('repondre avance au jour suivant et change de carte', (tester) async {
    await lance(tester);
    await tester.drag(find.textContaining('solde'), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(find.text('Jour 2'), findsOneWidget);
    expect(find.textContaining('casernes'), findsOneWidget);
  });

  testWidgets('le nom du joueur remplace le gabarit', (tester) async {
    await lance(tester);
    expect(find.textContaining('Awa'), findsWidgets);
  });
}
