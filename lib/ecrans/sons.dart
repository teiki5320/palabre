import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../moteur/sons.dart';

export '../moteur/sons.dart' show Son, sonDeLaReponse;

/// Le son du jeu : six échantillons courts, joués d'un geste, et coupables
/// depuis le menu.
///
/// Un lecteur par son plutôt qu'un lecteur partagé : deux sons peuvent se
/// chevaucher — les caisses pendant qu'une carte s'en va — et un lecteur
/// unique couperait le premier pour jouer le second. Six lecteurs de
/// quelques kilo-octets coûtent moins qu'un défaut qu'on entend.
class Sons {
  Sons({AudioPlayer Function()? fabrique}) : _fabrique = fabrique ?? AudioPlayer.new;

  final AudioPlayer Function() _fabrique;
  final Map<Son, AudioPlayer> _lecteurs = {};

  bool _coupe = false;
  bool get coupe => _coupe;

  /// Prépare les lecteurs. Sans ça le premier son de la partie arrive avec
  /// un temps de retard, juste après le geste qui l'a déclenché — et un
  /// bruit en retard est pire qu'un silence.
  Future<void> prepare() async {
    for (final son in Son.values) {
      // Tout dans le même filet, la création du lecteur comprise : sur une
      // plateforme sans greffon audio — les tests, par exemple — c'est elle
      // qui échoue en premier. Un son qu'on ne peut pas préparer reste
      // absent de la table, et `joue` devient un silence au lieu d'une
      // erreur au milieu d'un mandat.
      try {
        final lecteur = _fabrique();
        await lecteur.setReleaseMode(ReleaseMode.stop);
        await lecteur.setPlayerMode(PlayerMode.lowLatency);
        await lecteur.setSource(AssetSource(fichierDe(son)));
        _lecteurs[son] = lecteur;
      } catch (e) {
        debugPrint('son impréparable : ${fichierDe(son)} ($e)');
      }
    }
  }

  /// Joue un son, ou rien si le joueur a coupé. Ne rend jamais d'erreur :
  /// l'appelant est un geste de jeu, il ne sait pas quoi faire d'un échec.
  void joue(Son son) {
    if (_coupe) return;
    final lecteur = _lecteurs[son];
    if (lecteur == null) return;
    unawaited(lecteur.stop().then((_) => lecteur.resume()).catchError((Object e) {
      debugPrint('son injouable : ${son.name} ($e)');
    }));
  }

  Future<void> coupeLe(bool valeur) async {
    _coupe = valeur;
    if (valeur) {
      for (final l in _lecteurs.values) {
        unawaited(l.stop());
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cle, valeur);
  }

  Future<void> relisLeReglage() async {
    final prefs = await SharedPreferences.getInstance();
    _coupe = prefs.getBool(_cle) ?? false;
  }

  Future<void> dispose() async {
    for (final l in _lecteurs.values) {
      await l.dispose();
    }
    _lecteurs.clear();
  }

  static const _cle = 'son_coupe';
}

/// Le son de la partie en cours. Créé une fois, gardé jusqu'à la fin.
final sonsProvider = Provider<Sons>((ref) {
  final sons = Sons();
  // Le réglage d'abord, les lecteurs ensuite : un joueur qui a coupé le son
  // ne doit pas entendre le premier échantillon pendant le chargement.
  // Un `catchError` au bout de la chaîne : sans lui, un appareil dont le
  // greffon audio refuse de se charger lèverait une erreur non rattrapée
  // au démarrage, loin de tout écran capable de l'expliquer.
  unawaited(sons.relisLeReglage().then((_) => sons.prepare()).catchError((Object e) {
    debugPrint('le son ne se prépare pas : $e');
  }));
  ref.onDispose(sons.dispose);
  return sons;
});
