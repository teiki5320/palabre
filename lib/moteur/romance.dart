// Ce qui se noue entre le président et quelqu'un qui entre dans son
// bureau. Une seconde mémoire, à côté de la loyauté, et rien à voir avec
// elle : on peut payer la solde du général sans rien vouloir de lui.
//
// La différence tient en une règle, et c'est la plus importante du
// fichier : **l'attache ne monte jamais toute seule**. La loyauté se lit
// dans les jauges qu'on déplace, sans que le joueur ait à y penser ;
// l'attache ne bouge que si une réponse la déclare. On ne se retrouve pas
// en liaison pour avoir bien géré un dossier.

/// Les six crans, de l'indifférence à la demande.
///
/// Ils ne se sautent pas : une carte qui demande le cran suivant ne sort
/// que si le précédent est atteint, ce qui donne à chaque histoire son
/// rythme et empêche de passer du premier regard au mariage en deux jours.
const int attacheRien = 0;

/// On se remarque. Un regard tenu une seconde de trop, rien de dit.
const int attacheRemarque = 1;

/// Un premier geste : un dîner qui s'éternise, une main qu'on ne retire pas.
const int attacheGeste = 2;

//// La liaison. C'est à partir d'ici que la chambre n'est plus vide.
const int attacheLiaison = 3;

//// On ne se cache plus vraiment. Le palais sait, la ville devine.
const int attacheOuverte = 4;

//// La demande. Le seul cran d'où part un mariage.
const int attacheDemande = 5;

const int attachePlancher = attacheRien;
const int attachePlafond = attacheDemande;

/// La proximité d'après, bornée. Rend la carte inchangée si rien ne bouge,
/// pour qu'un état ne se recopie pas à chaque réponse.
Map<String, int> appliqueAttache(Map<String, int> avant, String? qui, int mouvement) {
  if (qui == null || mouvement == 0) return avant;
  final v = ((avant[qui] ?? attacheRien) + mouvement).clamp(attachePlancher, attachePlafond);
  if (v == (avant[qui] ?? attacheRien)) return avant;
  return {...avant, qui: v};
}

/// Le cran atteint avec quelqu'un. Zéro pour tous ceux dont il n'est rien
/// arrivé — la carte vide est donc l'état normal.
int attacheAvec(Map<String, int> attache, String qui) => attache[qui] ?? attacheRien;

/// Avec qui la chose est allée le plus loin, et jusqu'où. Null tant que
/// personne n'a dépassé l'indifférence.
///
/// À égalité, on rend le premier dans l'ordre alphabétique : il faut bien
/// trancher, et une règle stable vaut mieux qu'un hasard qui changerait la
/// chambre d'un lancement à l'autre.
({String qui, int cran})? liaisonPrincipale(Map<String, int> attache) {
  String? meilleur;
  var haut = attacheRien;
  for (final e in attache.entries) {
    if (e.value > haut || (e.value == haut && meilleur != null && e.key.compareTo(meilleur) < 0)) {
      if (e.value <= attacheRien) continue;
      meilleur = e.key;
      haut = e.value;
    }
  }
  return meilleur == null ? null : (qui: meilleur, cran: haut);
}

/// Combien de liaisons courent en même temps, à partir du cran donné.
/// C'est ce qui permet à une carte de dire « deux personnes attendent une
/// réponse de vous, et elles se connaissent ».
int liaisonsAuMoins(Map<String, int> attache, int cran) =>
    attache.values.where((v) => v >= cran).length;

/// Le mariage. Le président commence célibataire : `EtatPartie.epouse` est
/// nul tant qu'il n'a pas dit oui, et les cartes du conjoint — celles qui
/// parlent du cabinet rouvert, de l'anniversaire oublié, de la sœur au
/// commissariat — ne sortent qu'ensuite. Ce n'est pas une fin, c'est un
/// paquet de cartes qui s'ouvre.
bool estMarie(String? epouse) => epouse != null;

