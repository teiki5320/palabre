import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/tirage.dart';

Carte carte(String id, {Conditions? conditions, int poids = 1, Chaine? chaine, bool repetable = false}) => Carte(
      id: id,
      personnage: 'general',
      humeur: Humeur.neutre,
      texte: 'texte',
      gauche: const Reponse(libelle: 'non', effets: {Jauge.armee: -5}),
      droite: const Reponse(libelle: 'oui', effets: {Jauge.armee: 5}),
      conditions: conditions ?? const Conditions(),
      poids: poids,
      chaine: chaine,
      repetable: repetable,
    );

EtatPartie etat({int jour = 5, Set<String> vues = const {}, Map<String, int> rangs = const {}, Map<String, int> jours = const {}}) =>
    EtatPartie(
      parcours: 'general',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      jour: jour,
      vues: vues,
      chainesRang: rangs,
      chainesJour: jours,
    );

void main() {
  test('une carte deja vue ne ressort pas', () {
    final tiree = choisitCarte(paquet: [carte('a'), carte('b')], etat: etat(vues: {'a'}), alea: Random(1));
    expect(tiree!.id, 'b');
  });

  test('une carte repetable peut ressortir', () {
    final tiree = choisitCarte(paquet: [carte('a', repetable: true)], etat: etat(vues: {'a'}), alea: Random(1));
    expect(tiree!.id, 'a');
  });

  test('une carte dont les conditions ne sont pas remplies est ecartee', () {
    final tiree = choisitCarte(
      paquet: [carte('tot', conditions: const Conditions(jourMin: 99)), carte('ok')],
      etat: etat(),
      alea: Random(1),
    );
    expect(tiree!.id, 'ok');
  });

  test('le paquet epuise rend null', () {
    expect(choisitCarte(paquet: [carte('a')], etat: etat(vues: {'a'}), alea: Random(1)), isNull);
  });

  test('le maillon suivant d une chaine passe avant une carte ordinaire', () {
    final paquet = [
      carte('ordinaire', poids: 50),
      carte('suite', chaine: const Chaine(id: 'solde', rang: 2)),
    ];
    final tiree = choisitCarte(paquet: paquet, etat: etat(rangs: {'solde': 1}, jours: {'solde': 1}), alea: Random(7));
    expect(tiree!.id, 'suite');
  });

  test('un maillon hors sequence est ecarte', () {
    final paquet = [
      carte('ordinaire'),
      carte('trop_loin', chaine: const Chaine(id: 'solde', rang: 3)),
    ];
    final tiree = choisitCarte(paquet: paquet, etat: etat(rangs: {'solde': 1}, jours: {'solde': 1}), alea: Random(7));
    expect(tiree!.id, 'ordinaire');
  });

  test('un maillon dont le delai n est pas ecoule attend', () {
    final paquet = [
      carte('ordinaire'),
      carte('suite', chaine: const Chaine(id: 'solde', rang: 2, delaiMin: 4)),
    ];
    final tot = choisitCarte(paquet: paquet, etat: etat(jour: 3, rangs: {'solde': 1}, jours: {'solde': 1}), alea: Random(7));
    expect(tot!.id, 'ordinaire');
    final tard = choisitCarte(paquet: paquet, etat: etat(jour: 5, rangs: {'solde': 1}, jours: {'solde': 1}), alea: Random(7));
    expect(tard!.id, 'suite');
  });

  test('le poids augmente la frequence', () {
    final paquet = [carte('rare', poids: 1, repetable: true), carte('courante', poids: 9, repetable: true)];
    final alea = Random(42);
    var courante = 0;
    for (var i = 0; i < 1000; i++) {
      if (choisitCarte(paquet: paquet, etat: etat(), alea: alea)!.id == 'courante') courante++;
    }
    expect(courante, greaterThan(820));
    expect(courante, lessThan(980));
  });

  test('a graine egale, le tirage est identique', () {
    final paquet = [carte('a', repetable: true), carte('b', repetable: true), carte('c', repetable: true)];
    List<String> serie(int graine) {
      final alea = Random(graine);
      return [for (var i = 0; i < 20; i++) choisitCarte(paquet: paquet, etat: etat(), alea: alea)!.id];
    }

    expect(serie(3), serie(3));
  });
}
