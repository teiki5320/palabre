import 'dart:math';

import '../contenu/chargement.dart';
import 'denouement.dart';
import 'etat_partie.dart';
import 'jauges.dart';
import 'modeles.dart';
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
}) {
  final alea = Random(graine);
  final depart = contenu.parcoursParId(parcours);
  if (depart == null) throw ArgumentError('parcours inconnu : $parcours');

  final denouements = <String, int>{};
  final vuesPartout = <String>{};
  var totalJours = 0;

  for (var p = 0; p < parties; p++) {
    var etat = EtatPartie(parcours: parcours, nomJoueur: 'Test', jauges: depart.depart);
    while (true) {
      final fin = evalue(etat, duree: duree);
      if (fin != null) {
        denouements.update(fin.type.name, (v) => v + 1, ifAbsent: () => 1);
        break;
      }
      final carte = choisitCarte(paquet: contenu.cartes, etat: etat, alea: alea);
      if (carte == null) {
        denouements.update('paquetEpuise', (v) => v + 1, ifAbsent: () => 1);
        break;
      }
      vuesPartout.add(carte.id);
      etat = repond(
        etat: etat,
        carte: carte,
        cote: _choisit(strategie, etat, carte, alea),
        atout: depart.atout,
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

Cote _choisit(Strategie s, EtatPartie etat, Carte carte, Random alea) => switch (s) {
      Strategie.toujoursGauche => Cote.gauche,
      Strategie.toujoursDroite => Cote.droite,
      Strategie.auHasard => alea.nextBool() ? Cote.gauche : Cote.droite,
      Strategie.equilibree => _versLeCentre(etat, carte),
    };

/// Joue le côté qui laisse les jauges le plus près du centre.
Cote _versLeCentre(EtatPartie etat, Carte carte) {
  int ecart(Reponse r) {
    final apres = etat.jauges.applique(r.effets);
    return Jauge.values.fold(0, (s, j) => s + (apres.valeur(j) - 50).abs());
  }

  return ecart(carte.gauche) <= ecart(carte.droite) ? Cote.gauche : Cote.droite;
}
