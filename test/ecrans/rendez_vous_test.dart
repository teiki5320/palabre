import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/partie_ecran.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/ecrans/theme.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:shared_preferences/shared_preferences.dart';

Contenu _contenu() => Contenu.depuisChaines(
      cartes: '['
          '{"id":"c1","personnage":"maire","humeur":"neutre","texte":"La ville dort.",'
          '"gauche":{"libelle":"Bien","effets":{"peuple":-5}},'
          '"droite":{"libelle":"Tant mieux","effets":{"peuple":5,"caisses":-5}}}'
          ']',
      personnages: '[{"id":"maire","nom":"Le Maire","titre":"Maire de la capitale"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":50,"armee":50,"caisses":50,"presse":50}}]',
      fins: '[{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
    );

/// Un mandat ou quelqu un attend ce soir.
EtatPartie _soiree() => const EtatPartie(
      parcours: 'general_parcours',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      jour: 30,
      attache: {'maire': 5},
      drapeaux: {'rdv_maire'},
    );

late SessionNotifier _session;

Future<void> _ouvreLaChambre(WidgetTester tester) async {
  final contenu = _contenu();
  await tester.pumpWidget(ProviderScope(
    overrides: [contenuProvider.overrideWith((ref) => contenu)],
    child: MaterialApp(
      theme: theme(),
      home: Consumer(builder: (context, ref, _) {
        return TextButton(
          onPressed: () {
            _session = ref.read(sessionProvider.notifier);
            _session.reprend(_soiree(), graine: 1);
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
  await tester.tap(find.text('Le couloir'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 120));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('la chambre tient le rendez-vous en trois temps', (tester) async {
    await _ouvreLaChambre(tester);

    // Un : elle attend, habillee, et rien ne bouge tout seul.
    expect(find.text('Approcher'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('Approcher'), findsOneWidget);

    // Deux : le premier appui joue les trois poses, et l invite ne revient
    // qu une fois la derniere atteinte.
    await tester.tap(find.text('Approcher'));
    await tester.pump();
    expect(find.text('Rejoindre le lit'), findsNothing);
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump(const Duration(milliseconds: 950));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Rejoindre le lit'), findsOneWidget);

    // Trois : le lit, puis la sortie, qui eteint le rendez-vous.
    await tester.tap(find.text('Rejoindre le lit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Revenir au bureau'), findsOneWidget);

    await tester.tap(find.text('Revenir au bureau'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(_session.state!.etat.drapeaux, isNot(contains('rdv_maire')));
    expect(find.text('Le bureau de travail'), findsOneWidget);
  });

  testWidgets('sans rendez-vous, la chambre reste une chambre', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final contenu = _contenu();
    await tester.pumpWidget(ProviderScope(
      overrides: [contenuProvider.overrideWith((ref) => contenu)],
      child: MaterialApp(
        theme: theme(),
        home: Consumer(builder: (context, ref, _) {
          return TextButton(
            onPressed: () {
              ref.read(sessionProvider.notifier).reprend(
                    const EtatPartie(
                      parcours: 'general_parcours',
                      nomJoueur: 'Awa',
                      jauges: Jauges.milieu,
                      jour: 30,
                      attache: {'maire': 5},
                    ),
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
    await tester.tap(find.text('Le couloir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.text('Approcher'), findsNothing);
    expect(find.text("On n'est pas seul"), findsOneWidget);
  });
}
