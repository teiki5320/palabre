import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contenu/chargement.dart';
import '../moteur/condition.dart';
import '../moteur/denouement.dart';
import '../moteur/etat_partie.dart';
import '../moteur/modeles.dart';
import '../moteur/partie.dart' as moteur;
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
    state = _prochaine(repond(
      etat: s.etat,
      carte: s.carte!,
      cote: cote,
      atout: _contenu.parcoursParId(s.etat.parcours)?.atout,
    ));
  }

  void arrete() => state = null;

  /// Enchaîne un second mandat après une réélection, et seulement après une
  /// réélection : c'est ici, et nulle part ailleurs, que la règle est
  /// vérifiée. Un écran mal écrit peut appeler cette méthode après une
  /// chute ou une élection perdue ; elle ne fait alors rien, plutôt que de
  /// faire confiance à l'écran pour ne pas se tromper. Jour 1, mandat
  /// suivant, jauges remises au départ du parcours, rien de l'ancien mandat
  /// — ni drapeau, ni carte vue, ni chaîne entamée.
  void mandatSuivant() {
    final s = state;
    if (s == null || s.denouement?.type != TypeDenouement.electionGagnee) return;
    // Un mandat qui s'est terminé sans qu'un jour ait été joué (paquet
    // vide) ne donne pas droit au suivant : sinon trois appuis font trois
    // mandats, et « La longévité du pouvoir » avec.
    if (s.etat.jour <= 1) return;
    final parcours = _contenu.parcoursParId(s.etat.parcours);
    if (parcours == null) return;
    final etat = moteur.mandatSuivant(s.etat, parcours);
    state = _prochaine(etat);
  }

  /// Calcule l'état affichable : dénouement s'il y en a un, sinon la carte du jour.
  Session _prochaine(EtatPartie etat) {
    final d = evalue(etat);
    if (d != null) return _termine(etat, d);
    final carte = choisitCarte(paquet: _contenu.cartes, etat: etat, alea: _alea);
    if (carte == null) {
      // Plus aucune carte jouable : une panne de contenu, pas une fin de
      // mandat. On clôt comme une élection pour que l'écran ait quelque
      // chose à dire, mais si pas un seul jour n'a été joué, il n'y a rien
      // à mettre au bilan — ni mandat compté, ni exploit décroché sur les
      // jauges de départ, ni progression réécrite.
      final faute = Denouement(
        type: (etat.jauges.peuple + etat.jauges.presse) / 2 > 50
            ? TypeDenouement.electionGagnee
            : TypeDenouement.electionPerdue,
      );
      if (etat.jour <= 1) {
        Sauvegarde.efface();
        return Session(
          etat: etat,
          denouement: faute,
          fin: choisitFin(faute, _contenu.fins, style: etat.style),
        );
      }
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
    final fin = choisitFin(denouement, _contenu.fins, style: etat.style);

    // Si la progression n'a pas encore été lue du disque, on calcule le
    // bilan contre une progression neuve pour que l'écran de fin ait quelque
    // chose à annoncer — mais on ne l'écrit surtout pas : ce serait écraser
    // tout ce que le joueur a débloqué par du vide.
    final chargee = ref.read(progressionProvider).value;
    final avant = chargee ?? Progression.neuve();
    final resultat = bilan(
      avant: avant,
      mandat: BilanMandat(
        jauges: etat.jauges,
        jour: etat.jour,
        mandat: etat.mandat,
        finId: fin?.id,
        finFamille: fin?.famille,
        drapeaux: etat.drapeaux,
        parcours: etat.parcours,
      ),
      contenu: _contenu,
    );
    if (chargee != null) Sauvegarde.enregistreProgression(resultat.progression);
    ref.invalidate(progressionProvider); // pour que la fin et la collection voient la nouvelle progression

    return Session(etat: etat, denouement: denouement, fin: fin, nouveautes: resultat.nouveautes);
  }
}

final sessionProvider = NotifierProvider<SessionNotifier, Session?>(SessionNotifier.new);

/// Remplace les gabarits d'un texte de carte par le nom et le titre du joueur.
String habille(String texte, {required String nom, required String titre}) =>
    texte.replaceAll('{nom}', nom).replaceAll('{titre}', titre);
