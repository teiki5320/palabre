import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contenu/chargement.dart';
import '../moteur/denouement.dart';
import '../moteur/etat_partie.dart';
import '../moteur/modeles.dart';
import '../moteur/partie.dart';
import '../moteur/tirage.dart';

/// Le contenu du jeu, lu une seule fois au lancement.
final contenuProvider = FutureProvider<Contenu>((ref) => Contenu.depuisAssets(rootBundle));

/// Ce que l'écran a besoin de savoir : où en est la partie, quelle carte est
/// devant le joueur, et comment le mandat s'est terminé le cas échéant.
class Session {
  const Session({required this.etat, this.carte, this.denouement, this.fin});

  final EtatPartie etat;
  final Carte? carte;
  final Denouement? denouement;
  final Fin? fin;

  bool get terminee => denouement != null;
}

class SessionNotifier extends Notifier<Session?> {
  late Random _alea;

  @override
  Session? build() => null;

  Contenu get _contenu => ref.read(contenuProvider).requireValue;

  /// Commence un mandat. La graine rend la partie reproductible en test.
  void demarre({required Parcours parcours, required String nom, int? graine}) {
    _alea = Random(graine ?? DateTime.now().millisecondsSinceEpoch);
    final etat = EtatPartie(parcours: parcours.id, nomJoueur: nom, jauges: parcours.depart);
    state = _prochaine(etat);
  }

  /// Reprend une partie enregistrée.
  void reprend(EtatPartie etat, {int? graine}) {
    _alea = Random(graine ?? DateTime.now().millisecondsSinceEpoch);
    state = _prochaine(etat);
  }

  void repondA(Cote cote) {
    final s = state;
    if (s == null || s.carte == null || s.terminee) return;
    state = _prochaine(repond(etat: s.etat, carte: s.carte!, cote: cote));
  }

  void arrete() => state = null;

  /// Calcule l'état affichable : dénouement s'il y en a un, sinon la carte du jour.
  Session _prochaine(EtatPartie etat) {
    final d = evalue(etat);
    if (d != null) {
      return Session(etat: etat, denouement: d, fin: choisitFin(d, _contenu.fins));
    }
    final carte = choisitCarte(paquet: _contenu.cartes, etat: etat, alea: _alea);
    if (carte == null) {
      // Plus aucune carte jouable : on clôt le mandat comme une élection.
      final faute = Denouement(
        type: (etat.jauges.peuple + etat.jauges.presse) / 2 > 50
            ? TypeDenouement.electionGagnee
            : TypeDenouement.electionPerdue,
      );
      return Session(etat: etat, denouement: faute, fin: choisitFin(faute, _contenu.fins));
    }
    return Session(etat: etat, carte: carte);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

/// Remplace les gabarits d'un texte de carte par le nom et le titre du joueur.
String habille(String texte, {required String nom, required String titre}) =>
    texte.replaceAll('{nom}', nom).replaceAll('{titre}', titre);
