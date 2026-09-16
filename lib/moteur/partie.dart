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

/// Les jauges que le régime favorise quand le mandat penche d'un côté.
/// Une république tient par le peuple et par une armée qui reste à sa
/// place ; une dictature tient par l'argent et par une presse qui dit ce
/// qu'on lui souffle. Ce que l'un ménage, l'autre l'abîme.
const _favoriteesRepublique = {Jauge.peuple, Jauge.armee};
const _favoriteesDictature = {Jauge.caisses, Jauge.presse};

/// Ce que le régime change à une décision. Le mandat ne pousse jamais une
/// jauge tout seul — un bonus quotidien finirait par la coller au plafond,
/// qui tue autant que le plancher. Il change seulement ce que coûte ou
/// rapporte chaque choix : au bout de l'axe, les jauges du camp encaissent
/// moitié moins et gagnent moitié plus, celles d'en face l'inverse.
Map<Jauge, int> selonRegime(Map<Jauge, int> effets, int style) {
  final ecart = style - 50;
  if (ecart == 0) return effets;
  final intensite = (ecart.abs() / 50).clamp(0.0, 1.0);
  final favorisees = ecart > 0 ? _favoriteesDictature : _favoriteesRepublique;
  return {
    for (final e in effets.entries)
      e.key: () {
        final bienVue = favorisees.contains(e.key);
        final gain = e.value > 0;
        // Un gain sur une jauge du camp compte plus, une perte compte
        // moins ; sur une jauge d'en face, c'est exactement l'inverse.
        final facteur = bienVue == gain ? 1 + 0.5 * intensite : 1 - 0.5 * intensite;
        final v = (e.value * facteur).round();
        // Un effet ne disparaît jamais complètement : il reste au moins un
        // point, sinon une décision n'aurait plus aucune conséquence.
        return v == 0 ? (e.value > 0 ? 1 : -1) : v;
      }(),
  };
}

/// L'atout du parcours amortit sa jauge dans les deux sens : elle gagne
/// moins et perd moins, donc elle reste loin des deux bords, et les deux
/// bords tuent. Il s'applique en dernier, sur le chiffre que le joueur va
/// réellement subir.
Map<Jauge, int> selonAtout(Map<Jauge, int> effets, Atout? atout) {
  if (atout == null) return effets;
  final mouvement = effets[atout.jauge];
  if (mouvement == null) return effets;
  final amorti = (mouvement * atout.part).round();
  // Un effet ne disparaît jamais tout à fait : une décision garde toujours
  // une conséquence, même sur la jauge que le parcours protège.
  return {...effets, atout.jauge: amorti == 0 ? (mouvement > 0 ? 1 : -1) : amorti};
}

/// Ce qu'une réponse fait vraiment : régime, mandat et atout compris. C'est
/// ce que l'écran montre pendant le geste, et ce que le moteur applique —
/// le joueur ne doit jamais voir un chiffre différent de celui qu'il va
/// subir.
Map<Jauge, int> effetsReels({
  required Map<Jauge, int> effets,
  required int style,
  required int mandat,
  Atout? atout,
}) {
  final reels = selonAtout(amplifie(selonRegime(effets, style), mandat), atout);
  // Borné ici, en sortie, et nulle part ailleurs : le régime seul pouvait
  // porter un effet à 30 au premier mandat, alors que l'amplification du
  // second le ramenait à 20 — le second mandat frappait moins fort.
  return {for (final e in reels.entries) e.key: e.value.clamp(-20, 20)};
}

/// Applique une réponse et rend l'état du lendemain.
EtatPartie repond({
  required EtatPartie etat,
  required Carte carte,
  required Cote cote,
  Atout? atout,
}) {
  final reponse = cote == Cote.gauche ? carte.gauche : carte.droite;
  final effets = effetsReels(
    effets: reponse.effets,
    style: etat.style,
    mandat: etat.mandat,
    atout: atout,
  );

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
