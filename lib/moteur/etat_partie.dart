import 'jauges.dart';
import 'memoire.dart';
import 'romance.dart';
import 'modeles.dart';

/// Tout ce qui décrit un mandat en cours. Immuable : chaque réponse rend un
/// nouvel état, ce qui permet de rejouer et de tester une partie pas à pas.
/// Le mandat commence au milieu de l'axe : ni vertueux ni corrompu, un État
/// ordinaire. C'est aussi le point où le régime ne change rien aux
/// décisions — il ne pèse que si le joueur l'a fait pencher.
const int styleDepart = 50;

class EtatPartie {
  const EtatPartie({
    required this.parcours,
    required this.nomJoueur,
    required this.jauges,
    this.jour = 1,
    this.mandat = 1,
    this.style = styleDepart,
    this.drapeaux = const {},
    this.vues = const {},
    this.chainesRang = const {},
    this.chainesJour = const {},
    this.hier,
    this.loyaute = const {},
    this.adversaire,
    this.force = forceDepart,
    this.attache = const {},
    this.epouse,
  });

  final String parcours;
  final String nomJoueur;
  final Jauges jauges;
  final int jour;
  final int mandat;

  /// Où en est le mandat entre la république et la dictature, de 0 à 100.
  /// Ce n'est pas une jauge : aucun des deux bouts ne tue. C'est le chemin
  /// qu'on a pris sans jamais le décider d'un coup, et ce que la fin dira.
  final int style;

  /// Marques laissées par les réponses précédentes.
  final Set<String> drapeaux;

  /// Identifiants des cartes déjà sorties dans ce mandat.
  final Set<String> vues;

  /// Chaîne -> dernier rang joué.
  final Map<String, int> chainesRang;

  /// Chaîne -> jour du dernier rang joué.
  final Map<String, int> chainesJour;

  /// La carte d'hier, pour que le tirage n'envoie pas la même personne
  /// deux jours de suite ; null au premier jour.
  final String? hier;

  /// Ce que chaque personnage retient de vous, de −5 à +5. Personne n'y
  /// figure tant qu'il n'a rien à retenir.
  final Map<String, int> loyaute;

  /// Qui se présentera contre vous au centième jour, tiré au sort le
  /// premier. Null dans les parties d'avant l'opposition.
  final String? adversaire;

  /// Sa force, de 20 à 85. Elle part de 50 — le seuil que l'élection
  /// utilisait quand il n'y avait personne en face.
  final int force;

  /// Où en est ce qui se noue avec chacun, de 0 à 5. Contrairement à la
  /// loyauté, rien n'y entre sans que le joueur l'ait choisi sur une carte.
  final Map<String, int> attache;

  /// Qui le président a épousé, ou null : il commence célibataire, et le
  /// reste tant qu'il n'a pas dit oui. C'est cette personne que les cartes
  /// du conjoint font parler.
  final String? epouse;

  EtatPartie copie({
    Jauges? jauges,
    int? jour,
    int? mandat,
    int? style,
    Set<String>? drapeaux,
    Set<String>? vues,
    Map<String, int>? chainesRang,
    Map<String, int>? chainesJour,
    String? hier,
    Map<String, int>? loyaute,
    String? adversaire,
    int? force,
    Map<String, int>? attache,
    String? epouse,
    bool celibataire = false,
  }) =>
      EtatPartie(
        parcours: parcours,
        nomJoueur: nomJoueur,
        jauges: jauges ?? this.jauges,
        jour: jour ?? this.jour,
        mandat: mandat ?? this.mandat,
        style: style ?? this.style,
        drapeaux: drapeaux ?? this.drapeaux,
        vues: vues ?? this.vues,
        chainesRang: chainesRang ?? this.chainesRang,
        chainesJour: chainesJour ?? this.chainesJour,
        hier: hier ?? this.hier,
        loyaute: loyaute ?? this.loyaute,
        adversaire: adversaire ?? this.adversaire,
        force: force ?? this.force,
        attache: attache ?? this.attache,
        // Un mariage ne se défait qu'en le demandant : sans le drapeau,
        // `copie` ne peut que garder ou remplacer l'époux, jamais l'effacer
        // par omission.
        epouse: celibataire ? null : (epouse ?? this.epouse),
      );
}

/// Évaluation des conditions d'une carte contre l'état courant.
extension ConditionsSurEtat on Conditions {
  /// [personnage] est celui qui parle sur la carte : c'est de lui qu'on
  /// exige une loyauté quand la carte ne nomme personne d'autre.
  bool satisfaites(EtatPartie etat, {String? personnage}) {
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
    if (parcoursInterdits.contains(etat.parcours)) return false;
    if (etat.style < styleMin || etat.style > styleMax) return false;

    final plancher = loyauteMin;
    final plafond = loyauteMax;
    if (plancher != null || plafond != null) {
      final qui = loyauteDe ?? personnage;
      if (qui == null) return false;
      final v = etat.loyaute[qui] ?? 0;
      if (plancher != null && v < plancher) return false;
      if (plafond != null && v > plafond) return false;
    }

    if (!romanceSatisfaite(
      attache: etat.attache,
      epouse: etat.epouse,
      personnage: personnage,
      attacheDe: attacheDe,
      attacheMin: attacheMin,
      attacheMax: attacheMax,
      marie: marie,
    )) {
      return false;
    }

    if (adversaire.isNotEmpty && !adversaire.contains(etat.adversaire)) return false;
    final forceBas = forceMin;
    final forceHaut = forceMax;
    if (forceBas != null && etat.force < forceBas) return false;
    if (forceHaut != null && etat.force > forceHaut) return false;
    return true;
  }
}
