import 'etat_partie.dart';
import 'jauges.dart';
import 'memoire.dart';
import 'modeles.dart';
import 'romance.dart';
import 'palais.dart';

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
/// Ce que le régime ajoute ou retire à un effet, au bout de l'axe. À un
/// demi, un républicain aimé du peuple était renversé pour l'avoir trop
/// été dans une partie sur deux ; à trois dixièmes, le bord reste un danger
/// qu'on voit venir.
const double regimePoids = 0.3;

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
        final facteur = bienVue == gain ? 1 + regimePoids * intensite : 1 - regimePoids * intensite;
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
///
/// [qui] est le personnage tel que ce joueur le voit — c'est de lui qu'on
/// tire la jauge à laquelle il tient, donc ce que la réponse change à sa
/// loyauté. Facultatif : sans lui, personne ne retient rien, et le moteur
/// se comporte comme avant la mémoire.
EtatPartie repond({
  required EtatPartie etat,
  required Carte carte,
  required Cote cote,
  Atout? atout,
  Personnage? qui,
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

  // Deux mémoires se mettent à jour ici, et nulle part ailleurs : ce que
  // l'interlocuteur du jour retient de la réponse, et ce que l'opposition
  // en tire. Ni l'une ni l'autre n'est déclarée dans les cartes — elles se
  // lisent dans les effets que le joueur vient de subir.
  final loyaute = appliqueLoyaute(
    etat.loyaute,
    carte.personnage,
    mouvementLoyaute(qui: qui, effetsReels: effets),
  );
  final force = appliqueForce(etat.force, mouvementForce(effets));

  // La romance, elle, ne se déduit de rien : seule la réponse la déclare.
  // Une rupture efface l'attache de la personne visée et défait le mariage
  // s'il s'agissait d'elle ; un oui retient qui l'on vient d'épouser.
  final r = reponse.romance;
  final vise = r.de ?? carte.personnage;
  var attache = etat.attache;
  var epouse = etat.epouse;
  var celibataire = false;
  if (r.rupture) {
    attache = apresRupture(attache, vise);
    if (epouse == vise) celibataire = true;
  } else if (r.mouvement != 0) {
    attache = appliqueAttache(attache, vise, r.mouvement);
  }
  if (r.epouse) epouse = vise;

  final apres = etat.copie(
    jauges: etat.jauges.applique(effets),
    loyaute: loyaute,
    force: force,
    attache: attache,
    epouse: epouse,
    celibataire: celibataire,
    jour: etat.jour + 1,
    // L'axe du régime ne s'amplifie pas au fil des mandats : un abus de
    // pouvoir est un abus de pouvoir, qu'il soit le premier ou le dixième.
    style: (etat.style + reponse.style).clamp(0, 100),
    drapeaux: drapeaux,
    vues: vues,
    chainesRang: chainesRang,
    chainesJour: chainesJour,
    hier: carte.id,
  );

  // Le coffre-fort, s'il y en a un au palais, s'ouvre tout seul le jour où
  // les caisses passent sous le seuil — une fois, et une seule.
  return coffreSiBesoin(apres);
}

/// Le mandat suivant, après une réélection. Le pays se souvient : le régime
/// qu'on a installé, ce qu'on a fait et ce qu'on a déjà vu restent, seules
/// les jauges repartent du départ du parcours. C'est ce qui permet aux cartes du second mandat
/// de revenir sur le premier.
EtatPartie mandatSuivant(EtatPartie etat, Parcours parcours) => EtatPartie(
      parcours: etat.parcours,
      nomJoueur: etat.nomJoueur,
      jauges: parcours.depart,
      jour: 1,
      mandat: etat.mandat + 1,
      style: etat.style,
      drapeaux: etat.drapeaux,
      // Les cartes jouées ne reviennent pas : un second mandat est fait de
      // ce qu'on n'a pas encore vu, et une histoire en cours reprend où
      // elle en était — son délai est réputé écoulé.
      vues: etat.vues,
      chainesRang: etat.chainesRang,
      // Ce qui s'est noué ne se dénoue pas à l'élection : on rempile avec
      // les mêmes gens, et marié si on l'était.
      attache: etat.attache,
      epouse: etat.epouse,
      // On ne repart pas parmi des inconnus : ceux qui vous ont vu décider
      // cent jours durant s'en souviennent, et celui d'en face aussi.
      loyaute: etat.loyaute,
      adversaire: etat.adversaire,
      force: forceApresDefaite(etat.force),
    );
