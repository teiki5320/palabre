import 'condition.dart';
import 'jauges.dart';

/// Les trois expressions disponibles pour chaque personnage.
enum Humeur { neutre, content, fache }

Map<Jauge, int> _effets(Map<String, dynamic>? source) => {
      for (final e in (source ?? const <String, dynamic>{}).entries)
        Jauge.values.byName(e.key): (e.value as num).toInt(),
    };

List<String> _textes(dynamic source) => ((source as List?) ?? const []).cast<String>();

/// Une des deux réponses possibles à une carte.
class Reponse {
  const Reponse({
    required this.libelle,
    required this.effets,
    this.drapeaux = const [],
    this.style = 0,
  });

  final String libelle;
  final Map<Jauge, int> effets;

  /// Ce que la réponse déplace sur l'axe république — dictature. Positif
  /// vers la dictature, négatif vers la république, zéro pour la plupart des
  /// décisions, qui ne disent rien du régime.
  final int style;

  /// Marques posées dans la partie, que d'autres cartes pourront exiger.
  final List<String> drapeaux;

  factory Reponse.depuisJson(Map<String, dynamic> j) => Reponse(
        libelle: j['libelle'] as String,
        effets: _effets(j['effets'] as Map<String, dynamic>?),
        drapeaux: _textes(j['drapeaux']),
        style: ((j['style'] as num?) ?? 0).toInt(),
      );
}

/// Place d'une carte dans une suite d'événements liés.
class Chaine {
  const Chaine({required this.id, required this.rang, this.delaiMin = 0});

  final String id;
  final int rang;

  /// Nombre de jours minimum depuis la carte précédente de la chaîne.
  final int delaiMin;

  factory Chaine.depuisJson(Map<String, dynamic> j) => Chaine(
        id: j['id'] as String,
        rang: (j['rang'] as num).toInt(),
        delaiMin: ((j['delai_min'] as num?) ?? 0).toInt(),
      );
}

/// Ce qui doit être vrai pour qu'une carte puisse sortir.
class Conditions {
  const Conditions({
    this.mandatMin = 1,
    this.jourMin = 1,
    this.jourMax = 9999,
    this.minimums = const {},
    this.maximums = const {},
    this.drapeauxRequis = const [],
    this.drapeauxInterdits = const [],
    this.parcours = const [],
    this.styleMin = 0,
    this.styleMax = 100,
  });

  final int mandatMin;
  final int jourMin;
  final int jourMax;

  /// Jauge -> valeur plancher, la carte ne sort que si la jauge est au-dessus.
  final Map<Jauge, int> minimums;

  /// Jauge -> valeur plafond, la carte ne sort que si la jauge est en dessous.
  final Map<Jauge, int> maximums;

  final List<String> drapeauxRequis;
  final List<String> drapeauxInterdits;

  /// Parcours autorisés ; vide signifie « tous ».
  final List<String> parcours;

  /// Où doit en être le régime pour que la carte ait un sens. Le chef des
  /// renseignements ne vient pas voir un démocrate ; le président de
  /// l'Assemblée ne convoque plus personne quand il n'y a plus d'Assemblée.
  final int styleMin;
  final int styleMax;

  factory Conditions.depuisJson(Map<String, dynamic>? j) {
    if (j == null) return const Conditions();
    final minimums = <Jauge, int>{};
    final maximums = <Jauge, int>{};
    for (final jauge in Jauge.values) {
      final min = j['${jauge.name}_min'] as num?;
      final max = j['${jauge.name}_max'] as num?;
      if (min != null) minimums[jauge] = min.toInt();
      if (max != null) maximums[jauge] = max.toInt();
    }
    return Conditions(
      mandatMin: ((j['mandat_min'] as num?) ?? 1).toInt(),
      jourMin: ((j['jour_min'] as num?) ?? 1).toInt(),
      jourMax: ((j['jour_max'] as num?) ?? 9999).toInt(),
      minimums: minimums,
      maximums: maximums,
      drapeauxRequis: _textes(j['drapeaux_requis']),
      drapeauxInterdits: _textes(j['drapeaux_interdits']),
      parcours: _textes(j['parcours']),
      styleMin: ((j['style_min'] as num?) ?? 0).toInt(),
      styleMax: ((j['style_max'] as num?) ?? 100).toInt(),
    );
  }
}

