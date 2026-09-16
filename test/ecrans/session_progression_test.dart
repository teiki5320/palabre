import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/ecrans/session.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/progression.dart';
import 'package:president/sauvegarde/sauvegarde.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Un contenu minimal : un parcours au depart distinctif (pour verifier que
/// mandatSuivant y revient bien), une carte toujours jouable (pour que le
/// second mandat ne se termine pas tout seul, faute de carte), et un
/// exploit qui se debloque en tenant jusqu au bout du mandat.
Contenu contenuDEssai() => Contenu.depuisChaines(
      cartes: '[{"id":"c1","personnage":"general","humeur":"neutre","texte":"Une phrase.",'
          '"gauche":{"libelle":"A","effets":{"armee":1}},'
          '"droite":{"libelle":"B","effets":{"armee":-1}}}]',
      personnages: '[{"id":"general","nom":"Le General","titre":"Chef d etat-major"}]',
      parcours: '[{"id":"general_parcours","nom":"L ancien general","titre":"Monsieur le President",'
          '"femme":false,"depart":{"peuple":40,"armee":70,"caisses":50,"presse":40}}]',
      fins: '[{"id":"armee_bas","jauge":"armee","vers_le_haut":false,"titre":"Le palais est pris",'
          '"texte":"t","image":"i"},'
          '{"id":"election_gagnee","jauge":null,"vers_le_haut":true,"titre":"Reelu","texte":"t","image":"i"},'
          '{"id":"election_perdue","jauge":null,"vers_le_haut":false,"titre":"Battu","texte":"t","image":"i"}]',
      exploits: '[{"id":"tenir_jusqu_au_bout","titre":"Tenir bon","description":"Aller jusqu au bout du mandat",'
          '"condition":{"jours_min":30}}]',
    );

final etatReelu = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 60, armee: 60, caisses: 60, presse: 60),
  jour: dureeMandat + 1,
  mandat: 1,
  drapeaux: {'un_drapeau'},
  vues: {'c1'},
  chainesRang: {'x': 2},
  chainesJour: {'x': 30},
);

const etatChute = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 50, armee: 0, caisses: 50, presse: 50),
  jour: 5,
);

