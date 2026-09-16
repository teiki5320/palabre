import '../contenu/chargement.dart';
import 'condition.dart';
import 'modeles.dart';

/// Un exploit à débloquer, décrit entièrement par une condition typée : le
/// contenu ne code rien, ajouter un exploit n'est qu'une entrée de JSON.
class Exploit {
  const Exploit({
    required this.id,
    required this.titre,
    required this.description,
    required this.condition,
  });

  final String id;
  final String titre;
  final String description;
  final Condition condition;

  factory Exploit.depuisJson(Map<String, dynamic> j) => Exploit(
        id: j['id'] as String,
        titre: j['titre'] as String,
        description: j['description'] as String,
        condition: Condition.depuisJson(j['condition'] as Map<String, dynamic>?),
      );
}

/// Ce qui est acquis d'une partie à l'autre : ne se perd jamais, ne se
/// recalcule qu'en fin de mandat, par [bilan].
class Progression {
  const Progression({
    required this.parcoursDebloques,
    required this.exploits,
    required this.finsDecouvertes,
    required this.mandatsJoues,
    required this.meilleurJour,
  });

  final Set<String> parcoursDebloques;
  final Set<String> exploits;
  final Set<String> finsDecouvertes;
  final int mandatsJoues;
  final int meilleurJour;

  factory Progression.neuve() => const Progression(
        parcoursDebloques: {},
        exploits: {},
        finsDecouvertes: {},
        mandatsJoues: 0,
        meilleurJour: 0,
      );

  Progression copie({
    Set<String>? parcoursDebloques,
    Set<String>? exploits,
    Set<String>? finsDecouvertes,
    int? mandatsJoues,
    int? meilleurJour,
  }) =>
      Progression(
        parcoursDebloques: parcoursDebloques ?? this.parcoursDebloques,
        exploits: exploits ?? this.exploits,
        finsDecouvertes: finsDecouvertes ?? this.finsDecouvertes,
        mandatsJoues: mandatsJoues ?? this.mandatsJoues,
        meilleurJour: meilleurJour ?? this.meilleurJour,
      );
}

/// Ce qu'un mandat qui vient de finir a tout juste débloqué, à annoncer sur
/// l'écran de fin — jamais en douce, jamais deux fois.
class Nouveautes {
  const Nouveautes({
    this.exploits = const [],
    this.parcours = const [],
    this.finInedite = false,
  });

  final List<Exploit> exploits;
  final List<Parcours> parcours;
  final bool finInedite;

  bool get rienDeNeuf => exploits.isEmpty && parcours.isEmpty && !finInedite;
}

/// Calcule la progression d'après à partir de celle d'avant et des faits du
/// mandat qui vient de se terminer. Pure : ne lit ni n'écrit rien.
({Progression progression, Nouveautes nouveautes}) bilan({
  required Progression avant,
  required BilanMandat mandat,
  required Contenu contenu,
}) {
  final exploitsGagnes = <Exploit>[];
  final exploitsAcquis = {...avant.exploits};
  for (final exploit in contenu.exploits) {
    if (avant.exploits.contains(exploit.id)) continue;
    if (!exploit.condition.remplie(mandat)) continue;
    exploitsGagnes.add(exploit);
    exploitsAcquis.add(exploit.id);
  }

  final parcoursGagnes = <Parcours>[];
  final parcoursDebloques = {...avant.parcoursDebloques};
  for (final parcours in contenu.parcours) {
    if (parcours.ouvertDesLeDebut) continue;
    if (avant.parcoursDebloques.contains(parcours.id)) continue;
    final condition = parcours.condition;
    // Sans condition typée, un parcours verrouillé resterait fermé à
    // jamais : ce n'est pas à bilan de l'ouvrir « au cas où ».
    if (condition == null) continue;
    if (!condition.remplie(mandat)) continue;
    parcoursGagnes.add(parcours);
    parcoursDebloques.add(parcours.id);
  }

  final finId = mandat.finId;
  final finInedite = finId != null && !avant.finsDecouvertes.contains(finId);
  final finsDecouvertes = finId == null ? avant.finsDecouvertes : {...avant.finsDecouvertes, finId};

  final progression = avant.copie(
    parcoursDebloques: parcoursDebloques,
    exploits: exploitsAcquis,
    finsDecouvertes: finsDecouvertes,
    mandatsJoues: avant.mandatsJoues + 1,
    meilleurJour: mandat.jour > avant.meilleurJour ? mandat.jour : avant.meilleurJour,
  );

  final nouveautes = Nouveautes(
    exploits: exploitsGagnes,
    parcours: parcoursGagnes,
    finInedite: finInedite,
  );

  return (progression: progression, nouveautes: nouveautes);
}