/// Une carte : un personnage, une phrase, deux réponses.
class Carte {
  const Carte({
    required this.id,
    required this.personnage,
    required this.humeur,
    required this.texte,
    required this.gauche,
    required this.droite,
    this.conditions = const Conditions(),
    this.poids = 1,
    this.chaine,
    this.repetable = false,
    this.ouverture = false,
  });

  final String id;
  final String personnage;
  final Humeur humeur;
  final String texte;
  final Reponse gauche;
  final Reponse droite;
  final Conditions conditions;

  /// Poids du tirage : une carte de poids 3 sort trois fois plus souvent.
  final int poids;
  final Chaine? chaine;
  final bool repetable;

  /// La carte qui ouvre un premier mandat : la prestation de serment. Elle
  /// passe avant toutes les autres au premier jour, et une seule carte du
  /// contenu peut la porter.
  final bool ouverture;

  factory Carte.depuisJson(Map<String, dynamic> j) => Carte(
        id: j['id'] as String,
        personnage: j['personnage'] as String,
        humeur: Humeur.values.byName((j['humeur'] as String?) ?? 'neutre'),
        texte: j['texte'] as String,
        gauche: Reponse.depuisJson(j['gauche'] as Map<String, dynamic>),
        droite: Reponse.depuisJson(j['droite'] as Map<String, dynamic>),
        conditions: Conditions.depuisJson(j['conditions'] as Map<String, dynamic>?),
        poids: ((j['poids'] as num?) ?? 1).toInt(),
        chaine: j['chaine'] == null ? null : Chaine.depuisJson(j['chaine'] as Map<String, dynamic>),
        repetable: (j['repetable'] as bool?) ?? false,
        ouverture: (j['ouverture'] as bool?) ?? false,
      );
}

/// Quelqu'un qui vient voir le Président.
class Personnage {
  const Personnage({required this.id, required this.nom, required this.titre});

  final String id;
  final String nom;
  final String titre;

  factory Personnage.depuisJson(Map<String, dynamic> j) => Personnage(
        id: j['id'] as String,
        nom: j['nom'] as String,
        titre: j['titre'] as String,
      );

  /// Chemin de l'image pour une humeur donnée.
  String image(Humeur h) => 'assets/images/personnages/${id}_${h.name}.jpg';
}

/// Qui le joueur était avant d'être élu.
/// Ce qu'un parcours donne de plus, et qu'aucun autre n'a. C'est la vraie
/// récompense d'un parcours débloqué : partir de plus haut ne sert à rien,
/// puisque ce qui tue est la proximité d'un bord, pas le total.
///
/// Un atout amortit une jauge **dans les deux sens** : elle gagne moins et
/// perd moins. C'est ce qui la garde loin des deux bords, et les deux bords
/// tuent. N'amortir que les pertes serait pire que rien pour un parcours qui
/// démarre haut : l'ancien international, à 80 de peuple, serait poussé vers
/// le plafond par son propre atout.
class Atout {
  const Atout({required this.jauge, required this.part, required this.texte});

  /// La jauge protégée.
  final Jauge jauge;

  /// Ce qui reste d'un mouvement sur cette jauge, gain comme perte : 0,5 le
  /// divise par deux. L'atout ancre la jauge, il ne la dope pas.
  final double part;

  /// Une phrase courte, affichée au choix du parcours : sans elle, l'atout
  /// serait invisible et ne donnerait envie de rien.
  final String texte;

  factory Atout.depuisJson(Map<String, dynamic> j) => Atout(
        jauge: Jauge.values.byName(j['jauge'] as String),
        part: ((j['part'] as num?) ?? 0.5).toDouble(),
        texte: j['texte'] as String,
      );
}