final etatBattu = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 30, armee: 50, caisses: 50, presse: 30),
  jour: dureeMandat + 1,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'le bilan est calcule une seule fois : des reconstructions repetees de l ecran '
      'ne recalculent ni ne reecrivent la progression', (tester) async {
    final contenu = contenuDEssai();
    final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
    addTearDown(container.dispose);
    await container.read(contenuProvider.future);
    await container.read(progressionProvider.future);

    container.read(sessionProvider.notifier).reprend(etatReelu, graine: 1);

    var constructions = 0;
    Widget ecran() => UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Consumer(builder: (context, ref, _) {
              constructions++;
              final session = ref.watch(sessionProvider);
              return Text('exploits:${session?.nouveautes.exploits.length}');
            }),
          ),
        );

    // Reconstruit l ecran plusieurs fois, comme le ferait Flutter pour toute
    // sorte de raisons qui n ont rien a voir avec la partie.
    for (var i = 0; i < 5; i++) {
      await tester.pumpWidget(ecran());
      await tester.pumpAndSettle();
    }

    expect(constructions, greaterThan(1));
    // La nouveaute reste presente a chaque reconstruction : elle n a pas ete
    // recalculee contre une progression deja mise a jour, ce qui l aurait
    // fait disparaitre.
    expect(find.text('exploits:1'), findsOneWidget);

    final progressionPersistee = await Sauvegarde.lisProgression();
    expect(progressionPersistee.mandatsJoues, 1);
    expect(progressionPersistee.exploits, contains('tenir_jusqu_au_bout'));

    final progressionExposee = await container.read(progressionProvider.future);
    expect(progressionExposee.mandatsJoues, 1);
    expect(progressionExposee.exploits, contains('tenir_jusqu_au_bout'));
  });

  test('les nouveautes sont vides quand rien n a ete gagne', () async {
    final contenu = contenuDEssai();
    final progressionDeja = Progression.neuve().copie(finsDecouvertes: {'armee_bas'});
    final container = ProviderContainer(overrides: [
      contenuProvider.overrideWith((ref) => contenu),
      progressionProvider.overrideWith((ref) => progressionDeja),
    ]);
    addTearDown(container.dispose);
    await container.read(contenuProvider.future);
    await container.read(progressionProvider.future);

    // Chute au jour 5 : ni l exploit (jours_min 30) ni un parcours (aucune
    // condition) ne peuvent se debloquer, et la fin est deja connue.
    container.read(sessionProvider.notifier).reprend(etatChute, graine: 1);

    final session = container.read(sessionProvider)!;
    expect(session.nouveautes.rienDeNeuf, isTrue);
    expect(session.nouveautes.exploits, isEmpty);
    expect(session.nouveautes.parcours, isEmpty);
    expect(session.nouveautes.finInedite, isFalse);
  });

  test(
      'mandatSuivant repart au jour 1, mandat suivant, avec les jauges de '
      'depart du parcours et rien de l ancien mandat', () async {
    final contenu = contenuDEssai();
    final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
    addTearDown(container.dispose);
    await container.read(contenuProvider.future);
    await container.read(progressionProvider.future);

    container.read(sessionProvider.notifier).reprend(etatReelu, graine: 1);
    expect(container.read(sessionProvider)!.terminee, isTrue);

    container.read(sessionProvider.notifier).mandatSuivant();

    final suite = container.read(sessionProvider)!;
    expect(suite.terminee, isFalse);
    expect(suite.etat.jour, 1);
    expect(suite.etat.mandat, 2);
    expect(suite.etat.nomJoueur, 'Awa');
    expect(suite.etat.parcours, 'general_parcours');
    expect(suite.etat.jauges.peuple, 40);
    expect(suite.etat.jauges.armee, 70);
    expect(suite.etat.jauges.caisses, 50);
    expect(suite.etat.jauges.presse, 40);
    expect(suite.etat.drapeaux, isEmpty);
    expect(suite.etat.vues, isEmpty);
    expect(suite.etat.chainesRang, isEmpty);
    expect(suite.etat.chainesJour, isEmpty);
    // Les nouveautes du mandat qui vient de finir ne s appliquent plus au
    // second mandat, qui commence tout juste.
    expect(suite.nouveautes.rienDeNeuf, isTrue);
  });

  test('mandatSuivant ne fait rien si le mandat n est pas termine', () async {
    final contenu = contenuDEssai();
    final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
    addTearDown(container.dispose);
    await container.read(contenuProvider.future);
    await container.read(progressionProvider.future);

    container.read(sessionProvider.notifier).demarre(
          parcours: contenu.parcours.first,
          nom: 'Awa',
          graine: 1,
        );
    final avant = container.read(sessionProvider);
    expect(avant!.terminee, isFalse);

    container.read(sessionProvider.notifier).mandatSuivant();

    expect(container.read(sessionProvider), same(avant));
  });

  test(
      'mandatSuivant ne fait rien si le mandat s est termine par une chute : '
      'c est au moteur de refuser, pas a l ecran de s en souvenir', () async {
    final contenu = contenuDEssai();
    final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
    addTearDown(container.dispose);
    await container.read(contenuProvider.future);
    await container.read(progressionProvider.future);

    container.read(sessionProvider.notifier).reprend(etatChute, graine: 1);
    final avant = container.read(sessionProvider);
    expect(avant!.terminee, isTrue);
    expect(avant.denouement!.type, TypeDenouement.chute);

    container.read(sessionProvider.notifier).mandatSuivant();

    expect(container.read(sessionProvider), same(avant));
  });

  test('mandatSuivant ne fait rien si le mandat s est termine par une election perdue', () async {
    final contenu = contenuDEssai();
    final container = ProviderContainer(overrides: [contenuProvider.overrideWith((ref) => contenu)]);
    addTearDown(container.dispose);
    await container.read(contenuProvider.future);
    await container.read(progressionProvider.future);

    container.read(sessionProvider.notifier).reprend(etatBattu, graine: 1);
    final avant = container.read(sessionProvider);
    expect(avant!.terminee, isTrue);
    expect(avant.denouement!.type, TypeDenouement.electionPerdue);

    container.read(sessionProvider.notifier).mandatSuivant();

    expect(container.read(sessionProvider), same(avant));
  });
}
