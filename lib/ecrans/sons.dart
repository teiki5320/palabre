import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../moteur/sons.dart';

export '../moteur/sons.dart' show Fond, Son, fondDe, sonDeLaReponse;

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

  /// Les deux lecteurs du fond. Deux, parce qu'un fondu enchaîné a besoin
  /// des deux bouts en même temps : l'ancien qui s'efface pendant que le
  /// nouveau monte. Avec un seul lecteur il y aurait un trou de silence à
  /// chaque porte franchie.
  AudioPlayer? _fondA;
  AudioPlayer? _fondB;
  bool _surA = true;
  Fond? _fondEnCours;
  Timer? _fondu;

  bool _coupe = false;
  bool get coupe => _coupe;

  /// Ce qui joue en fond, ou rien. Lu par les tests et par l'écran qui
  /// veut savoir s'il a déjà demandé ce fond-là.
  Fond? get fond => _fondEnCours;

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

  /// Met un fond en boucle, ou coupe ce qui joue si [voulu] est nul.
  ///
  /// Redemander le fond déjà en cours ne fait rien : l'écran peut appeler
  /// cette méthode à chaque reconstruction sans relancer la boucle à
  /// chaque image.
  Future<void> metLeFond(Fond? voulu) async {
    if (voulu == _fondEnCours) return;
    _fondEnCours = voulu;
    _fondu?.cancel();
    if (_coupe) return;

    final partant = _surA ? _fondA : _fondB;
    AudioPlayer? arrivant;
    if (voulu != null) {
      try {
        arrivant = _fabrique();
        await arrivant.setReleaseMode(ReleaseMode.loop);
        await arrivant.setVolume(0);
        await arrivant.play(AssetSource(fichierDuFond(voulu)));
      } catch (e) {
        debugPrint('fond injouable : ${fichierDuFond(voulu)} ($e)');
        arrivant = null;
      }
    }
    if (_surA) {
      _fondB = arrivant;
    } else {
      _fondA = arrivant;
    }
    _surA = !_surA;

    // Une musique se retire plus lentement qu'une rue : on peut quitter un
    // balcon d'un pas, pas un morceau.
    final duree = estMusique(voulu ?? _fondEnCours ?? Fond.garage)
        ? const Duration(milliseconds: 1400)
        : const Duration(milliseconds: 600);
    _enFondu(partant: partant, arrivant: arrivant, duree: duree);
  }

  /// Le fondu lui-même, en vingt pas. `audioplayers` ne sait pas monter un
  /// volume tout seul : on le fait à la main, sur un minuteur.
  void _enFondu({AudioPlayer? partant, AudioPlayer? arrivant, required Duration duree}) {
    const pas = 20;
    var i = 0;
    _fondu = Timer.periodic(duree ~/ pas, (t) {
      i++;
      final part = (i / pas).clamp(0.0, 1.0);
      unawaited(partant?.setVolume((1 - part) * _volumeDuFond).catchError((_) {}));
      unawaited(arrivant?.setVolume(part * _volumeDuFond).catchError((_) {}));
      if (i >= pas) {
        t.cancel();
        unawaited(partant?.dispose().catchError((_) {}));
      }
    });
  }

  Future<void> coupeLe(bool valeur) async {
    _coupe = valeur;
    if (valeur) {
      for (final l in _lecteurs.values) {
        unawaited(l.stop());
      }
      _fondu?.cancel();
      for (final l in [_fondA, _fondB]) {
        unawaited(l?.dispose().catchError((_) {}));
      }
      _fondA = null;
      _fondB = null;
    } else {
      // Rallumer remet le fond de la pièce où l'on se trouve.
      final reprendre = _fondEnCours;
      _fondEnCours = null;
      unawaited(metLeFond(reprendre));
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cle, valeur);
  }

  Future<void> relisLeReglage() async {
    final prefs = await SharedPreferences.getInstance();
    _coupe = prefs.getBool(_cle) ?? false;
  }

  Future<void> dispose() async {
    _fondu?.cancel();
    for (final l in [..._lecteurs.values, _fondA, _fondB]) {
      await l?.dispose();
    }
    _lecteurs.clear();
    _fondA = null;
    _fondB = null;
  }

  /// Le fond reste sous les gestes : c'est un décor, pas un événement.
  static const double _volumeDuFond = 0.55;

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
