import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contenu/chargement.dart';
import '../moteur/condition.dart';
import '../moteur/denouement.dart';
import '../moteur/etat_partie.dart';
import '../moteur/modeles.dart';
import '../moteur/partie.dart';
import '../moteur/progression.dart';
import '../moteur/tirage.dart';
import '../sauvegarde/sauvegarde.dart';

/// Le contenu du jeu, lu une seule fois au lancement.
final contenuProvider = FutureProvider<Contenu>((ref) => Contenu.depuisAssets(rootBundle));

/// La progression du joueur, lue une seule fois au lancement de
/// l'application — comme le contenu. Elle est invalidée dès qu'un mandat
/// vient de se terminer, pour que l'écran de fin et la collection voient
/// aussitôt ce qui vient d'être débloqué.
final progressionProvider = FutureProvider<Progression>((ref) => Sauvegarde.lisProgression());

/// Ce que l'écran a besoin de savoir : où en est la partie, quelle carte est
/// devant le joueur, et comment le mandat s'est terminé le cas échéant.
class Session {
  const Session({required this.etat, this.carte, this.denouement, this.fin, this.nouveautes = const Nouveautes()});

  final EtatPartie etat;
  final Carte? carte;
  final Denouement? denouement;
  final Fin? fin;

  /// Ce que le mandat qui vient de finir a débloqué — vide tant que la
  /// partie continue, calculé une seule fois par [SessionNotifier], au
  /// moment même où le mandat se termine.
  final Nouveautes nouveautes;

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

  /// Enchaîne un second mandat après une réélection (ou toute autre fin) :
  /// jour 1, mandat suivant, jauges remises au départ du parcours, rien de
  /// l'ancien mandat — ni drapeau, ni carte vue, ni chaîne entamée.
  void mandatSuivant() {
    final s = state;
    if (s == null || !s.terminee) return;
    final parcours = _contenu.parcoursParId(s.etat.parcours)!;
    final etat = EtatPartie(
      parcours: s.etat.parcours,
      nomJoueur: s.etat.nomJoueur,
      jauges: parcours.depart,
      jour: 1,
      mandat: s.etat.mandat + 1,
    );
    state = _prochaine(etat);
  }

  /// Calcule l'état affichable : dénouement s'il y en a un, sinon la carte du jour.
  Session _prochaine(EtatPartie etat) {
    final d = evalue(etat);
    if (d != null) return _termine(etat, d);
    final carte = choisitCarte(paquet: _contenu.cartes, etat: etat, alea: _alea);
    if (carte == null) {
      // Plus aucune carte jouable : on clôt le mandat comme une élection.
      final faute = Denouement(
        type: (etat.jauges.peuple + etat.jauges.presse) / 2 > 50
            ? TypeDenouement.electionGagnee
            : TypeDenouement.electionPerdue,
      );
      return _termine(etat, faute);
    }
    Sauvegarde.enregistre(etat);
    return Session(etat: etat, carte: carte);
  }

  /// Le mandat s'arrête ici, et nulle part ailleurs : le bilan n'est
  /// calculé qu'à cet unique endroit, jamais depuis un `build` ni relu à
  /// chaque reconstruction de l'écran, sous peine de compter un exploit
  /// plusieurs fois et de réécrire la progression en boucle.
  Session _termine(EtatPartie etat, Denouement denouement) {
    Sauvegarde.efface(); // le mandat est fini, il n'y a plus rien à reprendre
    final fin = choisitFin(denouement, _contenu.fins);

    final avant = ref.read(progressionProvider).value ?? Progression.neuve();
    final resultat = bilan(
      avant: avant,
      mandat: BilanMandat(
        jauges: etat.jauges,
        jour: etat.jour,
        mandat: etat.mandat,
        finId: fin?.id,
        drapeaux: etat.drapeaux,
        parcours: etat.parcours,
      ),
      contenu: _contenu,
    );
    Sauvegarde.enregistreProgression(resultat.progression);
    ref.invalidate(progressionProvider); // pour que la fin et la collection voient la nouvelle progression

    return Session(etat: etat, denouement: denouement, fin: fin, nouveautes: resultat.nouveautes);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

/// Remplace les gabarits d'un texte de carte par le nom et le titre du joueur.
String habille(String texte, {required String nom, required String titre}) =>
    texte.replaceAll('{nom}', nom).replaceAll('{titre}', titre);
