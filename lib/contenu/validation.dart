import '../moteur/condition.dart';
import '../moteur/denouement.dart';
import '../moteur/jauges.dart';
import '../moteur/modeles.dart';
import 'chargement.dart';

/// Mots qui n'ont rien à faire dans un jeu situé dans un pays imaginaire.
const _interdits = [
  'senegal', 'benin', 'cote d ivoire', 'ivoirien', 'togo', 'mali', 'niger', 'nigeria',
  'ghana', 'burkina', 'guinee', 'cameroun', 'tchad', 'france', 'francais', 'paris',
  'fmi', 'banque mondiale', 'onu', 'union africaine', 'cedeao', 'union europeenne',
  'cfa', 'bceao', 'uemoa',
  'dakar', 'abidjan', 'lome', 'cotonou', 'bamako', 'ouagadougou', 'accra', 'lagos',
];

/// Le titre le plus long que `habille()` puisse poser dans un texte de carte,
/// et un nom de joueur généreux : c'est contre eux qu'on mesure la longueur,
/// pas contre le texte brut.
const _titreLePlusLong = 'Madame la Présidente';
const _nomLePlusLong = 'Rakotobearison';

/// Minuscules, sans accents, un seul mot par espace, encadré d'espaces pour
/// pouvoir chercher un mot entier. Le trait d'union disparaît (« Séné-gal »
/// devient « senegal »), l'apostrophe devient une espace (« l'ONU » devient
/// « l onu ») : ni l'un ni l'autre ne doit permettre d'échapper au filtre.
String _mots(String s) {
  const avec = 'àâäéèêëîïôöùûüç';
  const sans = 'aaaeeeeiioouuuc';
  var r = s.toLowerCase();
  for (var i = 0; i < avec.length; i++) {
    r = r.replaceAll(avec[i], sans[i]);
  }
  r = r.replaceAll(RegExp("[-‑–—‒―−]"), '');
  r = r.replaceAll(RegExp("[^a-z0-9]"), ' ');
  final mots = r.split(RegExp(r'\s+')).where((m) => m.isNotEmpty);
  return ' ${mots.join(' ')} ';
}

