import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/progression.dart';
import 'package:president/sauvegarde/sauvegarde.dart';
import 'package:shared_preferences/shared_preferences.dart';

const etat = EtatPartie(
  parcours: 'general_parcours',
  nomJoueur: 'Awa',
  jauges: Jauges(peuple: 44, armee: 61, caisses: 38, presse: 52),
  jour: 7,
  mandat: 2,
  drapeaux: {'solde_impayee'},
  vues: {'c1', 'c2'},
  chainesRang: {'affaire': 2},
  chainesJour: {'affaire': 5},
);

const progression = Progression(
  parcoursDebloques: {'general_parcours', 'reformateur_parcours'},
  exploits: {'premier_bilan', 'mandat_complet'},
  finsDecouvertes: {'fin_coup_etat', 'fin_reelection'},
  mandatsJoues: 3,
  meilleurJour: 87,
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sans rien d enregistre, la lecture rend une progression neuve', () async {
    final lue = await Sauvegarde.lisProgression();
    expect(lue.parcoursDebloques, isEmpty);
    expect(lue.exploits, isEmpty);
    expect(lue.finsDecouvertes, isEmpty);
    expect(lue.mandatsJoues, 0);
    expect(lue.meilleurJour, 0);
  });

  test('une progression enregistree se relit a l identique', () async {
    await Sauvegarde.enregistreProgression(progression);
    final relue = await Sauvegarde.lisProgression();
    expect(relue.parcoursDebloques, {'general_parcours', 'reformateur_parcours'});
    expect(relue.exploits, {'premier_bilan', 'mandat_complet'});
    expect(relue.finsDecouvertes, {'fin_coup_etat', 'fin_reelection'});
    expect(relue.mandatsJoues, 3);
    expect(relue.meilleurJour, 87);
  });

  test('une progression illisible rend une progression neuve sans toucher la partie en cours', () async {
    await Sauvegarde.enregistre(etat);
    SharedPreferences.setMockInitialValues({
      'partie_en_cours': (await SharedPreferences.getInstance()).getString('partie_en_cours')!,
      'progression': 'ceci n est pas du json',
    });

    final lue = await Sauvegarde.lisProgression();
    expect(lue.parcoursDebloques, isEmpty);
    expect(lue.exploits, isEmpty);
    expect(lue.finsDecouvertes, isEmpty);
    expect(lue.mandatsJoues, 0);
    expect(lue.meilleurJour, 0);

    final partieToujoursLa = await Sauvegarde.lis();
    expect(partieToujoursLa, isNotNull);
    expect(partieToujoursLa!.nomJoueur, 'Awa');
  });

  test('effacer la partie en cours laisse la progression intacte', () async {
    await Sauvegarde.enregistre(etat);
    await Sauvegarde.enregistreProgression(progression);

    await Sauvegarde.efface();

    expect(await Sauvegarde.lis(), isNull);
    final progressionRelue = await Sauvegarde.lisProgression();
    expect(progressionRelue.parcoursDebloques, {'general_parcours', 'reformateur_parcours'});
    expect(progressionRelue.exploits, {'premier_bilan', 'mandat_complet'});
    expect(progressionRelue.finsDecouvertes, {'fin_coup_etat', 'fin_reelection'});
    expect(progressionRelue.mandatsJoues, 3);
    expect(progressionRelue.meilleurJour, 87);
  });
}
