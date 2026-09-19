import 'jauges.dart';
import 'modeles.dart';

/// Ce que les gens du palais retiennent de vous, et ce que l'opposition
/// devient pendant que vous gouvernez. Deux mémoires, et rien d'autre : le
/// reste du moteur les lit, il ne les fabrique pas.

// ─────────────────────────── la loyauté ───────────────────────────

/// Bornes de la loyauté d'un personnage. Cinq crans de chaque côté : assez
/// pour que trois refus de suite se sentent, pas assez pour qu'un mandat
/// entier se résume à un chiffre.
const int loyautePlancher = -5;
const int loyautePlafond = 5;

/// Ce qu'une réponse change à la loyauté du personnage qui l'a demandée.
///
/// Rien n'est déclaré dans les cartes : on regarde ce que la décision fait
/// à **la jauge que ce personnage défend**. Le général défend l'armée, la
/// commerçante le peuple, la rédactrice la presse. Aller dans leur sens les
/// rapproche, les contrarier les éloigne — et une décision qui ne les touche
/// pas ne change rien.
///
/// C'est ce qui permet aux quatre cent trente-quatre cartes déjà écrites de
/// nourrir la mémoire sans qu'on en retouche une seule.
int mouvementLoyaute({required Personnage? qui, required Map<Jauge, int> effetsReels}) {
  final jauge = qui?.jauge;
  if (jauge == null) return 0;
  final v = effetsReels[jauge] ?? 0;
  if (v > 2) return 1;
  if (v < -2) return -1;
  return 0;
}

/// La loyauté d'après, bornée. Rend la carte inchangée si rien ne bouge.
Map<String, int> appliqueLoyaute(Map<String, int> avant, String? qui, int mouvement) {
  if (qui == null || mouvement == 0) return avant;
  final v = ((avant[qui] ?? 0) + mouvement).clamp(loyautePlancher, loyautePlafond);
  return {...avant, qui: v};
}

// ────────────────────────── l'adversaire ──────────────────────────

/// Celui qui se présentera contre vous au centième jour. Tiré au sort au
/// premier jour, il ne change plus, et il grandit de vos fautes.
class Adversaire {
  const Adversaire({
    required this.id,
    required this.nom,
    required this.titre,
    required this.accroche,
    this.forceDepart = 50,
  });

  final String id;
  final String nom;

  /// Ce qu'il était avant de vouloir votre place.
  final String titre;

  /// Une ligne, celle qu'on montre au joueur le premier jour.
  final String accroche;

  /// Où commence sa force. Cinquante pour tous : c'est le seuil que
  /// l'élection utilisait avant qu'il existe, donc rien ne change tant
  /// qu'on ne lui donne pas de quoi monter.
  final int forceDepart;

  factory Adversaire.depuisJson(Map<String, dynamic> j) => Adversaire(
        id: j['id'] as String,
        nom: j['nom'] as String,
        titre: j['titre'] as String,
        accroche: j['accroche'] as String,
        forceDepart: ((j['force_depart'] as num?) ?? 50).toInt(),
      );
}

/// Où commence l'opposition : cinquante, le seuil que l'élection utilisait
/// quand il n'y avait personne en face. Tant que le joueur ne la nourrit
/// pas, rien ne change de ce qu'on jouait avant.
const int forceDepart = 50;

const int forcePlancher = 20;
const int forcePlafond = 85;

/// Ce que l'opposition gagne ou perd d'une décision.
///
/// Elle ne vit pas de vos jauges, elle vit de ce que vous **perdez** devant
/// le pays : ce qui coûte du peuple ou de la presse la nourrit, ce qui en
/// rapporte l'affame. L'armée et les caisses ne la regardent pas — un
/// opposant ne fait pas campagne sur l'état d'un coffre.
///
/// Le rapport est de un pour quatre : il faut perdre une quinzaine de points
/// de peuple pour lui en donner quatre. Sur cent jours, un président qui se
/// tient bien le laisse sous cinquante, un président qui dérape le voit
/// passer soixante-dix.
int mouvementForce(Map<Jauge, int> effetsReels) {
  final devantLePays = (effetsReels[Jauge.peuple] ?? 0) + (effetsReels[Jauge.presse] ?? 0);
  if (devantLePays == 0) return 0;
  // Division entière vers zéro : un mouvement de moins de quatre points ne
  // déplace rien, ce qui évite que chaque carte grignote l'élection.
  return -(devantLePays ~/ 4);
}

int appliqueForce(int avant, int mouvement) => (avant + mouvement).clamp(forcePlancher, forcePlafond);

/// Ce qu'une réélection lui coûte. Il ne disparaît pas — c'est le même
/// pays, le même homme, et les cartes continuent de le nommer — mais il
/// vient de perdre devant tout le monde : la moitié du terrain qu'il avait
/// pris vous revient. Sans cela, un opposant monté à soixante-dix rendrait
/// le second mandat injouable dès le premier jour, les jauges repartant du
/// départ du parcours.
int forceApresDefaite(int force) => forceDepart + ((force - forceDepart) ~/ 2);
