import 'etat_partie.dart';
import 'jauges.dart';

/// Les cinq pièces du palais. L'ordre est celui de la visite : on arrive au
/// bureau, on en repart vers les autres.
enum Piece { bureau, balcon, chambre, garage, piscine }

Piece? pieceParId(String id) {
  for (final p in Piece.values) {
    if (p.name == id) return p;
  }
  return null;
}

extension NomDePiece on Piece {
  String get nom => switch (this) {
        Piece.bureau => 'Le bureau',
        Piece.balcon => 'Le balcon',
        Piece.chambre => 'La chambre',
        Piece.garage => 'La cour des voitures',
        Piece.piscine => 'La piscine',
      };
}

/// Un objet du palais : ce qu'on achète avec l'argent de l'État, et qui
/// reste acquis d'un mandat à l'autre.
///
/// Les objets ne codent rien : un objet qui « ouvre du contenu » pose
/// seulement son drapeau `objet_<id>`, et ce sont les cartes qui décident
/// d'apparaître grâce à `drapeaux_requis`. Le moteur n'a donc pas une ligne
/// à savoir du catalogue.
class Objet {
  const Objet({
    required this.id,
    required this.piece,
    required this.nom,
    required this.description,
    required this.prix,
    this.natures = const [],
    this.effetAchat = const {},
    this.styleAchat = 0,
  });

  final String id;
  final Piece piece;
  final String nom;
  final String description;

  /// En points de caisses, pris sur la partie en cours.
  final int prix;

  /// « decor », « contenu », « bonus » — pour l'affichage seulement.
  final List<String> natures;

  /// Ce que l'achat fait aux jauges, une seule fois, au moment de payer.
  final Map<Jauge, int> effetAchat;

  /// Ce que l'achat décale sur l'axe du régime, une seule fois.
  final int styleAchat;

  /// Le drapeau que l'objet pose dans la partie. C'est par lui que les
  /// cartes conditionnées apparaissent.
  String get drapeau => 'objet_$id';

  static Jauge? _jauge(String nom) {
    for (final j in Jauge.values) {
      if (j.name == nom) return j;
    }
    return null;
  }

  factory Objet.depuisJson(Map<String, dynamic> j) {
    final piece = pieceParId(j['piece'] as String);
    if (piece == null) throw FormatException('Pièce inconnue : ${j['piece']}');
    final effets = <Jauge, int>{};
    for (final e in ((j['effet_achat'] as Map?) ?? const {}).entries) {
      final jauge = _jauge(e.key as String);
      if (jauge == null) throw FormatException('Jauge inconnue : ${e.key}');
      effets[jauge] = (e.value as num).toInt();
    }
    return Objet(
      id: j['id'] as String,
      piece: piece,
      nom: j['nom'] as String,
      description: j['description'] as String,
      prix: (j['prix'] as num).toInt(),
      natures: ((j['natures'] as List?) ?? const []).cast<String>(),
      effetAchat: effets,
      styleAchat: ((j['style_achat'] as num?) ?? 0).toInt(),
    );
  }
}

/// On n'achète jamais au point de se tuer : un achat qui ferait tomber les
/// caisses sous ce seuil est refusé. C'est le seul garde-fou du palais, et
/// il est volontairement bas — on doit pouvoir se ruiner, pas se suicider
/// par distraction.
const int plancherAchat = 15;

/// Ce que le coffre-fort rend, la première fois que les caisses passent
/// sous [seuilCoffre]. Une seule fois par mandat : c'est un filet, pas une
/// rente. Un vrai plancher permanent supprimerait la mort par les caisses,
/// qui clôt aujourd'hui un mandat sur sept.
const int seuilCoffre = 10;
const int renfortCoffre = 10;
const String drapeauCoffre = 'objet_coffre_fort';
const String drapeauCoffreOuvert = 'coffre_ouvert';

/// Peut-on acheter cet objet maintenant ? Non s'il est déjà au palais, non
/// si le prix laisse les caisses sous le plancher.
bool achetable(EtatPartie etat, Objet objet, Set<String> possedes) =>
    !possedes.contains(objet.id) && etat.jauges.caisses - objet.prix >= plancherAchat;

/// L'état après un achat : les caisses paient, l'effet unique s'applique,
/// le régime bouge s'il y a lieu, et le drapeau de l'objet est posé pour
/// que les cartes qu'il ouvre puissent sortir dès le lendemain.
EtatPartie achete(EtatPartie etat, Objet objet) {
  final effets = <Jauge, int>{
    ...objet.effetAchat,
    Jauge.caisses: (objet.effetAchat[Jauge.caisses] ?? 0) - objet.prix,
  };
  return etat.copie(
    jauges: etat.jauges.applique(effets),
    style: (etat.style + objet.styleAchat).clamp(0, 100),
    drapeaux: {...etat.drapeaux, objet.drapeau},
  );
}

/// Les drapeaux qu'un mandat commence avec, d'après ce que le palais
/// contient déjà. C'est ce qui fait qu'un objet acheté au premier mandat
/// ouvre encore ses cartes au quatrième.
Set<String> drapeauxDuPalais(Set<String> objetsPossedes) => {
      for (final id in objetsPossedes) 'objet_$id',
    };

/// Le coffre-fort s'ouvre, si le palais en a un, s'il n'a pas déjà servi,
/// et si les caisses viennent de passer sous le seuil. Rend l'état tel
/// quel dans tous les autres cas.
EtatPartie coffreSiBesoin(EtatPartie etat) {
  if (!etat.drapeaux.contains(drapeauCoffre)) return etat;
  if (etat.drapeaux.contains(drapeauCoffreOuvert)) return etat;
  if (etat.jauges.caisses >= seuilCoffre) return etat;
  return etat.copie(
    jauges: etat.jauges.applique({Jauge.caisses: renfortCoffre}),
    drapeaux: {...etat.drapeaux, drapeauCoffreOuvert},
  );
}
