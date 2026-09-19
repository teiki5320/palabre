import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../moteur/etat_partie.dart';
import '../moteur/jauges.dart';
import '../moteur/memoire.dart';
import '../moteur/progression.dart';

/// La partie en cours et la progression, gardées sur l'appareil. Rien ne
/// part sur le réseau.
///
/// Chaque méthode avale ses propres erreurs : une sauvegarde abîmée ou un
/// stockage indisponible (disque plein, environnement de test sans plugin)
/// ne doit jamais empêcher de jouer. Les deux sauvegardes vivent sous des
/// clés distinctes et indépendantes : effacer l'une ne touche jamais l'autre.
class Sauvegarde {
  static const _cle = 'partie_en_cours';
  static const _cleProgression = 'progression';
  static const _cleIntro = 'intro_vue';

  static Future<void> enregistre(EtatPartie etat) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cle, jsonEncode(versJson(etat)));
    } catch (_) {
      // Rien à faire : on ne bloque jamais la partie pour une sauvegarde ratée.
    }
  }

  /// Rend la partie enregistrée, ou null s'il n'y en a pas, si elle est
  /// illisible, ou si le stockage est indisponible.
  static Future<EtatPartie?> lis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_cle);
      if (brut == null) return null;
      try {
        return depuisJson(jsonDecode(brut) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_cle);
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> efface() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cle);
    } catch (_) {
      // Rien à faire.
    }
  }

  /// L'intro ne se montre qu'au tout premier lancement. En cas de stockage
  /// indisponible on répond « déjà vue » : mieux vaut sauter une explication
  /// que la réimposer à chaque ouverture.
  static Future<bool> introVue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_cleIntro) ?? false;
    } catch (_) {
      return true;
    }
  }

  static Future<void> noteIntroVue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cleIntro, true);
    } catch (_) {
      // Rien à faire : au pire, l'intro se remontrera une fois.
    }
  }

  static Future<void> enregistreProgression(Progression p) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cleProgression, jsonEncode(progressionVersJson(p)));
    } catch (_) {
      // Rien à faire : on ne bloque jamais la partie pour une sauvegarde ratée.
    }
  }

  /// Rend la progression enregistrée, ou une progression neuve s'il n'y en a
  /// pas, si elle est illisible, ou si le stockage est indisponible.
  static Future<Progression> lisProgression() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final brut = prefs.getString(_cleProgression);
      if (brut == null) return Progression.neuve();
      try {
        return progressionDepuisJson(jsonDecode(brut) as Map<String, dynamic>);
      } catch (_) {
        await prefs.remove(_cleProgression);
        return Progression.neuve();
      }
    } catch (_) {
      return Progression.neuve();
    }
  }
}

Map<String, dynamic> versJson(EtatPartie e) => {
      'parcours': e.parcours,
      'nom': e.nomJoueur,
      'jauges': {
        'peuple': e.jauges.peuple,
        'armee': e.jauges.armee,
        'caisses': e.jauges.caisses,
        'presse': e.jauges.presse,
      },
      'jour': e.jour,
      'mandat': e.mandat,
      'style': e.style,
      'drapeaux': e.drapeaux.toList(),
      'vues': e.vues.toList(),
      'chaines_rang': e.chainesRang,
      'chaines_jour': e.chainesJour,
      'hier': e.hier,
      'loyaute': e.loyaute,
      'adversaire': e.adversaire,
      'force': e.force,
    };

EtatPartie depuisJson(Map<String, dynamic> j) {
  final g = j['jauges'] as Map<String, dynamic>;
  return EtatPartie(
    parcours: j['parcours'] as String,
    nomJoueur: j['nom'] as String,
    jauges: Jauges(
      peuple: (g['peuple'] as num).toInt(),
      armee: (g['armee'] as num).toInt(),
      caisses: (g['caisses'] as num).toInt(),
      presse: (g['presse'] as num).toInt(),
    ),
    jour: (j['jour'] as num).toInt(),
    mandat: (j['mandat'] as num).toInt(),
    // Une sauvegarde d'avant l'axe du régime repart du début de l'axe.
    style: ((j['style'] as num?) ?? styleDepart).toInt(),
    drapeaux: ((j['drapeaux'] as List?) ?? const []).cast<String>().toSet(),
    vues: ((j['vues'] as List?) ?? const []).cast<String>().toSet(),
    chainesRang: ((j['chaines_rang'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
    chainesJour: ((j['chaines_jour'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
    hier: j['hier'] as String?,
    // Une sauvegarde d'avant la mémoire reprend sans rancune et sans
    // opposant : la force repart de son départ, donc l'élection se décide
    // comme elle se décidait quand elle a été enregistrée.
    loyaute: ((j['loyaute'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
    adversaire: j['adversaire'] as String?,
    force: ((j['force'] as num?) ?? forceDepart).toInt(),
  );
}

Map<String, dynamic> progressionVersJson(Progression p) => {
      'parcours_debloques': p.parcoursDebloques.toList(),
      'exploits': p.exploits.toList(),
      'fins_decouvertes': p.finsDecouvertes.toList(),
      'mandats_joues': p.mandatsJoues,
      'meilleur_jour': p.meilleurJour,
      'objets': p.objets.toList(),
    };

Progression progressionDepuisJson(Map<String, dynamic> j) => Progression(
      parcoursDebloques: ((j['parcours_debloques'] as List?) ?? const []).cast<String>().toSet(),
      exploits: ((j['exploits'] as List?) ?? const []).cast<String>().toSet(),
      finsDecouvertes: ((j['fins_decouvertes'] as List?) ?? const []).cast<String>().toSet(),
      mandatsJoues: ((j['mandats_joues'] as num?) ?? 0).toInt(),
      meilleurJour: ((j['meilleur_jour'] as num?) ?? 0).toInt(),
      // Une sauvegarde d'avant le palais commence avec un palais vide.
      objets: ((j['objets'] as List?) ?? const []).cast<String>().toSet(),
    );