/// Qui parle quand une carte dit « le conjoint ». Null si le président est
/// célibataire : la carte ne sort pas, faute de quelqu'un pour la dire.
String? conjointDe(String? epouse) => epouse;

/// Ce qu'une carte peut exiger de la romance, pour que le tirage n'ait pas
/// à connaître le détail des crans.
bool romanceSatisfaite({
  required Map<String, int> attache,
  required String? epouse,
  required String? personnage,
  String? attacheDe,
  int? attacheMin,
  int? attacheMax,
  bool? marie,
}) {
  if (marie != null && estMarie(epouse) != marie) return false;
  if (attacheMin == null && attacheMax == null) return true;
  final qui = attacheDe ?? personnage;
  if (qui == null) return false;
  final v = attacheAvec(attache, qui);
  if (attacheMin != null && v < attacheMin) return false;
  if (attacheMax != null && v > attacheMax) return false;
  return true;
}

/// Ce qu'une réponse déclare de la romance : un cran de plus, un cran de
/// moins, ou un mariage. Jamais déduit, toujours écrit.
class EffetRomance {
  const EffetRomance({this.mouvement = 0, this.de, this.epouse = false, this.rupture = false});

  /// Le déplacement de l'attache, de −5 à 5. Zéro pour l'immense majorité
  /// des cartes, qui ne parlent pas de ça.
  final int mouvement;

  /// De qui, si ce n'est pas le personnage de la carte.
  final String? de;

  /// Vrai pour la réponse qui épouse. Le moteur retient alors la personne
  /// visée, et le conjoint existe à partir du lendemain.
  final bool epouse;

  /// Vrai pour la réponse qui rompt tout : l'attache retombe à zéro, et un
  /// mariage se défait.
  final bool rupture;

  bool get vide => mouvement == 0 && !epouse && !rupture;

  factory EffetRomance.depuisJson(Map<String, dynamic>? j) {
    if (j == null) return const EffetRomance();
    return EffetRomance(
      mouvement: ((j['mouvement'] as num?) ?? 0).toInt().clamp(-attachePlafond, attachePlafond),
      de: j['de'] as String?,
      epouse: (j['epouse'] as bool?) ?? false,
      rupture: (j['rupture'] as bool?) ?? false,
    );
  }
}

/// Ce que la rupture laisse : l'attache de cette personne retombe à zéro,
/// celle des autres ne bouge pas. On ne rompt qu'avec quelqu'un.
Map<String, int> apresRupture(Map<String, int> avant, String? qui) {
  if (qui == null || !avant.containsKey(qui)) return avant;
  final apres = {...avant}..remove(qui);
  return apres;
}

/// L'état de la chambre, que le décor lira. Rien d'explicite ici : le
/// moteur dit seulement s'il y a quelqu'un, et depuis quand.
enum Chambre {
  /// Personne. Le lit fait d'un seul côté.
  seule,

  /// Quelqu'un est passé, sans rester. Deux verres, un châle sur la chaise.
  visitee,

  /// On y dort à deux, et le palais le sait.
  partagee,
}

/// Avec qui l'on partage la chambre, ou null. Le conjoint d'abord — on ne
/// met pas son amant dans le lit conjugal — puis la liaison la plus
/// avancée, à partir du cran où elle n'est plus un regard.
String? partenaire(Map<String, int> attache, String? epouse) {
  if (epouse != null) return epouse;
  final l = liaisonPrincipale(attache);
  return (l != null && l.cran >= attacheLiaison) ? l.qui : null;
}

Chambre chambreSelon(Map<String, int> attache, String? epouse) {
  if (estMarie(epouse)) return Chambre.partagee;
  final l = liaisonPrincipale(attache);
  if (l == null) return Chambre.seule;
  if (l.cran >= attacheOuverte) return Chambre.partagee;
  if (l.cran >= attacheLiaison) return Chambre.visitee;
  return Chambre.seule;
}
