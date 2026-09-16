import 'dart:math';

import 'etat_partie.dart';
import 'modeles.dart';

/// Choisit la carte du jour, ou null si plus rien n'est jouable.
Carte? choisitCarte({required List<Carte> paquet, required EtatPartie etat, required Random alea}) {
  final jouables = <Carte>[];
  for (final c in paquet) {
    if (!c.repetable && etat.vues.contains(c.id)) continue;
    if (!c.conditions.satisfaites(etat)) continue;
    final ch = c.chaine;
    if (ch != null) {
      final rangAtteint = etat.chainesRang[ch.id] ?? 0;
      if (ch.rang != rangAtteint + 1) continue;
      final dernierJour = etat.chainesJour[ch.id];
      if (dernierJour != null && etat.jour - dernierJour < ch.delaiMin) continue;
    }
    jouables.add(c);
  }
  if (jouables.isEmpty) return null;

  // On prête serment avant de gouverner : au tout premier jour d'un premier
  // mandat, la carte d'ouverture passe avant tout le reste. Aux mandats
  // suivants elle ne revient pas — on ne rejure pas ce qu'on a déjà juré.
  if (etat.jour == 1 && etat.mandat == 1) {
    for (final c in jouables) {
      if (c.ouverture) return c;
    }
  }

  // Une histoire commencée passe avant une situation ordinaire : seule une
  // suite de chaîne (rang > 1) est prioritaire, pas la carte de rang 1 qui
  // l'ouvre, qui sort comme une carte ordinaire, au hasard pondéré.
  final maillons = jouables.where((c) => (c.chaine?.rang ?? 0) > 1).toList();
  return _tirePondere(maillons.isNotEmpty ? maillons : jouables, alea);
}

Carte _tirePondere(List<Carte> cartes, Random alea) {
  final total = cartes.fold<int>(0, (s, c) => s + (c.poids < 1 ? 1 : c.poids));
  var seuil = alea.nextInt(total);
  for (final c in cartes) {
    seuil -= c.poids < 1 ? 1 : c.poids;
    if (seuil < 0) return c;
  }
  return cartes.last;
}
