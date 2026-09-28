// Jusqu'où la romance va vraiment, en mille mandats.
//
// Les dix histoires de cœur et tout ce qu'elles ouvrent — la chambre, les
// noces, les cartes du conjoint — sont le contenu le plus cher du jeu.
// Cette mesure dit combien de joueurs les voient.
//
// Usage : flutter test outils/mesure_romance.dart
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/partie.dart';
import 'package:president/moteur/romance.dart';
import 'package:president/moteur/tirage.dart';

const parties = 1000;
const parcoursOuverts = ['general_parcours', 'professeure', 'syndicaliste', 'femme_affaires'];

void main() {
  test('jusqu ou va la romance', () {
    final contenu = Contenu.depuisChaines(
      cartes: File('assets/contenu/cartes.json').readAsStringSync(),
      personnages: File('assets/contenu/personnages.json').readAsStringSync(),
      parcours: File('assets/contenu/parcours.json').readAsStringSync(),
      fins: File('assets/contenu/fins.json').readAsStringSync(),
      exploits: File('assets/contenu/exploits.json').readAsStringSync(),
      objets: File('assets/contenu/objets.json').readAsStringSync(),
      adversaires: File('assets/contenu/adversaires.json').readAsStringSync(),
      chambre: File('assets/contenu/chambre.json').readAsStringSync(),
    );
    final alea = Random(11);
    final cransAtteints = <int, int>{for (var i = 0; i <= 5; i++) i: 0};
    var maries = 0;
    var chambreVisitee = 0;

    for (var p = 0; p < parties; p++) {
      final quel = parcoursOuverts[p % parcoursOuverts.length];
      final depart = contenu.parcoursParId(quel)!;
      final adv = contenu.adversaires;
      var etat = EtatPartie(
        parcours: quel,
        nomJoueur: 'Test',
        jauges: depart.depart,
        adversaire: adv.isEmpty ? null : adv[alea.nextInt(adv.length)].id,
      );
      var haut = 0;
      var vueVisitee = false;
      while (evalue(etat) == null) {
        final carte = choisitCarte(paquet: contenu.cartes, etat: etat, alea: alea);
        if (carte == null) break;
        final basse = [Jauge.peuple, Jauge.armee, Jauge.caisses, Jauge.presse]
            .reduce((a, b) => etat.jauges.valeur(a) <= etat.jauges.valeur(b) ? a : b);
        final g = effetsReels(
                effets: carte.gauche.effets, style: etat.style, mandat: etat.mandat, atout: depart.atout)[basse] ??
            0;
        final d = effetsReels(
                effets: carte.droite.effets, style: etat.style, mandat: etat.mandat, atout: depart.atout)[basse] ??
            0;
        // À effet égal sur la jauge basse, on accepte ce qui rapproche :
        // c'est le joueur qui *veut* la romance, le cas le plus favorable.
        var cote = g >= d ? Cote.gauche : Cote.droite;
        if (g == d) {
          cote = carte.gauche.romance.mouvement >= carte.droite.romance.mouvement ? Cote.gauche : Cote.droite;
        }
        etat = repond(
          etat: etat,
          carte: carte,
          cote: cote,
          atout: depart.atout,
          qui: contenu.personnageDe(carte, depart, epouse: etat.epouse),
        );
        final l = liaisonPrincipale(etat.attache);
        if (l != null && l.cran > haut) haut = l.cran;
        if (chambreSelon(etat.attache, etat.epouse) != Chambre.seule) vueVisitee = true;
      }
      cransAtteints[haut] = cransAtteints[haut]! + 1;
      if (etat.epouse != null) maries++;
      if (vueVisitee) chambreVisitee++;
    }

    const noms = ['rien', 'on se remarque', 'un geste', 'la liaison', 'au grand jour', 'la demande'];
    // ignore: avoid_print
    print('mandats : $parties  (joueur qui accepte la romance à effet égal)');
    for (var i = 0; i <= 5; i++) {
      // ignore: avoid_print
      print('  cran $i — ${noms[i].padRight(16)} : ${cransAtteints[i]} mandats  '
          '(${(100 * cransAtteints[i]! / parties).toStringAsFixed(1)} %)');
    }
    // ignore: avoid_print
    print('  la chambre n est pas vide      : $chambreVisitee mandats');
    // ignore: avoid_print
    print('  mariage                        : $maries mandats');
  });
}
