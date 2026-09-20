import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/tirage.dart';

Carte carte(String id, {Conditions? conditions, int poids = 1, Chaine? chaine, bool repetable = false, int attente = 0, String personnage = 'general'}) => Carte(
      id: id,
      personnage: personnage,
      humeur: Humeur.neutre,
      texte: 'texte',
      gauche: const Reponse(libelle: 'non', effets: {Jauge.armee: -5}),
      droite: const Reponse(libelle: 'oui', effets: {Jauge.armee: 5}),
      conditions: conditions ?? const Conditions(),
      poids: poids,
      chaine: chaine,
      repetable: repetable,
      attente: attente,
    );

EtatPartie etat({
  int jour = 5,
  Set<String> vues = const {},
  Map<String, int> rangs = const {},
  Map<String, int> jours = const {},
  Map<String, int> cartesJour = const {},
  String? hier,
}) =>
    EtatPartie(
      hier: hier,
      parcours: 'general',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      jour: jour,
      vues: vues,
      chainesRang: rangs,
      chainesJour: jours,
      cartesJour: cartesJour,
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

  test('une carte repetable attend son delai avant de revenir', () {
    final rdv = carte('rdv', repetable: true, attente: 10);
    // Sortie au trentieme jour : elle ne revient pas le trente-neuvieme.
    expect(
      choisitCarte(paquet: [rdv], etat: etat(jour: 39, vues: {'rdv'}, cartesJour: {'rdv': 30}), alea: Random(1)),
      isNull,
    );
    // Le quarantieme, si.
    expect(
      choisitCarte(paquet: [rdv], etat: etat(jour: 40, vues: {'rdv'}, cartesJour: {'rdv': 30}), alea: Random(1))!.id,
      'rdv',
    );
  });

  test('une carte repetable sans attente revient des le lendemain', () {
    final tiree = choisitCarte(
      paquet: [carte('a', repetable: true)],
      etat: etat(jour: 6, vues: {'a'}, cartesJour: {'a': 5}),
      alea: Random(1),
    );
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

  test('une carte de rang 1 qui ouvre une chaine ne passe pas devant une carte ordinaire', () {
    final paquet = [
      carte('ordinaire', poids: 50),
      carte('ouverture', chaine: const Chaine(id: 'solde', rang: 1)),
    ];
    final tiree = choisitCarte(paquet: paquet, etat: etat(), alea: Random(7));
    expect(tiree!.id, 'ordinaire');
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

  group('hier', () {
    test('la personne d hier ne revient pas le lendemain', () {
      final paquet = [carte('a'), carte('b'), carte('c', personnage: 'marchande')];
      for (var g = 0; g < 30; g++) {
        final c = choisitCarte(paquet: paquet, etat: etat(vues: {'a'}, hier: 'a'), alea: Random(g));
        expect(c!.id, 'c');
      }
    });

    test('le debut d une histoire ne suit pas une carte de la meme histoire', () {
      final paquet = [
        carte('a', chaine: const Chaine(id: 'x', rang: 1)),
        carte('b', chaine: const Chaine(id: 'x', rang: 1), personnage: 'maire'),
        carte('c', personnage: 'marchande'),
      ];
      for (var g = 0; g < 30; g++) {
        final c = choisitCarte(paquet: paquet, etat: etat(vues: {'a'}, hier: 'a'), alea: Random(g));
        expect(c!.id, 'c');
      }
    });

    test('s il ne reste que la personne d hier, elle revient', () {
      final paquet = [carte('a'), carte('b')];
      final c = choisitCarte(paquet: paquet, etat: etat(vues: {'a'}, hier: 'a'), alea: Random(1));
      expect(c!.id, 'b');
    });

    test('une suite d histoire revient le lendemain meme si c est la meme personne', () {
      final paquet = [
        carte('a', chaine: const Chaine(id: 'x', rang: 1)),
        carte('a2', chaine: const Chaine(id: 'x', rang: 2, delaiMin: 1)),
        carte('c', personnage: 'marchande'),
      ];
      final c = choisitCarte(paquet: paquet, etat: etat(vues: {'a'}, hier: 'a', rangs: {'x': 1}, jours: {'x': 4}), alea: Random(1));
      expect(c!.id, 'a2');
    });
  });
}
