import 'package:flutter_test/flutter_test.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/partie.dart';
import 'package:president/moteur/romance.dart';

/// Ce qui se noue, et ce qui ne se noue pas tout seul. La règle que ces
/// tests gardent avant toutes les autres : une réponse qui ne parle pas de
/// romance n'en crée aucune, quoi qu'elle fasse aux jauges.

Carte carte({
  String personnage = 'redactrice',
  EffetRomance gauche = const EffetRomance(),
  Map<Jauge, int> effets = const {Jauge.presse: 12},
}) =>
    Carte(
      id: 'essai',
      personnage: personnage,
      humeur: Humeur.neutre,
      texte: 'Une soirée qui dure.',
      gauche: Reponse(libelle: 'Je reste', effets: effets, romance: gauche),
      droite: const Reponse(libelle: 'Je rentre', effets: {Jauge.presse: -5}),
    );

EtatPartie depart({Map<String, int> attache = const {}, String? epouse}) => EtatPartie(
      parcours: 'general_parcours',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      attache: attache,
      epouse: epouse,
    );

void main() {
  group('l attache ne se déduit de rien', () {
    test('une réponse muette ne noue rien, même en servant la personne', () {
      final apres = repond(etat: depart(), carte: carte(), cote: Cote.gauche);
      expect(apres.attache, isEmpty);
    });

    test('une réponse qui la déclare monte d un cran', () {
      final apres = repond(
        etat: depart(),
        carte: carte(gauche: const EffetRomance(mouvement: 1)),
        cote: Cote.gauche,
      );
      expect(attacheAvec(apres.attache, 'redactrice'), attacheRemarque);
    });

    test('elle vise le personnage de la carte, sauf mention contraire', () {
      final apres = repond(
        etat: depart(),
        carte: carte(gauche: const EffetRomance(mouvement: 2, de: 'cabinet')),
        cote: Cote.gauche,
      );
      expect(attacheAvec(apres.attache, 'cabinet'), attacheGeste);
      expect(attacheAvec(apres.attache, 'redactrice'), attacheRien);
    });

    test('elle ne dépasse ni zéro ni cinq', () {
      var m = <String, int>{};
      for (var i = 0; i < 12; i++) {
        m = appliqueAttache(m, 'maire', 1);
      }
      expect(m['maire'], attacheDemande);
      for (var i = 0; i < 12; i++) {
        m = appliqueAttache(m, 'maire', -1);
      }
      expect(m['maire'], attacheRien);
    });

    test('elle rend la carte inchangée quand rien ne bouge', () {
      const avant = {'maire': 3};
      expect(identical(appliqueAttache(avant, 'maire', 0), avant), isTrue);
      expect(identical(appliqueAttache(avant, null, 2), avant), isTrue);
      // Déjà au plafond : la carte ne doit pas être recopiée pour rien.
      const plein = {'maire': attacheDemande};
      expect(identical(appliqueAttache(plein, 'maire', 1), plein), isTrue);
    });
  });

  group('le mariage', () {
    test('le président commence célibataire', () {
      expect(depart().epouse, isNull);
      expect(estMarie(depart().epouse), isFalse);
    });

    test('une réponse peut épouser, et le moteur retient qui', () {
      final apres = repond(
        etat: depart(attache: {'maire': attacheDemande}),
        carte: carte(personnage: 'maire', gauche: const EffetRomance(epouse: true)),
        cote: Cote.gauche,
      );
      expect(apres.epouse, 'maire');
      expect(estMarie(apres.epouse), isTrue);
    });

    test('rompre efface l attache et défait le mariage si c était elle', () {
      final apres = repond(
        etat: depart(attache: {'maire': 5, 'cabinet': 2}, epouse: 'maire'),
        carte: carte(personnage: 'maire', gauche: const EffetRomance(rupture: true)),
        cote: Cote.gauche,
      );
      expect(apres.epouse, isNull);
      expect(attacheAvec(apres.attache, 'maire'), attacheRien);
      // Les autres ne sont pas concernés : on rompt avec quelqu'un.
      expect(attacheAvec(apres.attache, 'cabinet'), attacheGeste);
    });

    test('rompre avec quelqu un d autre ne défait pas le mariage', () {
      final apres = repond(
        etat: depart(attache: {'maire': 5, 'cabinet': 3}, epouse: 'maire'),
        carte: carte(personnage: 'cabinet', gauche: const EffetRomance(rupture: true)),
        cote: Cote.gauche,
      );
      expect(apres.epouse, 'maire');
      expect(attacheAvec(apres.attache, 'cabinet'), attacheRien);
    });

    test('copie ne peut pas effacer un mariage par omission', () {
      final marie = depart(epouse: 'maire');
      expect(marie.copie(jour: 4).epouse, 'maire');
      expect(marie.copie(celibataire: true).epouse, isNull);
    });
  });

  group('ce que la chambre montre', () {
    test('vide tant que rien ne dépasse le premier geste', () {
      expect(chambreSelon(const {}, null), Chambre.seule);
      expect(chambreSelon(const {'maire': attacheGeste}, null), Chambre.seule);
    });

    test('quelqu un est passé à partir de la liaison', () {
      expect(chambreSelon(const {'maire': attacheLiaison}, null), Chambre.visitee);
    });

    test('on y dort à deux quand on ne se cache plus, ou quand on est marié', () {
      expect(chambreSelon(const {'maire': attacheOuverte}, null), Chambre.partagee);
      expect(chambreSelon(const {}, 'maire'), Chambre.partagee);
    });
  });

  group('plusieurs à la fois', () {
    const trois = {'maire': 4, 'cabinet': 2, 'emissaire': 4};

    test('la liaison principale est la plus avancée', () {
      expect(liaisonPrincipale(trois)?.cran, 4);
    });

    test('à égalité, on tranche toujours de la même façon', () {
      // Deux fois le même appel doit rendre le même nom, sinon la chambre
      // changerait d'un lancement à l'autre.
      expect(liaisonPrincipale(trois)?.qui, liaisonPrincipale(trois)?.qui);
      expect(liaisonPrincipale(trois)?.qui, 'emissaire');
    });

    test('on sait combien de liaisons courent en même temps', () {
      expect(liaisonsAuMoins(trois, attacheLiaison), 2);
      expect(liaisonsAuMoins(trois, attacheGeste), 3);
      expect(liaisonsAuMoins(const {}, attacheRemarque), 0);
    });

    test('personne, c est personne', () {
      expect(liaisonPrincipale(const {}), isNull);
      expect(liaisonPrincipale(const {'maire': 0}), isNull);
    });
  });

  group('ce que les cartes peuvent exiger', () {
    const etat = EtatPartie(
      parcours: 'general_parcours',
      nomJoueur: 'Awa',
      jauges: Jauges.milieu,
      attache: {'redactrice': 3, 'maire': 1},
    );

    test('le cran porte sur le personnage de la carte', () {
      expect(const Conditions(attacheMin: 3).satisfaites(etat, personnage: 'redactrice'), isTrue);
      expect(const Conditions(attacheMin: 3).satisfaites(etat, personnage: 'maire'), isFalse);
    });

    test('une carte peut viser quelqu un d autre', () {
      expect(
        const Conditions(attacheDe: 'redactrice', attacheMin: 3).satisfaites(etat, personnage: 'maire'),
        isTrue,
      );
    });

    test('un inconnu vaut zéro, ce qui ouvre les cartes de premier regard', () {
      expect(const Conditions(attacheMax: 0).satisfaites(etat, personnage: 'cabinet'), isTrue);
      expect(const Conditions(attacheMax: 0).satisfaites(etat, personnage: 'redactrice'), isFalse);
    });

    test('une carte sans personnage ne peut pas exiger d attache', () {
      expect(const Conditions(attacheMin: 1).satisfaites(etat), isFalse);
    });

    test('le mariage s exige dans les deux sens', () {
      const celibataire = Conditions(marie: false);
      const marie = Conditions(marie: true);
      expect(celibataire.satisfaites(etat), isTrue);
      expect(marie.satisfaites(etat), isFalse);

      final apres = etat.copie(epouse: 'redactrice');
      expect(marie.satisfaites(apres), isTrue);
      expect(celibataire.satisfaites(apres), isFalse);
    });

    test('la plupart des cartes ne s en soucient pas', () {
      expect(const Conditions().satisfaites(etat, personnage: 'redactrice'), isTrue);
    });
  });

  test('un second mandat garde ce qui s est noué', () {
    const parcours = Parcours(
      id: 'general_parcours',
      nom: 'Le général',
      titre: 'Monsieur le Président',
      femme: false,
      depart: Jauges.milieu,
    );
    final fin = depart(attache: {'maire': 5}, epouse: 'maire').copie(jour: 101);
    final suivant = mandatSuivant(fin, parcours);
    expect(suivant.epouse, 'maire');
    expect(attacheAvec(suivant.attache, 'maire'), attacheDemande);
  });
}
