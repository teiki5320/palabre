import 'jauges.dart';
import 'modeles.dart';

/// Tout ce qui décrit un mandat en cours. Immuable : chaque réponse rend un
/// nouvel état, ce qui permet de rejouer et de tester une partie pas à pas.
class EtatPartie {
  const EtatPartie({
    required this.parcours,
    required this.nomJoueur,
    required this.jauges,
    this.jour = 1,
    this.mandat = 1,
    this.drapeaux = const {},
    this.vues = const {},
    this.chainesRang = const {},
    this.chainesJour = const {},
  });

  final String parcours;
  final String nomJoueur;
  final Jauges jauges;
  final int jour;
  final int mandat;

  /// Marques laissées par les réponses précédentes.
  final Set<String> drapeaux;

  /// Identifiants des cartes déjà sorties dans ce mandat.
  final Set<String> vues;

  /// Chaîne -> dernier rang joué.
  final Map<String, int> chainesRang;

  /// Chaîne -> jour du dernier rang joué.
  final Map<String, int> chainesJour;

  EtatPartie copie({
    Jauges? jauges,
    int? jour,
    int? mandat,
    Set<String>? drapeaux,
    Set<String>? vues,
    Map<String, int>? chainesRang,
    Map<String, int>? chainesJour,
  }) =>
      EtatPartie(
        parcours: parcours,
        nomJoueur: nomJoueur,
        jauges: jauges ?? this.jauges,
        jour: jour ?? this.jour,
        mandat: mandat ?? this.mandat,
        drapeaux: drapeaux ?? this.drapeaux,
        vues: vues ?? this.vues,
        chainesRang: chainesRang ?? this.chainesRang,
        chainesJour: chainesJour ?? this.chainesJour,
      );
}

/// Évaluation des conditions d'une carte contre l'état courant.
extension ConditionsSurEtat on Conditions {
  bool satisfaites(EtatPartie etat) {
    if (etat.mandat < mandatMin) return false;
    if (etat.jour < jourMin || etat.jour > jourMax) return false;
    for (final e in minimums.entries) {
      if (etat.jauges.valeur(e.key) < e.value) return false;
    }
    for (final e in maximums.entries) {
      if (etat.jauges.valeur(e.key) > e.value) return false;
    }
    for (final d in drapeauxRequis) {
      if (!etat.drapeaux.contains(d)) return false;
    }
    for (final d in drapeauxInterdits) {
      if (etat.drapeaux.contains(d)) return false;
    }
    if (parcours.isNotEmpty && !parcours.contains(etat.parcours)) return false;
    return true;
  }
}
