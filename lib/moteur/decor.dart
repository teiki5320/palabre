import 'etat_partie.dart';
import 'jauges.dart';
import 'palais.dart';
import 'romance.dart';

/// Quelle image le palais montre, pour une pièce et un état de partie.
///
/// Tout est ici, et nulle part ailleurs : l'ordre des règles est l'ordre de
/// priorité, la première qui s'applique gagne. C'est volontaire — l'émeute
/// l'emporte sur la liesse, et la ville éteinte sur l'avenue ordinaire,
/// parce qu'un pays en feu n'est pas « aussi » un pays qui circule.
///
/// Rien ici ne connaît Flutter : la règle se teste sans écran.
class Decor {
  const Decor({
    required this.dossier,
    required this.etat,
    required this.nom,
    this.images = 1,
    this.allerRetour = false,
    this.ratio = ratioPlaque,
  });

  /// Le chemin sous `assets/images/palais/`, sans le numéro d'image.
  final String dossier;

  /// L'identifiant de l'état, pour les tests et les traces.
  final String etat;

  /// Ce qu'on en dirait à voix haute.
  final String nom;

  /// Combien d'images composent la boucle : six pour le balcon, une pour
  /// les pièces, qui s'animent autrement.
  final int images;

  /// Vrai quand la boucle se joue en aller-retour : 1, 2, 3, 4, 5, 6, puis
  /// 5, 4, 3, 2 avant de repartir. C'est ce qu'il faut pour des images
  /// tirées d'un plan filmé, où la dernière ne ressemble plus du tout à la
  /// première : jouées en rond, elles feraient un raccord sec toutes les
  /// huit secondes. En repassant par où elle est venue, la boucle n'a plus
  /// de couture du tout, et pas une image de plus à livrer.
  final bool allerRetour;

  /// La forme de la plaque. Presque tout le palais est en trois-deux, et
  /// l'écran en montre moins d'un tiers à la fois ; la scène du lit est en
  /// trois-quatre, et remplit alors l'écran du téléphone sans qu'on ait
  /// rien à déplacer du doigt.
  final double ratio;

  String chemin(int i) =>
      images == 1 ? 'assets/images/palais/$dossier.jpg' : 'assets/images/palais/$dossier/k$i.jpg';

  /// Combien de pas compte un tour complet. Une boucle en rond en compte
  /// autant qu'elle a d'images ; une boucle en aller-retour en compte
  /// presque le double, sans repasser deux fois par les deux bouts.
  int get pas => allerRetour && images > 1 ? images * 2 - 2 : images;

  /// L'image à montrer au pas [j], de 0 à [pas] − 1, en base 1 comme
  /// [chemin] l'attend.
  int cle(int j) {
    final p = pas;
    final i = ((j % p) + p) % p;
    return (allerRetour && images > 1 && i >= images ? images * 2 - 2 - i : i) + 1;
  }
}

/// Vrai entre le quatre-vingtième jour et la fin : c'est la seule chose qui
/// fait tomber la nuit sur le palais. Le jeu n'a pas d'horloge — la nuit
/// n'est pas une heure, c'est la fin d'un mandat qui approche et qu'on ne
/// dort plus.
bool estNuit(EtatPartie etat) => etat.jour >= 80;

/// Les dix états de la place, dans leur ordre de priorité.
Decor decorDuBalcon(EtatPartie etat) {
  final j = etat.jauges;
  final heure = estNuit(etat) ? 'nuit' : 'jour';

  // Les deux états de cérémonie passent avant tout le reste : ils sont
  // posés par une carte, donc ils décrivent un jour précis, pas une
  // situation durable. Ils n'existent que de jour.
  if (etat.drapeaux.contains('fete_nationale')) {
    return const Decor(dossier: 'balcon/jour/defile', etat: 'defile', nom: 'Le défilé', images: 6, allerRetour: true);
  }
  if (etat.drapeaux.contains('deuil_national')) {
    return const Decor(
      dossier: 'balcon/jour/deuil',
      etat: 'deuil',
      nom: 'Le deuil national',
      images: 6,
      allerRetour: true,
    );
  }

  String d(String nom) => 'balcon/$heure/$nom';

  if (j.peuple <= 25) {
    return Decor(dossier: d('emeute'), etat: 'emeute', nom: "L'émeute", images: 6, allerRetour: true);
  }
  if (j.armee >= 70) {
    return Decor(
      dossier: d('verrouillee'),
      etat: 'verrouillee',
      nom: "L'avenue verrouillée",
      images: 6,
      allerRetour: true,
    );
  }
  if (j.caisses <= 25) {
    return Decor(dossier: d('eteinte'), etat: 'eteinte', nom: 'La ville éteinte', images: 6, allerRetour: true);
  }
  if (j.presse <= 25) {
    return Decor(
      dossier: d('cameras'),
      etat: 'cameras',
      nom: 'Le siège des caméras',
      images: 6,
      allerRetour: true,
    );
  }
  if (j.peuple >= 70) {
    return Decor(dossier: d('liesse'), etat: 'liesse', nom: 'La liesse', images: 6, allerRetour: true);
  }
  if (j.caisses >= 65 && j.peuple >= 55) {
    return Decor(
      dossier: d('prospere'),
      etat: 'prospere',
      nom: "L'avenue prospère",
      images: 6,
      allerRetour: true,
    );
  }
  if (etat.jour >= 55 && etat.jour <= 75) {
    return Decor(
      dossier: d('pluies'),
      etat: 'pluies',
      nom: 'La saison des pluies',
      images: 6,
      allerRetour: true,
    );
  }
  return Decor(
    dossier: d('ordinaire'),
    etat: 'ordinaire',
    nom: "L'avenue ordinaire",
    images: 6,
    allerRetour: true,
  );
}

