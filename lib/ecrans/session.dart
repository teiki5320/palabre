import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contenu/chargement.dart';
import '../moteur/condition.dart';
import '../moteur/denouement.dart';
import '../moteur/etat_partie.dart';
import '../moteur/modeles.dart';
import '../moteur/palais.dart';
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
  const Session({
    required this.etat,
    this.carte,
    this.denouement,
    this.fin,
    this.nouveautes = const Nouveautes(),
    this.journal,
  });

  final EtatPartie etat;
  final Carte? carte;

  /// Ce que le pays a dit de la réponse d'hier, à afficher sous la carte du
  /// jour. Null au premier jour et après une visite du palais — on ne
  /// réimprime pas le journal de la veille à chaque aller-retour.
  final String? journal;
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
  ///
  /// Le mandat ne commence pas les mains vides : ce que le palais contient
  /// déjà pose ses drapeaux dès le premier jour, sans quoi un objet acheté
  /// au premier mandat n'ouvrirait plus rien au quatrième.
  void demarre({required Parcours parcours, required String nom, int? graine}) {
    _alea = Random(graine ?? DateTime.now().millisecondsSinceEpoch);
    final palais = ref.read(progressionProvider).value?.objets ?? const <String>{};
    // L'opposant est tiré au premier jour et ne change plus : c'est lui
    // qu'on affrontera au centième, et c'est son nom que les cartes de
    // campagne demandent.
    final adversaires = _contenu.adversaires;
    final etat = EtatPartie(
      parcours: parcours.id,
      nomJoueur: nom,
      jauges: parcours.depart,
      drapeaux: drapeauxDuPalais(palais),
      adversaire: adversaires.isEmpty ? null : adversaires[_alea.nextInt(adversaires.length)].id,
    );
    state = _prochaine(etat);
  }

  /// Achète un objet du palais : les caisses paient tout de suite, l'objet
  /// entre dans la progression pour toujours, et son drapeau ouvre dès
  /// demain les cartes qu'il débloque. Ne fait rien si la partie est finie
  /// ou si le prix laisse les caisses sous le plancher — l'écran n'a pas à
  /// être le seul à vérifier.
  void acheteObjet(Objet objet) {
    final s = state;
    if (s == null || s.terminee) return;
    final progression = ref.read(progressionProvider).value;
    final possedes = progression?.objets ?? const <String>{};
    if (!achetable(s.etat, objet, possedes)) return;

    if (progression != null) {
      final apres = progression.copie(objets: {...progression.objets, objet.id});
      // L'écriture d'abord, la relecture ensuite : invalider avant que le
      // disque ait reçu l'objet fait relire l'ancien palais, et l'objet
      // qu'on vient de payer disparaît jusqu'au prochain lancement.
      unawaited(Sauvegarde.enregistreProgression(apres).then((_) {
        ref.invalidate(progressionProvider);
      }));
    }
    final etat = achete(s.etat, objet);
    Sauvegarde.enregistre(etat);
    state = Session(etat: etat, carte: s.carte, journal: s.journal);
  }

  /// Reprend une partie enregistrée.
  void reprend(EtatPartie etat, {int? graine}) {
    _alea = Random(graine ?? DateTime.now().millisecondsSinceEpoch);
    state = _prochaine(etat);
  }

  void repondA(Cote cote) {
    final s = state;
    if (s == null || s.carte == null || s.terminee) return;
    final reponse = cote == Cote.gauche ? s.carte!.gauche : s.carte!.droite;
    state = _prochaine(
      repond(
        etat: s.etat,
        carte: s.carte!,
        cote: cote,
        atout: _contenu.parcoursParId(s.etat.parcours)?.atout,
        qui: _contenu.personnageDe(s.carte!, _contenu.parcoursParId(s.etat.parcours), epouse: s.etat.epouse),
      ),
      journal: reponse.journal,
    );
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
    final palais = ref.read(progressionProvider).value?.objets ?? const <String>{};
    final etat = moteur.mandatSuivant(s.etat, parcours);
    // Les drapeaux du palais survivent au mandat comme les objets : un
    // coffre-fort acheté hier reste un coffre-fort demain, mais il se
    // referme, il n'a pas déjà servi.
    state = _prochaine(etat.copie(
      drapeaux: {...etat.drapeaux, ...drapeauxDuPalais(palais)}..remove(drapeauCoffreOuvert),
    ));
  }

  /// Calcule l'état affichable : dénouement s'il y en a un, sinon la carte du jour.
  Session _prochaine(EtatPartie etat, {String? journal}) {
    final d = evalue(etat);
    if (d != null) return _termine(etat, d);
    final carte = choisitCarte(paquet: _contenu.cartes, etat: etat, alea: _alea);
    if (carte == null) {
      // Plus aucune carte jouable : une panne de contenu, pas une fin de
      // mandat. On clôt comme une élection pour que l'écran ait quelque
      // chose à dire, mais si pas un seul jour n'a été joué, il n'y a rien
      // à mettre au bilan — ni mandat compté, ni exploit décroché sur les
      // jauges de départ, ni progression réécrite.
      final faute = Denouement(type: electionDe(etat));
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
    return Session(etat: etat, carte: carte, journal: journal);
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
