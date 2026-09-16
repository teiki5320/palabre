import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../moteur/etat_partie.dart';
import '../moteur/jauges.dart';

/// La partie en cours, gardée sur l'appareil. Rien ne part sur le réseau.
///
/// Chaque méthode avale ses propres erreurs : une sauvegarde abîmée ou un
/// stockage indisponible (disque plein, environnement de test sans plugin)
/// ne doit jamais empêcher de jouer.
class Sauvegarde {
  static const _cle = 'partie_en_cours';

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
      'drapeaux': e.drapeaux.toList(),
      'vues': e.vues.toList(),
      'chaines_rang': e.chainesRang,
      'chaines_jour': e.chainesJour,
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
    drapeaux: ((j['drapeaux'] as List?) ?? const []).cast<String>().toSet(),
    vues: ((j['vues'] as List?) ?? const []).cast<String>().toSet(),
    chainesRang: ((j['chaines_rang'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
    chainesJour: ((j['chaines_jour'] as Map?) ?? const {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
  );
}