Decor decorDuBureau(EtatPartie etat) {
  if (etat.jauges.presse <= 30) {
    return const Decor(dossier: 'pieces/bureau_enseveli', etat: 'enseveli', nom: 'Enseveli');
  }
  if (etat.style >= 70) {
    return const Decor(dossier: 'pieces/bureau_chef', etat: 'chef', nom: 'Le palais du chef');
  }
  if (etat.style <= 30) {
    return const Decor(dossier: 'pieces/bureau_ouvert', etat: 'ouvert', nom: 'La porte ouverte');
  }
  return const Decor(dossier: 'pieces/bureau_base', etat: 'base', nom: 'Le bureau de travail');
}

/// Ceux dont la chambre existe en images. C'est la liste des dix qu'on peut
/// courtiser : une personne qui n'y figure pas n'a pas de plaque, et la
/// chambre reste celle d'un célibataire plutôt que de pointer sur un
/// fichier absent.
const _chambresPartagees = {
  'redactrice', 'cabinet', 'emissaire', 'militante', 'epouse',
  'international', 'ministre', 'renseignements', 'maire', 'epoux',
};

/// Le drapeau qu'une carte de rendez-vous pose, et que la chambre
/// consomme quand la soirée est finie. Il nomme la personne : sans ça, un
/// président qui a deux liaisons en cours verrait arriver celle qui ne
/// l'avait pas invité.
String drapeauRendezVous(String qui) => 'rdv_$qui';

/// La personne qui attend ce soir, d'après les drapeaux posés, ou null.
String? invitationDe(Set<String> drapeaux) {
  for (final qui in _chambresPartagees) {
    if (drapeaux.contains(drapeauRendezVous(qui))) return qui;
  }
  return null;
}

/// Une soirée promise : la personne attend, habillée, et rien ne bouge
/// tant que le joueur ne touche pas l'écran. C'est la seule scène du
/// palais qui avance au doigt plutôt qu'à l'horloge.
class RendezVous {
  const RendezVous({required this.qui, required this.debout, required this.lit});

  final String qui;

  /// Les quatre poses debout, celles de la chambre partagée : la première
  /// habillée, les trois suivantes jouées d'une traite au premier appui.
  final Decor debout;

  /// La boucle sur le lit, en portrait, au second appui.
  final Decor lit;
}

/// Le rendez-vous de ce soir, ou null : sans le drapeau, sans partenaire,
/// ou avec quelqu'un dont la chambre n'existe pas en images.
RendezVous? rendezVousDe(EtatPartie etat) {
  final qui = invitationDe(etat.drapeaux);
  if (qui == null) return null;
  return RendezVous(
    qui: qui,
    debout: Decor(
      dossier: 'pieces/chambre_conjoint/$qui',
      etat: 'rdv_debout_$qui',
      nom: 'Ce soir',
      images: 4,
    ),
    lit: Decor(
      dossier: 'pieces/chambre_lit/$qui',
      etat: 'rdv_lit_$qui',
      nom: 'Ce soir',
      images: 6,
      allerRetour: true,
      ratio: 3 / 4,
    ),
  );
}

