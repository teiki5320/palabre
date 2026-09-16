import 'jauges.dart';

List<String> _textes(dynamic source) => ((source as List?) ?? const []).cast<String>();

/// Ce qu'on sait d'un mandat qui vient de se terminer, pour évaluer les
/// conditions de déblocage des parcours et des exploits.
class BilanMandat {
  const BilanMandat({
    required this.jauges,
    required this.jour,
    required this.mandat,
    this.finId,
    this.drapeaux = const {},
    required this.parcours,
  });

  final Jauges jauges;
  final int jour;
  final int mandat;

  /// Identifiant de la [Fin] écrite qui correspond au dénouement, ou null si
  /// le contenu ne la fournit pas.
  final String? finId;

  final Set<String> drapeaux;
  final String parcours;
}

/// Ce qui doit être vrai à la fin d'un mandat pour qu'un parcours se
/// débloque ou qu'un exploit se déclenche. Une cousine de [Conditions], pour
/// la fin de mandat plutôt que pour la sortie d'une carte.
class Condition {
  const Condition({
    this.jaugesMin = const {},
    this.jaugesMax = const {},
    this.joursMin = 1,
    this.mandatMin = 1,
    this.fin,
    this.drapeauxRequis = const [],
    this.drapeauxInterdits = const [],
  });

  /// Jauge -> valeur plancher, la condition n'est remplie que si la jauge
  /// finit au-dessus.
  final Map<Jauge, int> jaugesMin;

  /// Jauge -> valeur plafond, la condition n'est remplie que si la jauge
  /// finit en dessous.
  final Map<Jauge, int> jaugesMax;

  final int joursMin;
  final int mandatMin;

  /// Identifiant de la fin exigée, ou null si la fin importe peu.
  final String? fin;

  final List<String> drapeauxRequis;
  final List<String> drapeauxInterdits;

  /// Vraie quand aucun champ ne contraint quoi que ce soit : cette condition
  /// est donc toujours remplie. Sert au contrôle de contenu, qui refuse un
  /// exploit dans ce cas — il se débloquerait au premier mandat venu, sans
  /// que personne ne comprenne pourquoi.
  bool get estVide =>
      jaugesMin.isEmpty &&
      jaugesMax.isEmpty &&
      joursMin <= 1 &&
      mandatMin <= 1 &&
      fin == null &&
      drapeauxRequis.isEmpty &&
      drapeauxInterdits.isEmpty;

  factory Condition.depuisJson(Map<String, dynamic>? j) {
    if (j == null) return const Condition();
    final jaugesMin = <Jauge, int>{};
    final jaugesMax = <Jauge, int>{};
    for (final jauge in Jauge.values) {
      final min = j['${jauge.name}_min'] as num?;
      final max = j['${jauge.name}_max'] as num?;
      if (min != null) jaugesMin[jauge] = min.toInt();
      if (max != null) jaugesMax[jauge] = max.toInt();
    }
    return Condition(
      jaugesMin: jaugesMin,
      jaugesMax: jaugesMax,
      joursMin: ((j['jours_min'] as num?) ?? 1).toInt(),
      mandatMin: ((j['mandat_min'] as num?) ?? 1).toInt(),
      fin: j['fin'] as String?,
      drapeauxRequis: _textes(j['drapeaux_requis']),
      drapeauxInterdits: _textes(j['drapeaux_interdits']),
    );
  }

  bool remplie(BilanMandat b) {
    if (b.mandat < mandatMin) return false;
    if (b.jour < joursMin) return false;
    for (final e in jaugesMin.entries) {
      if (b.jauges.valeur(e.key) < e.value) return false;
    }
    for (final e in jaugesMax.entries) {
      if (b.jauges.valeur(e.key) > e.value) return false;
    }
    if (fin != null && b.finId != fin) return false;
    for (final d in drapeauxRequis) {
      if (!b.drapeaux.contains(d)) return false;
    }
    for (final d in drapeauxInterdits) {
      if (b.drapeaux.contains(d)) return false;
    }
    return true;
  }
}
