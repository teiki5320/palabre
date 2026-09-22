import 'dart:math';

import '../contenu/chargement.dart';
import 'denouement.dart';
import 'etat_partie.dart';
import 'jauges.dart';
import 'modeles.dart';
import 'palais.dart';
import 'partie.dart';
import 'tirage.dart';

/// Façons de jouer, pour éprouver l'équilibrage sans joueur humain.
enum Strategie { toujoursGauche, toujoursDroite, auHasard, equilibree }

/// Ce que la simulation mesure.
class Mesures {
  const Mesures({
    required this.parties,
    required this.joursMoyens,
    required this.denouements,
    required this.cartesJamaisVues,
  });

  final int parties;

  /// Durée moyenne d'un mandat, en jours.
  final double joursMoyens;

  /// Nom du dénouement -> nombre de parties qui s'y terminent.
  final Map<String, int> denouements;

  /// Cartes qu'aucune partie n'a tirées : du contenu écrit pour rien.
  final Set<String> cartesJamaisVues;
}

/// Joue un grand nombre de mandats et rend les mesures.
Mesures simule({
  required Contenu contenu,
  required String parcours,
  required Strategie strategie,
  int parties = 1000,
  int graine = 1,
  int duree = dureeMandat,
  int mandats = 1,
  bool acheteDesObjets = false,
}) {
  final alea = Random(graine);
  final depart = contenu.parcoursParId(parcours);
  if (depart == null) throw ArgumentError('parcours inconnu : $parcours');

  final denouements = <String, int>{};
  final vuesPartout = <String>{};
  var totalJours = 0;

  final adversaires = contenu.adversaires;

  for (var p = 0; p < parties; p++) {
    var etat = EtatPartie(
      parcours: parcours,
      nomJoueur: 'Test',
      jauges: depart.depart,
      // Comme l'écran : un opposant tiré au premier jour, sans quoi les
      // cartes qui le nomment ne sortiraient jamais et passeraient pour du
      // contenu écrit pour rien.
      adversaire: adversaires.isEmpty ? null : adversaires[alea.nextInt(adversaires.length)].id,
    );
    final objets = <String>{};
    while (true) {
      final fin = evalue(etat, duree: duree);
      if (fin != null) {
        // Réélu avec un mandat de plus à jouer : on enchaîne, comme l'écran.
        if (fin.type == TypeDenouement.electionGagnee && etat.mandat < mandats) {
          totalJours += etat.jour - 1;
          etat = mandatSuivant(etat, depart);
          continue;
        }
        denouements.update(fin.type.name, (v) => v + 1, ifAbsent: () => 1);
        break;
      }
      final carte = choisitCarte(paquet: contenu.cartes, etat: etat, alea: alea);
      if (carte == null) {
        denouements.update('paquetEpuise', (v) => v + 1, ifAbsent: () => 1);
        break;
      }
      vuesPartout.add(carte.id);
      // Le palais fait partie du jeu : un joueur qui ne passe jamais à la
      // boutique ne verra jamais les cartes qu'un objet ouvre, et elles
      // passeraient pour du contenu écrit pour rien.
      if (acheteDesObjets && etat.jour % 7 == 0) {
        final possibles = [
          for (final o in contenu.objets)
            if (achetable(etat, o, objets)) o,
        ];
        if (possibles.isNotEmpty) {
          final o = possibles[alea.nextInt(possibles.length)];
          objets.add(o.id);
          etat = achete(etat, o);
        }
      }
      etat = repond(
        etat: etat,
        carte: carte,
        cote: _choisit(strategie, etat, carte, alea, depart.atout),
        atout: depart.atout,
        qui: contenu.personnageDe(carte, depart, epouse: etat.epouse),
      );
    }
    totalJours += etat.jour - 1;
  }

  return Mesures(
    parties: parties,
    joursMoyens: totalJours / parties,
    denouements: denouements,
    cartesJamaisVues: {for (final c in contenu.cartes) c.id}..removeAll(vuesPartout),
  );
}

Cote _choisit(Strategie s, EtatPartie etat, Carte carte, Random alea, Atout? atout) => switch (s) {
      Strategie.toujoursGauche => Cote.gauche,
      Strategie.toujoursDroite => Cote.droite,
      Strategie.auHasard => alea.nextBool() ? Cote.gauche : Cote.droite,
      Strategie.equilibree => _versLeCentre(etat, carte, atout),
    };

/// Joue le côté qui laisse les jauges le plus près du centre — en jugeant sur
/// les effets réels, régime, mandat et atout compris, c'est-à-dire sur ce que
/// l'écran montre au joueur. Juger sur les effets bruts, c'est simuler un
/// joueur aveugle, et tout l'équilibrage mesuré avec lui est faux.
Cote _versLeCentre(EtatPartie etat, Carte carte, Atout? atout) {
  int ecart(Reponse r) {
    final apres = etat.jauges.applique(
      effetsReels(effets: r.effets, style: etat.style, mandat: etat.mandat, atout: atout),
    );
    return Jauge.values.fold(0, (s, j) => s + (apres.valeur(j) - 50).abs());
  }

  return ecart(carte.gauche) <= ecart(carte.droite) ? Cote.gauche : Cote.droite;
}
