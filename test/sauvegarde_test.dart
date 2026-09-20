import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
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
  cartesJour: {'rdv_maire': 30},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sans partie enregistree, la lecture rend null', () async {
    expect(await Sauvegarde.lis(), isNull);
  });

  test('une partie enregistree se relit a l identique', () async {
    await Sauvegarde.enregistre(etat);
    final relu = (await Sauvegarde.lis())!;
    expect(relu.parcours, etat.parcours);
    expect(relu.nomJoueur, 'Awa');
    expect(relu.jauges.peuple, 44);
    expect(relu.jauges.presse, 52);
    expect(relu.jour, 7);
    expect(relu.mandat, 2);
    expect(relu.drapeaux, {'solde_impayee'});
    expect(relu.vues, {'c1', 'c2'});
    expect(relu.chainesRang['affaire'], 2);
    expect(relu.chainesJour['affaire'], 5);
    expect(relu.cartesJour['rdv_maire'], 30);
  });

  test('effacer supprime la partie', () async {
    await Sauvegarde.enregistre(etat);
    await Sauvegarde.efface();
    expect(await Sauvegarde.lis(), isNull);
  });

  test('une sauvegarde illisible est ignoree plutot que de faire planter', () async {
    SharedPreferences.setMockInitialValues({'partie_en_cours': 'ceci n est pas du json'});
    expect(await Sauvegarde.lis(), isNull);
  });
}
