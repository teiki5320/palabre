import 'etat_partie.dart';
import 'modeles.dart';

/// Le côté vers lequel le joueur a glissé la carte.
enum Cote { gauche, droite }

/// Applique une réponse et rend l'état du lendemain.
EtatPartie repond({required EtatPartie etat, required Carte carte, required Cote cote}) {
  final reponse = cote == Cote.gauche ? carte.gauche : carte.droite;

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
    jauges: etat.jauges.applique(reponse.effets),
    jour: etat.jour + 1,
    drapeaux: drapeaux,
    vues: vues,
    chainesRang: chainesRang,
    chainesJour: chainesJour,
  );
}
