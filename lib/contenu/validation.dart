import '../moteur/jauges.dart';
import 'chargement.dart';

/// Mots qui n'ont rien à faire dans un jeu situé dans un pays imaginaire.
const _interdits = [
  'senegal', 'benin', 'cote d ivoire', 'ivoirien', 'togo', 'mali', 'niger', 'nigeria',
  'ghana', 'burkina', 'guinee', 'cameroun', 'tchad', 'france', 'francais', 'paris',
  'fmi', 'banque mondiale', 'onu', 'union africaine', 'cedeao', 'union europeenne',
];

String _sansAccents(String s) {
  const avec = 'àâäéèêëîïôöùûüç';
  const sans = 'aaaeeeeiioouuuc';
  var r = s.toLowerCase();
  for (var i = 0; i < avec.length; i++) {
    r = r.replaceAll(avec[i], sans[i]);
  }
  return r.replaceAll(RegExp(r"[^a-z0-9 ]"), ' ');
}

/// Passe tout le contenu en revue et rend la liste des problèmes trouvés.
/// Une liste vide signifie que le contenu est livrable.
List<String> valide(Contenu c) {
  final problemes = <String>[];

  final vus = <String>{};
  final drapeauxPoses = <String>{};
  final idsParcours = {for (final p in c.parcours) p.id};

  for (final carte in c.cartes) {
    for (final r in [carte.gauche, carte.droite]) {
      drapeauxPoses.addAll(r.drapeaux);
    }
  }

  for (final carte in c.cartes) {
    final ou = 'carte ${carte.id}';

    if (!vus.add(carte.id)) problemes.add('$ou : identifiant en double');
    if (!c.personnages.containsKey(carte.personnage)) {
      problemes.add('$ou : personnage inconnu « ${carte.personnage} »');
    }
    if (carte.texte.length > 140) problemes.add('$ou : texte de ${carte.texte.length} caractères, 140 au plus');
    if (carte.poids < 1) problemes.add('$ou : poids inférieur à 1');

    for (final r in [carte.gauche, carte.droite]) {
      if (r.libelle.length > 18) problemes.add('$ou : libellé « ${r.libelle} » de ${r.libelle.length} caractères, 18 au plus');
      if (r.effets.isEmpty) problemes.add('$ou : une réponse sans effet');
      if (r.effets.length > 3) problemes.add('$ou : une réponse touche ${r.effets.length} jauges, 3 au plus');
      for (final e in r.effets.entries) {
        if (e.value == 0) problemes.add('$ou : effet nul sur ${e.key.name}');
        if (e.value < -20 || e.value > 20) problemes.add('$ou : effet ${e.value} hors des bornes −20 à 20');
      }
    }

    final cond = carte.conditions;
    if (cond.jourMin > cond.jourMax) problemes.add('$ou : conditions impossibles, jour_min après jour_max');
    for (final j in Jauge.values) {
      final min = cond.minimums[j];
      final max = cond.maximums[j];
      if (min != null && max != null && min > max) {
        problemes.add('$ou : conditions impossibles sur ${j.name}');
      }
    }
    for (final d in cond.drapeauxRequis) {
      if (!drapeauxPoses.contains(d)) problemes.add('$ou : exige le drapeau « $d » que personne ne pose');
    }
    for (final p in cond.parcours) {
      if (!idsParcours.contains(p)) problemes.add('$ou : parcours inconnu « $p »');
    }

    final texte = _sansAccents('${carte.texte} ${carte.gauche.libelle} ${carte.droite.libelle}');
    for (final mot in _interdits) {
      if (texte.contains(mot)) problemes.add('$ou : mot interdit « $mot »');
    }
  }

  // Les chaînes doivent aller de 1 à n, sans trou ni doublon.
  final rangs = <String, List<int>>{};
  for (final carte in c.cartes) {
    final ch = carte.chaine;
    if (ch != null) rangs.putIfAbsent(ch.id, () => []).add(ch.rang);
  }
  for (final e in rangs.entries) {
    final attendus = [for (var i = 1; i <= e.value.length; i++) i];
    final tries = [...e.value]..sort();
    if (!_memeListe(tries, attendus)) {
      problemes.add('chaîne ${e.key} : rangs ${tries.join(", ")}, attendus ${attendus.join(", ")}');
    }
  }

  // Le joueur doit pouvoir gagner et perdre une élection.
  final aGagnee = c.fins.any((f) => f.jauge == null && f.versLeHaut);
  final aPerdue = c.fins.any((f) => f.jauge == null && !f.versLeHaut);
  if (!aGagnee) problemes.add('fins : il manque la fin d élection gagnée');
  if (!aPerdue) problemes.add('fins : il manque la fin d élection perdue');

  final clesFins = <String>{};
  for (final f in c.fins) {
    final cle = '${f.jauge?.name ?? "election"}_${f.versLeHaut}';
    if (!clesFins.add(cle)) problemes.add('fins : deux fins pour le même cas « $cle »');
  }

  if (c.parcours.where((p) => p.ouvertDesLeDebut).isEmpty) {
    problemes.add('parcours : aucun parcours ouvert dès le début');
  }

  return problemes;
}

bool _memeListe(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