Decor decorDeLaChambre(EtatPartie etat) {
  // Qu'on dorme à deux passe avant la nuit blanche : c'est la chose la
  // plus vraie de la pièce, et elle est rare. Jusqu'ici ce décor n'était
  // atteignable par rien — il attendait la romance.
  final qui = partenaire(etat.attache, etat.epouse);
  if (qui != null && _chambresPartagees.contains(qui)) {
    // Quatre images par personne, et une seule génération chacune : les
    // quatre poses ont été faites d'un coup, côte à côte sur fond vert,
    // puis incrustées sur une plaque unique. C'est la seule façon d'avoir
    // une boucle qui ne saute pas — quatre rendus séparés de la même
    // chambre ne se ressemblent qu'à 0,7 là où il en faut 0,94.
    return Decor(
      dossier: 'pieces/chambre_conjoint/$qui',
      etat: 'conjoint_$qui',
      nom: "On n'est pas seul",
      images: 4,
    );
  }
  if (estNuit(etat)) {
    return const Decor(dossier: 'pieces/chambre_nuit', etat: 'nuit', nom: 'La nuit blanche');
  }
  return const Decor(dossier: 'pieces/chambre_base', etat: 'base', nom: 'La chambre');
}

/// Le garage se remplit de ce qu'on a acheté : c'est la seule pièce dont
/// l'état ne dépend pas des jauges mais du palais lui-même.
const _vehicules = {'velo', 'quatre_quatre', 'motos', 'limousine'};

/// La cour se remplit une voiture à la fois. Les quatre plaques ont été
/// faites en cascade — la deuxième depuis la première, la troisième depuis
/// la deuxième — pour que ce soit la même cour du début à la fin et que
/// les véhicules s'ajoutent au lieu de se remplacer.
Decor decorDuGarage(Set<String> objets) {
  final combien = objets.where(_vehicules.contains).length;
  if (combien >= 3) {
    return const Decor(dossier: 'pieces/garage_parc', etat: 'parc', nom: 'Le parc');
  }
  if (combien == 2) {
    return const Decor(dossier: 'pieces/garage_trois', etat: 'trois', nom: 'Le 4×4 noir');
  }
  if (combien == 1) {
    return const Decor(dossier: 'pieces/garage_deux', etat: 'deux', nom: 'La sportive');
  }
  return const Decor(dossier: 'pieces/garage_base', etat: 'base', nom: 'La voiture de fonction');
}

Decor decorDeLaPiscine(EtatPartie etat, Set<String> objets) {
  if (objets.contains('dimanche') && etat.style <= 35) {
    // La seule pièce qui bouge : quand le quartier vient, l'eau bouge avec.
    return const Decor(
      dossier: 'pieces/piscine_quartier',
      etat: 'quartier',
      nom: 'Le dimanche du quartier',
      images: 6,
      allerRetour: true,
    );
  }
  if (etat.jauges.caisses <= 15) {
    return const Decor(dossier: 'pieces/piscine_vide', etat: 'vide', nom: 'Le bassin vidé');
  }
  if (etat.jauges.caisses <= 30) {
    return const Decor(dossier: 'pieces/piscine_verte', etat: 'verte', nom: "L'eau verte");
  }
  return const Decor(dossier: 'pieces/piscine_base', etat: 'base', nom: "L'eau claire");
}

/// Le décor d'une pièce quelconque, pour que l'écran n'ait pas à savoir
/// laquelle des cinq fonctions appeler.
Decor decorDe(Piece piece, EtatPartie etat, Set<String> objets) => switch (piece) {
      Piece.balcon => decorDuBalcon(etat),
      Piece.bureau => decorDuBureau(etat),
      Piece.chambre => decorDeLaChambre(etat),
      Piece.garage => decorDuGarage(objets),
      Piece.piscine => decorDeLaPiscine(etat, objets),
    };

/// Les jauges que la règle de cette pièce regarde — pour que l'écran puisse
/// dire au joueur pourquoi sa piscine est verte.
List<Jauge> jaugesLues(Piece piece) => switch (piece) {
      Piece.balcon => const [Jauge.peuple, Jauge.armee, Jauge.caisses, Jauge.presse],
      Piece.bureau => const [Jauge.presse],
      Piece.chambre => const [],
      Piece.garage => const [],
      Piece.piscine => const [Jauge.caisses],
    };

// ──────────────────────────── les passages ────────────────────────────

/// La forme des plaques du palais, et la valeur par défaut de
/// [Decor.ratio]. Le cadrage en dépend : c'est lui qui dit où tombe une
/// porte à l'écran. Seule la scène du lit y échappe, et elle n'a pas de
/// porte.
const double ratioPlaque = 3 / 2;

