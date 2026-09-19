import 'package:flutter_test/flutter_test.dart';
import 'dart:math';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/memoire.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/partie.dart';
import 'package:president/moteur/tirage.dart';

/// Deux mémoires : celle des gens du palais, celle de l'opposition. Elles
/// ne sont déclarées nulle part dans les cartes — elles se lisent dans les
/// effets subis — donc les seules règles qui les tiennent sont ici.

const general = Personnage(
  id: 'general',
  nom: 'Le général Sow',
  titre: 'Chef d\'état-major',
  jauge: Jauge.armee,
);

const sansJauge = Personnage(id: 'inconnu', nom: 'Un inconnu', titre: 'Personne');

Carte carte({required Map<Jauge, int> gauche, String personnage = 'general'}) => Carte(
      id: 'essai',
      personnage: personnage,
      humeur: Humeur.neutre,
      texte: 'Une demande.',
      gauche: Reponse(libelle: 'Oui', effets: gauche),
      droite: const Reponse(libelle: 'Non', effets: {}),
    );

EtatPartie depart() => const EtatPartie(parcours: 'general', nomJoueur: 'Awa', jauges: Jauges.milieu);

void main() {
  group('la loyauté', () {
    test('monte quand la décision sert la jauge du personnage', () {
      expect(mouvementLoyaute(qui: general, effetsReels: const {Jauge.armee: 10}), 1);
    });

    test('descend quand elle la dessert', () {
      expect(mouvementLoyaute(qui: general, effetsReels: const {Jauge.armee: -10}), -1);
    });

    test('ne bouge pas pour un effet léger', () {
      expect(mouvementLoyaute(qui: general, effetsReels: const {Jauge.armee: 2}), 0);
      expect(mouvementLoyaute(qui: general, effetsReels: const {Jauge.armee: -2}), 0);
    });

    test('ne bouge pas sur une jauge qui n est pas la sienne', () {
      expect(mouvementLoyaute(qui: general, effetsReels: const {Jauge.presse: 15}), 0);
    });

    test('ne bouge pas quand le personnage ne défend rien, ni quand il manque', () {
      expect(mouvementLoyaute(qui: sansJauge, effetsReels: const {Jauge.armee: 15}), 0);
      expect(mouvementLoyaute(qui: null, effetsReels: const {Jauge.armee: 15}), 0);
    });

    test('ne dépasse jamais ses bornes', () {
      var m = <String, int>{};
      for (var i = 0; i < 20; i++) {
        m = appliqueLoyaute(m, 'general', 1);
      }
      expect(m['general'], loyautePlafond);
      for (var i = 0; i < 40; i++) {
        m = appliqueLoyaute(m, 'general', -1);
      }
      expect(m['general'], loyautePlancher);
    });

    test('rend la carte inchangée quand rien ne bouge', () {
      const avant = {'general': 2};
      expect(identical(appliqueLoyaute(avant, 'general', 0), avant), isTrue);
      expect(identical(appliqueLoyaute(avant, null, 1), avant), isTrue);
    });

    test('une réponse la déplace vraiment dans l état', () {
      final apres = repond(
        etat: depart(),
        carte: carte(gauche: const {Jauge.armee: 12}),
        cote: Cote.gauche,
        qui: general,
      );
      expect(apres.loyaute['general'], 1);
    });

    test('sans personnage fourni, personne ne retient rien', () {
      final apres = repond(etat: depart(), carte: carte(gauche: const {Jauge.armee: 12}), cote: Cote.gauche);
      expect(apres.loyaute, isEmpty);
    });
  });

  group('la force de l opposant', () {
    test('monte de ce qu on perd devant le pays', () {
      expect(mouvementForce(const {Jauge.peuple: -12}), 3);
      expect(mouvementForce(const {Jauge.peuple: -8, Jauge.presse: -8}), 4);
    });

    test('descend de ce qu on y gagne', () {
      expect(mouvementForce(const {Jauge.peuple: 12}), -3);
    });

    test('ignore l armée et les caisses', () {
      expect(mouvementForce(const {Jauge.armee: -20, Jauge.caisses: -20}), 0);
    });

    test('ne bouge pas sous quatre points', () {
      expect(mouvementForce(const {Jauge.peuple: -3}), 0);
    });

    test('reste entre ses bornes', () {
      var f = forceDepart;
      for (var i = 0; i < 50; i++) {
        f = appliqueForce(f, 5);
      }
      expect(f, forcePlafond);
      for (var i = 0; i < 100; i++) {
        f = appliqueForce(f, -5);
      }
      expect(f, forcePlancher);
    });

    test('une réponse coûteuse la fait monter dans l état', () {
      final apres = repond(etat: depart(), carte: carte(gauche: const {Jauge.peuple: -12}), cote: Cote.gauche);
      expect(apres.force, forceDepart + 3);
    });
  });

  group('l élection', () {
    test('se décide à cinquante quand personne ne monte en face', () {
      const gagne = EtatPartie(
        parcours: 'general',
        nomJoueur: 'Awa',
        jauges: Jauges(peuple: 60, armee: 50, caisses: 50, presse: 60),
        jour: 101,
      );
      expect(evalue(gagne)?.type, TypeDenouement.electionGagnee);
    });

    test('se perd contre un opposant monté, avec les mêmes jauges', () {
      const memesJauges = EtatPartie(
        parcours: 'general',
        nomJoueur: 'Awa',
        jauges: Jauges(peuple: 60, armee: 50, caisses: 50, presse: 60),
        jour: 101,
        force: 65,
      );
      expect(evalue(memesJauges)?.type, TypeDenouement.electionPerdue);
    });

    test('une réélection lui reprend la moitié de son terrain', () {
      expect(forceApresDefaite(70), 60);
      expect(forceApresDefaite(forceDepart), forceDepart);
    });
  });

  group('les conditions', () {
    const etat = EtatPartie(
      parcours: 'general',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      loyaute: {'general': -4, 'ministre': 3},
      adversaire: 'pasteur',
      force: 70,
    );

    test('la loyauté exigée porte sur le personnage de la carte', () {
      const c = Conditions(loyauteMax: -3);
      expect(c.satisfaites(etat, personnage: 'general'), isTrue);
      expect(c.satisfaites(etat, personnage: 'ministre'), isFalse);
    });

    test('elle peut nommer quelqu un d autre', () {
      const c = Conditions(loyauteDe: 'ministre', loyauteMin: 2);
      expect(c.satisfaites(etat, personnage: 'general'), isTrue);
    });

    test('une carte sans personnage ne peut pas exiger de loyauté', () {
      const c = Conditions(loyauteMin: 1);
      expect(c.satisfaites(etat), isFalse);
    });

    test('un personnage qui n a rien retenu vaut zéro', () {
      const c = Conditions(loyauteMin: 0, loyauteMax: 0);
      expect(c.satisfaites(etat, personnage: 'doyen'), isTrue);
    });

    test('l adversaire nommé doit être celui de la partie', () {
      expect(const Conditions(adversaire: ['pasteur']).satisfaites(etat), isTrue);
      expect(const Conditions(adversaire: ['generale']).satisfaites(etat), isFalse);
    });

    test('la force encadre', () {
      expect(const Conditions(forceMin: 65).satisfaites(etat), isTrue);
      expect(const Conditions(forceMax: 65).satisfaites(etat), isFalse);
    });

    test('le tirage passe le personnage de la carte aux conditions', () {
      final fache = Carte(
        id: 'fache',
        personnage: 'general',
        humeur: Humeur.fache,
        texte: 'Vous ne m écoutez plus.',
        gauche: const Reponse(libelle: 'Si', effets: {}),
        droite: const Reponse(libelle: 'Non', effets: {}),
        conditions: const Conditions(loyauteMax: -3),
      );
      final tiree = choisitCarte(paquet: [fache], etat: etat, alea: _alea());
      expect(tiree, isNotNull);
    });
  });

  test('un mandat suivant garde la mémoire et l opposant', () {
    const parcours = Parcours(id: 'general', nom: 'Le général', titre: 'Monsieur le Président', femme: false, depart: Jauges.milieu);
    const fin = EtatPartie(
      parcours: 'general',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      jour: 101,
      loyaute: {'general': 4},
      adversaire: 'pasteur',
      force: 70,
    );
    final suivant = mandatSuivant(fin, parcours);
    expect(suivant.loyaute['general'], 4);
    expect(suivant.adversaire, 'pasteur');
    expect(suivant.force, 60);
  });
}

Random _alea() => Random(1);