class Parcours {
  const Parcours({
    required this.id,
    required this.nom,
    required this.titre,
    required this.femme,
    required this.depart,
    this.accroche = '',
    this.conditionDeblocage,
    this.condition,
    this.atout,
  });

  final String id;
  final String nom;

  /// « Monsieur le Président » ou « Madame la Présidente ».
  final String titre;
  final bool femme;
  final Jauges depart;

  /// Une ligne de caractère, affichée sous le nom au choix du parcours :
  /// ce que le pays pense de vous avant même que vous ayez décidé quoi que
  /// ce soit. Vide si le contenu n'en donne pas.
  final String accroche;

  /// Texte affiché sur un parcours verrouillé ; null si ouvert dès le début.
  final String? conditionDeblocage;

  /// Ce que ce parcours donne de plus ; null pour les parcours ouverts, qui
  /// n'ont rien eu à gagner.
  final Atout? atout;

  /// Condition typée du déblocage ; null si absente. Une condition vide
  /// étant toujours remplie, `null` (et non une `Condition` par défaut) est
  /// ce qui garde un parcours verrouillé pour toujours tant qu'elle manque.
  final Condition? condition;

  factory Parcours.depuisJson(Map<String, dynamic> j) {
    final d = j['depart'] as Map<String, dynamic>;
    return Parcours(
      id: j['id'] as String,
      nom: j['nom'] as String,
      titre: j['titre'] as String,
      femme: j['femme'] as bool,
      depart: Jauges(
        peuple: (d['peuple'] as num).toInt(),
        armee: (d['armee'] as num).toInt(),
        caisses: (d['caisses'] as num).toInt(),
        presse: (d['presse'] as num).toInt(),
      ),
      accroche: j['accroche'] as String? ?? '',
      conditionDeblocage: j['condition_deblocage'] as String?,
      condition: j['condition'] == null ? null : Condition.depuisJson(j['condition'] as Map<String, dynamic>),
      atout: j['atout'] == null ? null : Atout.depuisJson(j['atout'] as Map<String, dynamic>),
    );
  }

  bool get ouvertDesLeDebut => conditionDeblocage == null;

  /// Portrait de celui qu'on était avant d'être élu.
  String get image => 'assets/images/parcours/$id.jpg';
}

/// Comment un mandat se termine.
class Fin {
  const Fin({
    required this.id,
    required this.jauge,
    required this.versLeHaut,
    required this.titre,
    required this.texte,
    required this.image,
    this.styleMin = 0,
    this.styleMax = 100,
  });

  /// Le régime auquel cette fin appartient. Réélu dans un pays où l'on
  /// pouvait voter contre vous n'est pas réélu parce qu'il ne restait
  /// personne en face : même score, épilogue différent. Une fin qui couvre
  /// tout l'axe sert de repli quand aucune fin précise ne convient.
  final int styleMin;
  final int styleMax;

  /// De combien l'axe doit pencher pour que cette fin l'emporte : plus la
  /// fourchette est étroite, plus la fin est précise, et plus elle passe
  /// avant une fin générale.
  int get precision => styleMax - styleMin;

  /// La jauge fautive, ou null pour les fins d'élection.
  final Jauge? jauge;

  /// true si la jauge a débordé, false si elle s'est vidée.
  final bool versLeHaut;
  final String id;
  final String titre;
  final String texte;
  final String image;

  factory Fin.depuisJson(Map<String, dynamic> j) => Fin(
        id: j['id'] as String,
        jauge: j['jauge'] == null ? null : Jauge.values.byName(j['jauge'] as String),
        versLeHaut: (j['vers_le_haut'] as bool?) ?? false,
        titre: j['titre'] as String,
        texte: j['texte'] as String,
        image: j['image'] as String,
        styleMin: ((j['style_min'] as num?) ?? 0).toInt(),
        styleMax: ((j['style_max'] as num?) ?? 100).toInt(),
      );
}