/// Un rectangle en fractions de la plaque, de 0 à 1, coin haut-gauche.
/// Pas de `Rect` : ce fichier doit rester lisible sans Flutter, et testable
/// sans écran.
class Zone {
  const Zone(this.x, this.y, this.largeur, this.hauteur);

  final double x;
  final double y;
  final double largeur;
  final double hauteur;

  double get droite => x + largeur;
  double get bas => y + hauteur;
  double get centreX => x + largeur / 2;
}

/// Une ouverture qu'on touche dans l'image pour changer de pièce. Elle est
/// posée sur une porte, une baie ou une colonnade qui existe vraiment dans
/// la plaque — c'est ce qui la distingue d'un onglet déguisé.
class Passage {
  const Passage({required this.vers, required this.nom, required this.zone});

  final Piece vers;

  /// Ce qu'on lit au bas de l'ouverture : le lieu, pas l'action.
  final String nom;
  final Zone zone;
}

/// Les quatre états du bureau partagent le même cadrage : la baie vitrée à
/// gauche, la porte du couloir au centre, la porte-fenêtre du jardin à
/// droite. Les quatre plaques ont été faites depuis la même assise, donc
/// une seule série de coordonnées les sert toutes.
const _passagesDuBureau = [
  Passage(vers: Piece.balcon, nom: 'Le balcon', zone: Zone(0.00, 0.05, 0.26, 0.78)),
  Passage(vers: Piece.chambre, nom: 'Le couloir', zone: Zone(0.42, 0.23, 0.16, 0.40)),
  Passage(vers: Piece.piscine, nom: 'Le jardin', zone: Zone(0.76, 0.24, 0.24, 0.42)),
];

/// Depuis la piscine, la colonnade ramène à l'intérieur et la terrasse mène
/// à la cour des voitures. Les quatre états de la piscine sont cadrés de la
/// même fenêtre.
const _passagesDeLaPiscine = [
  Passage(vers: Piece.garage, nom: 'La cour', zone: Zone(0.04, 0.34, 0.20, 0.28)),
  Passage(vers: Piece.bureau, nom: 'Le palais', zone: Zone(0.68, 0.30, 0.22, 0.40)),
];

/// La chambre ouvre sur le même balcon que le bureau, par sa baie de droite.
const _passagesDeLaChambre = [
  Passage(vers: Piece.balcon, nom: 'Le balcon', zone: Zone(0.62, 0.14, 0.26, 0.68)),
];

/// La cour : l'aile du palais, sur la gauche, avec sa porte de service.
const _passagesDuGarage = [
  Passage(vers: Piece.bureau, nom: 'Le palais', zone: Zone(0.00, 0.10, 0.21, 0.66)),
];

/// Les ouvertures d'une pièce. Le balcon n'en a aucune : on y est dos au
/// palais, et c'est le demi-tour du bas de l'écran qui ramène — la même
/// sortie que partout ailleurs, pour qu'aucune pièce ne puisse enfermer
/// le joueur si une porte tombe à côté de son ouverture.
List<Passage> passagesDe(Piece piece) => switch (piece) {
      Piece.bureau => _passagesDuBureau,
      Piece.piscine => _passagesDeLaPiscine,
      Piece.chambre => _passagesDeLaChambre,
      Piece.garage => _passagesDuGarage,
      Piece.balcon => const [],
    };

/// Où mène le demi-tour, depuis n'importe où. Null depuis le bureau : on y
/// est déjà, et le bureau est le vestibule du palais.
Piece? demiTourDepuis(Piece piece) => piece == Piece.bureau ? null : Piece.bureau;

/// Le tour d'horizon d'entrée, de 0 à 1 : où doit se porter le regard à
/// l'instant [p] de la découverte d'une pièce. Il part du centre, va à
/// gauche, traverse jusqu'à droite, puis revient au centre.
///
/// C'est une règle, pas une décoration : sans elle, un joueur qui ignore
/// qu'on déplace le regard au doigt ne voit qu'une ouverture sur trois et
/// croit le palais fermé. Elle vit donc ici, où elle se teste sans écran.
double regardDuTour(double p) {
  double doux(double x) => x * x * (3 - 2 * x);
  final t = p.clamp(0.0, 1.0);
  if (t < .28) return 0.5 + (0.10 - 0.5) * doux(t / .28);
  if (t < .72) return 0.10 + (0.90 - 0.10) * doux((t - .28) / .44);
  return 0.90 + (0.5 - 0.90) * doux((t - .72) / .28);
}
