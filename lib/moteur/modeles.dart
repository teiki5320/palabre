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
  const Reponse({required this.libelle, required this.effets, this.drapeaux = const []});

  final String libelle;
  final Map<Jauge, int> effets;

  /// Marques posées dans la partie, que d'autres cartes pourront exiger.
  final List<String> drapeaux;

  factory Reponse.depuisJson(Map<String, dynamic> j) => Reponse(
        libelle: j['libelle'] as String,
        effets: _effets(j['effets'] as Map<String, dynamic>?),
        drapeaux: _textes(j['drapeaux']),
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
class Parcours {
  const Parcours({
    required this.id,
    required this.nom,
    required this.titre,
    required this.femme,
    required this.depart,
    this.conditionDeblocage,
    this.condition,
  });

  final String id;
  final String nom;

  /// « Monsieur le Président » ou « Madame la Présidente ».
  final String titre;
  final bool femme;
  final Jauges depart;

  /// Texte affiché sur un parcours verrouillé ; null si ouvert dès le début.
  final String? conditionDeblocage;

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
      conditionDeblocage: j['condition_deblocage'] as String?,
      condition: j['condition'] == null ? null : Condition.depuisJson(j['condition'] as Map<String, dynamic>),
    );
  }

  bool get ouvertDesLeDebut => conditionDeblocage == null;
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
  });

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
      );
}
