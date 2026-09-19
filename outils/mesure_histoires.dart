import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:president/contenu/chargement.dart';
import 'package:president/moteur/denouement.dart';
import 'package:president/moteur/etat_partie.dart';
import 'package:president/moteur/jauges.dart';
import 'package:president/moteur/modeles.dart';
import 'package:president/moteur/partie.dart';
import 'package:president/moteur/romance.dart';
import 'package:president/moteur/tirage.dart';

/// Ce qu'un joueur voit vraiment des histoires en cent jours.
///
/// Les chaînes existent dans le paquet ; la question est de savoir combien
/// en croise un mandat, et combien il en voit finir. On le mesure en
/// jouant, pas en comptant les cartes.
///
///   flutter test outils/mesure_histoires.dart
void main() {
  test('ce que mille mandats voient des histoires', () async {
    Future<String> lis(String n) => File('assets/contenu/$n.json').readAsString();
    final contenu = Contenu.depuisChaines(
      cartes: await lis('cartes'),
      personnages: await lis('personnages'),
      parcours: await lis('parcours'),
      fins: await lis('fins'),
      exploits: await lis('exploits'),
      objets: await lis('objets'),
      adversaires: await lis('adversaires'),
    );

    final chaines = <String, int>{}; // id de chaîne -> rang le plus haut
    for (final c in contenu.cartes) {
      final ch = c.chaine;
      if (ch == null) continue;
      chaines[ch.id] = max(chaines[ch.id] ?? 0, ch.rang);
    }

    const parties = 1000;
    final alea = Random(7);
    final depart = contenu.parcoursParId('general_parcours')!;

    var joursTotal = 0;
    var cartesTotal = 0;
    var maillonsTotal = 0;
    final commencees = <String, int>{};
    final finies = <String, int>{};
    final histoiresParPartie = <int>[];
    final finiesParPartie = <int>[];
    var actesLongs = 0; // maillons de rang 4 ou 5
    var rappels = 0; // cartes « ardoise »
    var memoire = 0; // cartes de loyauté
    var opposition = 0; // cartes d'adversaire ou de campagne
    var forceFinale = 0;
    var forceHaute = 0; // mandats ou l opposant a depasse 55
    var forceBasse = 0;
    var forceMaxTotale = 0;
    var loyautesExtremes = 0;
    var cartesCoeur = 0;
    var mandatsAvecLiaison = 0;
    var mandatsMaries = 0;
    var cartesConjoint = 0;
    final avecQui = <String, int>{};

    for (var p = 0; p < parties; p++) {
      final opposants = contenu.adversaires;
      var etat = EtatPartie(
        parcours: depart.id,
        nomJoueur: 'Awa',
        jauges: depart.depart,
        adversaire: opposants.isEmpty ? null : opposants[alea.nextInt(opposants.length)].id,
      );
      final vuesChaines = <String, int>{};
      var cartes = 0;
      var forceMax = etat.force;
      var forceMin = etat.force;
      while (true) {
        if (evalue(etat) != null) break;
        final carte = choisitCarte(paquet: contenu.cartes, etat: etat, alea: alea);
        if (carte == null) break;
        cartes++;
        if (carte.id.startsWith('ardoise_')) rappels++;
        if (carte.id.startsWith('coeur_')) cartesCoeur++;
        if (carte.personnage == 'conjoint') cartesConjoint++;
        if (carte.id.startsWith('fidele_') || carte.id.startsWith('rancune_')) memoire++;
        if (carte.id.startsWith('face_') || carte.id.startsWith('campagne_')) opposition++;
        final ch = carte.chaine;
        if (ch != null) {
          if (ch.rang > 1) maillonsTotal++;
          if (ch.rang >= 4) actesLongs++;
          vuesChaines[ch.id] = max(vuesChaines[ch.id] ?? 0, ch.rang);
        }
        // Le joueur attentif de l'equilibrage : il vise le centre sur les
        // effets reels, et se trompe une fois sur quatre.
        int ecart(Reponse r) {
          final apres = etat.jauges.applique(
            effetsReels(effets: r.effets, style: etat.style, mandat: etat.mandat, atout: depart.atout),
          );
          return Jauge.values.fold(0, (s, j) => s + (apres.valeur(j) - 50).abs());
        }
        final cote = alea.nextInt(4) == 0
            ? (alea.nextBool() ? Cote.gauche : Cote.droite)
            : (ecart(carte.gauche) <= ecart(carte.droite) ? Cote.gauche : Cote.droite);
        // ignore: unused_local_variable
        final avant = etat;
        etat = repond(
          etat: etat,
          carte: carte,
          cote: cote,
          atout: depart.atout,
          qui: contenu.personnageDe(carte, depart),
        );
        if (etat.force > forceMax) forceMax = etat.force;
        if (etat.force < forceMin) forceMin = etat.force;
      }
      joursTotal += etat.jour - 1;
      cartesTotal += cartes;
      forceFinale += etat.force;
      final l = liaisonPrincipale(etat.attache);
      if (l != null && l.cran >= attacheLiaison) mandatsAvecLiaison++;
      if (estMarie(etat.epouse)) {
        mandatsMaries++;
        avecQui.update(etat.epouse!, (v) => v + 1, ifAbsent: () => 1);
      }
      forceMaxTotale += forceMax;
      if (forceMax >= 55) forceHaute++;
      if (forceMin <= 42) forceBasse++;
      loyautesExtremes += etat.loyaute.values.where((v) => v >= 3 || v <= -3).length;
      var ici = 0;
      var iciFinies = 0;
      for (final e in vuesChaines.entries) {
        commencees[e.key] = (commencees[e.key] ?? 0) + 1;
        ici++;
        if (e.value >= (chaines[e.key] ?? 99)) {
          finies[e.key] = (finies[e.key] ?? 0) + 1;
          iciFinies++;
        }
      }
      histoiresParPartie.add(ici);
      finiesParPartie.add(iciFinies);
    }

    double moy(List<int> l) => l.fold(0, (a, b) => a + b) / l.length;

    // ignore: avoid_print
    print('''
MILLE MANDATS, JOUEUR ATTENTIF
  jours tenus en moyenne        : ${(joursTotal / parties).toStringAsFixed(1)}
  cartes vues en moyenne        : ${(cartesTotal / parties).toStringAsFixed(1)}
  suites d'histoire vues        : ${(maillonsTotal / parties).toStringAsFixed(1)} par mandat
  histoires entamees            : ${moy(histoiresParPartie).toStringAsFixed(1)} par mandat
  histoires menees a leur fin   : ${moy(finiesParPartie).toStringAsFixed(2)} par mandat
  mandats sans aucune histoire finie : ${finiesParPartie.where((x) => x == 0).length} sur $parties
  mandats avec au moins 3 finies     : ${finiesParPartie.where((x) => x >= 3).length} sur $parties
  actes 4 ou 5 vus              : ${(actesLongs / parties).toStringAsFixed(2)} par mandat
  cartes de rappel (ardoise)    : ${(rappels / parties).toStringAsFixed(2)} par mandat
  cartes de memoire (loyaute)   : ${(memoire / parties).toStringAsFixed(2)} par mandat
  cartes d opposition           : ${(opposition / parties).toStringAsFixed(2)} par mandat
  personnages a loyaute forte   : ${(loyautesExtremes / parties).toStringAsFixed(2)} en fin de mandat
  force de l opposant au bout   : ${(forceFinale / parties).toStringAsFixed(1)}
  cartes de romance par mandat  : ${(cartesCoeur / parties).toStringAsFixed(2)}
  mandats avec une liaison      : $mandatsAvecLiaison sur $parties
  mandats ou l on se marie      : $mandatsMaries sur $parties
  cartes du conjoint par mandat : ${(cartesConjoint / parties).toStringAsFixed(2)}
  force la plus haute atteinte  : ${(forceMaxTotale / parties).toStringAsFixed(1)} en moyenne
  mandats ou l opposant passe 55 : $forceHaute sur $parties
  mandats ou il descend sous 42  : $forceBasse sur $parties
''');

    // ignore: avoid_print
    print('QUI L ON EPOUSE : ${(avecQui.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).map((e) => '${e.key} ${e.value}').join(', ')}');

    final jamaisFinies = chaines.keys.where((k) => (finies[k] ?? 0) == 0).toList()..sort();
    // ignore: avoid_print
    print('HISTOIRES QU AUCUN DES MILLE MANDATS N A VUES FINIR : ${jamaisFinies.length} sur ${chaines.length}');
    for (final k in jamaisFinies) {
      // ignore: avoid_print
      print('   $k  (entamee dans ${commencees[k] ?? 0} mandats sur $parties)');
    }

    expect(parties, 1000);
  });
}