/// Passe tout le contenu en revue et rend la liste des problèmes trouvés.
/// Une liste vide signifie que le contenu est livrable.
List<String> valide(Contenu c) {
  final problemes = <String>[];

  final vus = <String>{};
  final drapeauxPoses = <String>{};
  final idsParcours = {for (final p in c.parcours) p.id};
  final idsFins = {for (final f in c.fins) f.id};

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
    // Mesuré une fois les marques remplacées : « {titre} » vaut jusqu'à
    // vingt caractères, et c'est ce texte-là qui doit tenir sur la carte
    // sans masquer le portrait.
    final habille = carte.texte
        .replaceAll('{titre}', _titreLePlusLong)
        .replaceAll('{nom}', _nomLePlusLong);
    if (habille.length > 150) {
      problemes.add('$ou : texte de ${habille.length} caractères une fois habillé, 150 au plus');
    }
    if (carte.poids < 1) problemes.add('$ou : poids inférieur à 1');

    for (final r in [carte.gauche, carte.droite]) {
      if (r.libelle.length > 18) problemes.add('$ou : libellé « ${r.libelle} » de ${r.libelle.length} caractères, 18 au plus');
      if (r.effets.isEmpty) problemes.add('$ou : une réponse sans effet');
      if (r.effets.length > 3) problemes.add('$ou : une réponse touche ${r.effets.length} jauges, 3 au plus');
      // L'axe du régime se déplace par petits pas : une seule décision ne
      // fait pas une dictature, c'est la somme qui compte.
      if (r.style < -10 || r.style > 10) {
        problemes.add('$ou : déplacement de régime ${r.style} hors des bornes −10 à 10');
      }
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

    final texte = _mots('${carte.texte} ${carte.gauche.libelle} ${carte.droite.libelle}');
    for (final mot in _interdits) {
      if (texte.contains(' $mot ')) problemes.add('$ou : mot interdit « $mot »');
    }
  }

  for (final fin in c.fins) {
    final ou = 'fin ${fin.id}';
    final texte = _mots('${fin.titre} ${fin.texte}');
    for (final mot in _interdits) {
      if (texte.contains(' $mot ')) problemes.add('$ou : mot interdit « $mot »');
    }
  }

  for (final personnage in c.personnages.values) {
    final ou = 'personnage ${personnage.id}';
    final texte = _mots('${personnage.nom} ${personnage.titre}');
    for (final mot in _interdits) {
      if (texte.contains(' $mot ')) problemes.add('$ou : mot interdit « $mot »');
    }
  }

  for (final parcours in c.parcours) {
    final ou = 'parcours ${parcours.id}';
    final texte = _mots('${parcours.nom} ${parcours.accroche} ${parcours.conditionDeblocage ?? ""}');
    for (final mot in _interdits) {
      if (texte.contains(' $mot ')) problemes.add('$ou : mot interdit « $mot »');
    }

    // Sans accroche, le choix du parcours n'affiche qu'un titre de fonction
    // et ne dit rien de qui on était.
    if (parcours.accroche.trim().isEmpty) {
      problemes.add('$ou : sans accroche');
    } else if (parcours.accroche.length > 60) {
      problemes.add('$ou : accroche de ${parcours.accroche.length} caractères, 60 au plus');
    }

    // L'atout est la récompense d'un parcours débloqué : un parcours ouvert
    // dès le début n'a rien eu à gagner, et un parcours verrouillé sans
    // atout ne donnerait envie de rien.
    final atout = parcours.atout;
    if (parcours.ouvertDesLeDebut && atout != null) {
      problemes.add('$ou : ouvert dès le début, mais porte un atout');
    }
    if (!parcours.ouvertDesLeDebut && atout == null) {
      problemes.add('$ou : verrouillé sans atout, rien ne récompense le déblocage');
    }
    if (atout != null && (atout.part <= 0 || atout.part >= 1)) {
      problemes.add('$ou : atout de part ${atout.part}, il faut entre 0 et 1 exclus');
    }
    if (atout != null && atout.texte.trim().isEmpty) {
      problemes.add('$ou : atout sans texte, il serait invisible');
    }

    if (!parcours.ouvertDesLeDebut) {
      final condition = parcours.condition;
      if (condition == null) {
        // Sans condition typée, ce parcours verrouillé ne se débloquera
        // jamais : bilan() n'ouvre jamais un parcours dans ce cas.
        problemes.add('$ou : sans condition typée, restera verrouillé pour toujours');
      } else {
        problemes.addAll(_problemesCondition(ou, condition, idsFins));
      }
    }
  }

  final idsExploits = <String>{};
  for (final exploit in c.exploits) {
    final ou = 'exploit ${exploit.id}';

    if (!idsExploits.add(exploit.id)) problemes.add('$ou : identifiant en double');
    if (exploit.titre.trim().isEmpty) problemes.add('$ou : sans titre');

    if (exploit.condition.estVide) {
      // Une condition vide est toujours remplie : cet exploit se
      // débloquerait au premier mandat venu, sans que personne comprenne
      // pourquoi.
      problemes.add('$ou : sans condition, se débloquerait au premier mandat venu');
    } else {
      problemes.addAll(_problemesCondition(ou, exploit.condition, idsFins));
    }

    final texteExploit = _mots('${exploit.titre} ${exploit.description}');
    for (final mot in _interdits) {
      if (texteExploit.contains(' $mot ')) problemes.add('$ou : mot interdit « $mot »');
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

  // Deux fins pour le même dénouement sont permises si le régime les
  // départage : réélu dans les règles et réélu seul candidat sont le même
  // score et deux histoires. Une fin large sert de repli à une fin étroite
  // qu'elle contient. Ce qui reste interdit, c'est deux fins qui se
  // chevauchent sans que l'une tranche : le choix serait arbitraire.
  final finsParCas = <String, List<Fin>>{};
  for (final f in c.fins) {
    final cle = '${f.jauge?.name ?? "election"}_${f.versLeHaut}';
    finsParCas.putIfAbsent(cle, () => []).add(f);
  }
  for (final e in finsParCas.entries) {
    final liste = e.value;
    for (var i = 0; i < liste.length; i++) {
      for (var k = i + 1; k < liste.length; k++) {
        final a = liste[i];
        final b = liste[k];
        final seChevauchent = a.styleMin <= b.styleMax && b.styleMin <= a.styleMax;
        final aContientB = a.styleMin <= b.styleMin && a.styleMax >= b.styleMax && a.precision > b.precision;
        final bContientA = b.styleMin <= a.styleMin && b.styleMax >= a.styleMax && b.precision > a.precision;
        if (seChevauchent && !aContientB && !bContientA) {
          problemes.add(
            'fins : « ${a.id} » et « ${b.id} » se disputent le cas « ${e.key} » '
            'sans que le régime les départage',
          );
        }
      }
    }
  }

  final clesFins = <String>{};
  for (final f in c.fins) {
    final cle = '${f.jauge?.name ?? "election"}_${f.versLeHaut}';
    clesFins.add(cle);
  }

  // La carte d'ouverture : une seule, et jouable par tout le monde au tout
  // premier jour. Sinon, des joueurs commenceraient sans prêter serment.
  final ouvertures = c.cartes.where((carte) => carte.ouverture).toList();
  if (ouvertures.length > 1) {
    final ids = ouvertures.map((carte) => carte.id).join(', ');
    problemes.add('cartes : plusieurs cartes d\'ouverture (« $ids »), une seule est possible');
  }
  for (final carte in ouvertures) {
    final ou = 'carte ${carte.id}';
    final cond = carte.conditions;
    if (cond.jourMin > 1) problemes.add('$ou : ouverture, mais jour_min après le premier jour');
    if (cond.mandatMin > 1) problemes.add('$ou : ouverture, mais mandat_min après le premier mandat');
    if (cond.parcours.isNotEmpty) {
      problemes.add('$ou : ouverture réservée à certains parcours, les autres commenceraient sans');
    }
    if (cond.drapeauxRequis.isNotEmpty) {
      problemes.add('$ou : ouverture conditionnée à un drapeau, qu\'aucune réponse n\'a encore posé');
    }
    if (carte.chaine != null) problemes.add('$ou : ouverture prise dans une chaîne');
  }

  if (c.parcours.where((p) => p.ouvertDesLeDebut).isEmpty) {
    problemes.add('parcours : aucun parcours ouvert dès le début');
  }

  return problemes;
}

/// Contrôles communs aux conditions d'exploit et de parcours : une jauge
/// dont le plancher dépasse le plafond, des jours au-delà de la durée du
/// mandat, ou une fin qui n'existe pas dans `fins.json` — dans tous les cas
/// une condition qui ne pourra jamais être remplie.
List<String> _problemesCondition(String ou, Condition condition, Set<String> idsFins) {
  final problemes = <String>[];
  for (final jauge in Jauge.values) {
    final min = condition.jaugesMin[jauge];
    final max = condition.jaugesMax[jauge];
    if (min != null && max != null && min > max) {
      problemes.add('$ou : condition impossible sur ${jauge.name}');
    }
  }
  if (condition.joursMin > dureeMandatPrototype) {
    problemes.add('$ou : condition impossible, jours_min au-delà de la durée du mandat');
  }
  final fin = condition.fin;
  if (fin != null && !idsFins.contains(fin)) {
    problemes.add('$ou : condition citant une fin inconnue « $fin »');
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
