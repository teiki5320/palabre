import 'etat_partie.dart';
import 'jauges.dart';
import 'modeles.dart';

/// Le côté vers lequel le joueur a glissé la carte.
enum Cote { gauche, droite }

/// Multiplie les effets d'une réponse selon le mandat en cours : le jeu ne
/// crée pas de cartes propres au second mandat (le mécanisme `mandat_min`
/// s'en charge pour le contenu), il rend les mêmes cartes plus dures à
/// encaisser. Au premier mandat, rien ne change. Arrondi à l'entier le plus
/// proche, toujours borné à ±20 avant d'être appliqué aux jauges.
Map<Jauge, int> amplifie(Map<Jauge, int> effets, int mandat) {
  if (mandat <= 1) return effets;
  final facteur = mandat == 2 ? 1.25 : 1.5;
  return {
    for (final e in effets.entries) e.key: (e.value * facteur).round().clamp(-20, 20),
  };
}

/// Applique une réponse et rend l'état du lendemain.
EtatPartie repond({required EtatPartie etat, required Carte carte, required Cote cote}) {
  final reponse = cote == Cote.gauche ? carte.gauche : carte.droite;
  final effets = amplifie(reponse.effets, etat.mandat);

  final drapeaux = {...etat.drapeaux, ...reponse.drapeaux};
  final vues = {...etat.vues, carte.id};

  final chainesRang = {...etat.chainesRang};
  final chainesJour = {...etat.chainesJour};
  final ch = carte.chaine;
  if (ch != null) {
    chainesRang[ch.id] = ch.rang;
    chainesJour[ch.id] = etat.jour;
  }

  return etat.copie(
    jauges: etat.jauges.applique(effets),
    jour: etat.jour + 1,
    // L'axe du régime ne s'amplifie pas au fil des mandats : un abus de
    // pouvoir est un abus de pouvoir, qu'il soit le premier ou le dixième.
    style: (etat.style + reponse.style).clamp(0, 100),
    drapeaux: drapeaux,
    vues: vues,
    chainesRang: chainesRang,
    chainesJour: chainesJour,
  );
}
